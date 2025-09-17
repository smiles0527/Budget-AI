import boto3
from botocore.client import Config
from datetime import timedelta
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
    buckets = s3.list_buckets().get("Buckets", [])
    if not any(b["Name"] == settings.s3_bucket for b in buckets):
        s3.create_bucket(Bucket=settings.s3_bucket)


def presign_put(object_key: str, content_type: str | None = None, expires: int = 900) -> str:
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


def upload_bytes(object_key: str, data: bytes, content_type: str | None = None) -> None:
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


