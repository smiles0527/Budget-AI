import boto3
from botocore.client import Config
from datetime import timedelta
from typing import Optional, List
from ..config import settings
from ..errors import AppError
from urllib.parse import urlparse, urlunparse


def _client():
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint,
        aws_access_key_id=settings.s3_access_key,
        aws_secret_access_key=settings.s3_secret_key,
        region_name=settings.s3_region,
        use_ssl=settings.s3_use_ssl,
        config=Config(signature_version="s3v4"),
    )


def ensure_bucket():
    s3 = _client()
    try:
        s3.head_bucket(Bucket=settings.s3_bucket)
        return
    except Exception:
        pass
    # Create if missing. On AWS, non-us-east-1 requires LocationConstraint.
    try:
        params = {"Bucket": settings.s3_bucket}
        if settings.s3_region and settings.s3_region != "us-east-1":
            params["CreateBucketConfiguration"] = {"LocationConstraint": settings.s3_region}
        s3.create_bucket(**params)
    except Exception:
        # Best-effort; ignore if exists or permissions limited
        pass


def presign_put(object_key: str, content_type: Optional[str] = None, expires: int = 900) -> str:
    s3 = _client()
    params = {"Bucket": settings.s3_bucket, "Key": object_key}
    if content_type:
        params["ContentType"] = content_type
    url = s3.generate_presigned_url(
        ClientMethod="put_object",
        Params=params,
        ExpiresIn=expires,
    )
    return _rewrite_public(url)


def download_bytes(object_key: str) -> bytes:
    s3 = _client()
    obj = s3.get_object(Bucket=settings.s3_bucket, Key=object_key)
    return obj["Body"].read()


def upload_bytes(object_key: str, data: bytes, content_type: Optional[str] = None) -> None:
    s3 = _client()
    params = {"Bucket": settings.s3_bucket, "Key": object_key, "Body": data}
    if content_type:
        params["ContentType"] = content_type
    s3.put_object(**params)


def presign_get(object_key: str, expires: int = 900) -> str:
    s3 = _client()
    url = s3.generate_presigned_url(
        ClientMethod="get_object",
        Params={"Bucket": settings.s3_bucket, "Key": object_key},
        ExpiresIn=expires,
    )
    return _rewrite_public(url)


def head_object(object_key: str):
    s3 = _client()
    try:
        return s3.head_object(Bucket=settings.s3_bucket, Key=object_key)
    except Exception:
        raise AppError(code="OBJECT_NOT_FOUND", message="Uploaded object not found", status_code=400)


def _rewrite_public(url: str) -> str:
    if not settings.s3_public_endpoint:
        return url
    try:
        target = urlparse(settings.s3_public_endpoint)
        src = urlparse(url)
        replaced = src._replace(scheme=target.scheme or src.scheme, netloc=target.netloc or src.netloc)
        return urlunparse(replaced)
    except Exception:
        return url


def delete_prefix(prefix: str) -> int:
    """Delete all objects under the given prefix. Returns number of deleted objects.

    This uses ListObjectsV2 and batched DeleteObjects calls. Safe for MinIO/S3.
    """
    s3 = _client()
    deleted_total = 0
    continuation_token = None
    while True:
        kwargs = {"Bucket": settings.s3_bucket, "Prefix": prefix}
        if continuation_token:
            kwargs["ContinuationToken"] = continuation_token
        resp = s3.list_objects_v2(**kwargs)
        contents = resp.get("Contents", [])
        if not contents:
            break
        # Batch delete up to 1000
        objects = [{"Key": c["Key"]} for c in contents]
        for i in range(0, len(objects), 1000):
            chunk = objects[i : i + 1000]
            del_resp = s3.delete_objects(Bucket=settings.s3_bucket, Delete={"Objects": chunk, "Quiet": True})
            deleted_total += len(del_resp.get("Deleted", chunk))
        if not resp.get("IsTruncated"):
            break
        continuation_token = resp.get("NextContinuationToken")
    return deleted_total


def s3_ready() -> bool:
    """Lightweight readiness check for S3/MinIO connectivity and bucket existence."""
    try:
        s3 = _client()
        # Head bucket if possible; fall back to list_buckets
        try:
            s3.head_bucket(Bucket=settings.s3_bucket)
            return True
        except Exception:
            buckets = s3.list_buckets().get("Buckets", [])
            return any(b.get("Name") == settings.s3_bucket for b in buckets)
    except Exception:
        return False


