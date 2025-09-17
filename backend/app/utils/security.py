import secrets
from datetime import datetime, timedelta, timezone
from passlib.hash import bcrypt


def hash_password(password: str) -> str:
    return bcrypt.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.verify(password, password_hash)
    except Exception:
        return False


def generate_session_token() -> tuple[str, str]:
    """Returns tuple (secret, hashed) using bcrypt."""
    secret = secrets.token_urlsafe(32)
    hashed = bcrypt.hash(secret)
    return secret, hashed


def session_expiry(days: int = 30) -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=days)


