import base64
import hmac
import json
import hashlib
from datetime import date, datetime
from typing import Any, Dict, Optional

from ..config import settings


class _CursorEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, (date, datetime)):
            return o.isoformat()
        if hasattr(o, 'hex'):  # UUID
            return str(o)
        return super().default(o)


def _sign(payload: bytes) -> str:
    mac = hmac.new(settings.cursor_secret.encode("utf-8"), payload, hashlib.sha256).digest()
    return base64.urlsafe_b64encode(mac).decode("utf-8").rstrip("=")


def encode_cursor(data: Dict[str, Any]) -> str:
    raw = json.dumps(data, separators=(",", ":"), cls=_CursorEncoder).encode("utf-8")
    sig = _sign(raw)
    token = base64.urlsafe_b64encode(raw).decode("utf-8").rstrip("=") + "." + sig
    return token


def decode_cursor(token: Optional[str]) -> Optional[Dict[str, Any]]:
    if not token:
        return None
    if "." not in token:
        return None
    payload_b64, sig = token.split(".", 1)
    # Pad base64
    padding = "=" * (-len(payload_b64) % 4)
    raw = base64.urlsafe_b64decode(payload_b64 + padding)
    expected = _sign(raw)
    if not hmac.compare_digest(sig, expected):
        return None
    return json.loads(raw.decode("utf-8"))


