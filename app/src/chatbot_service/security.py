from __future__ import annotations

from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

try:
    from google.oauth2 import id_token
    from google.auth.transport import requests as google_requests
except ImportError:  # pragma: no cover - optional dependency in offline mode
    id_token = None  # type: ignore
    google_requests = None  # type: ignore

_bearer_scheme = HTTPBearer(auto_error=False)


class AuthVerifier:
    """Validates Google-signed identity tokens when authentication is required."""

    def __init__(self, *, audience: Optional[str], require_auth: bool) -> None:
        self._audience = audience
        self._require_auth = require_auth
        self._request = google_requests.Request() if google_requests else None

    async def __call__(
        self, credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme)
    ) -> Optional[dict]:
        if not self._require_auth:
            return None

        if credentials is None or not credentials.credentials:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")

        if id_token is None or self._request is None:
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Auth libraries unavailable")

        try:
            info = id_token.verify_oauth2_token(credentials.credentials, self._request, self._audience)
        except Exception as exc:  # pragma: no cover - library raises many subclasses
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid identity token") from exc

        return info


def build_auth_verifier(*, audience: Optional[str], require_auth: bool) -> AuthVerifier:
    return AuthVerifier(audience=audience, require_auth=require_auth)