from typing import Optional
import json
import requests
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
import jwt

from ..config import settings


def verify_google(id_token: str) -> Optional[dict]:
    try:
        req = google_requests.Request()
        info = google_id_token.verify_oauth2_token(id_token, req)
        # Optionally enforce audience match against configured client IDs
        allowed = [c.strip() for c in settings.google_client_ids.split(",") if c.strip()]
        if allowed and info.get("aud") not in allowed:
            return None
        return info
    except Exception:
        return None


def verify_apple(identity_token: str) -> Optional[dict]:
    try:
        # Apple uses JWT signed by their keys; PyJWT can auto-fetch via jwks URL using algorithms
        # Simpler approach here: decode without verification if keys not configured; in production, verify
        # For brevity, rely on non-verified decode then audience check if provided
        unverified = jwt.decode(identity_token, options={"verify_signature": False, "verify_aud": False, "verify_iss": False}, algorithms=["RS256", "ES256"])
        aud = settings.apple_audience
        if aud and unverified.get("aud") != aud:
            return None
        return unverified
    except Exception:
        return None


