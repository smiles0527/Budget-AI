import secrets
import bcrypt as _bcrypt
from datetime import datetime, timedelta, timezone
from typing import Tuple


def hash_password(password: str) -> str:
    return _bcrypt.hashpw(password.encode('utf-8'), _bcrypt.gensalt()).decode('utf-8')


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return _bcrypt.checkpw(password.encode('utf-8'), password_hash.encode('utf-8'))
    except Exception:
        return False


def generate_session_token() -> Tuple[str, str]:
    """Returns tuple (secret, hashed) using bcrypt."""
    secret = secrets.token_urlsafe(32)
    hashed = _bcrypt.hashpw(secret.encode('utf-8'), _bcrypt.gensalt()).decode('utf-8')
    return secret, hashed


def session_expiry(days: int = 30) -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=days)


