from typing import Optional, Tuple
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from ..db import get_db
from .security import verify_password


async def _parse_bearer(auth_header: Optional[str]) -> Tuple[str, str]:
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    token = auth_header[7:]
    if "." not in token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token format")
    session_id, secret = token.split(".", 1)
    return session_id, secret


async def get_current_user(
    authorization: Optional[str] = Header(default=None),
    db: AsyncSession = Depends(get_db),
):
    session_id, secret = await _parse_bearer(authorization)
    q = text(
        """
        SELECT s.id, s.user_id, s.refresh_token_hash
        FROM sessions s
        WHERE s.id = :sid AND s.revoked_at IS NULL AND s.expires_at > now()
        """
    )
    res = await db.execute(q, {"sid": session_id})
    row = res.mappings().first()
    if not row:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    if not verify_password(secret, row["refresh_token_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token secret")

    u = await db.execute(
        text(
            "SELECT id, email, created_at FROM users WHERE id = :uid AND deleted_at IS NULL"
        ),
        {"uid": row["user_id"]},
    )
    user = u.mappings().first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return dict(user)


