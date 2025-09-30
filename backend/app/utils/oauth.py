from typing import Optional
import json
import requests
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
import jwt
from jwt import PyJWKClient

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
    """Verify Apple identity token against Apple's JWKS and optional audience.

    Falls back to unverified decode only in dev when APPLE_AUDIENCE is empty.
    """
    try:
        jwks_url = "https://appleid.apple.com/auth/keys"
        jwk_client = PyJWKClient(jwks_url)
        signing_key = jwk_client.get_signing_key_from_jwt(identity_token)
        options = {"verify_aud": bool(settings.apple_audience), "verify_iss": True}
        payload = jwt.decode(
            identity_token,
            signing_key.key,
            algorithms=["RS256", "ES256"],
            audience=settings.apple_audience if settings.apple_audience else None,
            issuer="https://appleid.apple.com",
            options=options,
        )
        return payload
    except Exception:
        # Dev fallback: allow unverified if no audience configured
        try:
            if not settings.apple_audience and settings.env == "dev":
                return jwt.decode(identity_token, options={"verify_signature": False})
        except Exception:
            pass
        return None


