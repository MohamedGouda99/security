from __future__ import annotations

import logging
from typing import Optional

from fastapi import Depends, FastAPI, HTTPException, Request, status

from .config import AppSettings, get_settings
from .rate_limiter import RateLimiter
from .schemas import ChatRequest, ChatResponse, HealthResponse
from .security import build_auth_verifier
from .vertex_client import VertexAIClient

_LOGGER = logging.getLogger(__name__)

settings: AppSettings = get_settings()
vertex_client = VertexAIClient(settings)
rate_limiter = RateLimiter(
    max_requests=settings.rate_limit_max_requests,
    window_seconds=settings.rate_limit_window_seconds,
)
auth_dependency = build_auth_verifier(
    audience=settings.auth_audience or None,
    require_auth=settings.require_auth,
)

app = FastAPI(
    title="Secure Chatbot API",
    version="0.1.0",
    description="Inference gateway for the Vertex AI powered chatbot.",
)


@app.on_event("startup")
async def setup_logging() -> None:
    """Route logs to Cloud Logging when available, otherwise use std logging."""

    if settings.offline_mode or not settings.project_id:
        logging.basicConfig(level=settings.log_level)
        _LOGGER.info("Using standard logging (Cloud Logging disabled)")
        return

    try:
        import google.cloud.logging  # type: ignore

        client = google.cloud.logging.Client(project=settings.project_id)
        client.setup_logging()
        _LOGGER.info("Cloud Logging configured")
    except Exception as exc:  # pragma: no cover - best effort logging
        logging.basicConfig(level=settings.log_level)
        _LOGGER.warning("Falling back to standard logging: %s", exc)


@app.get("/health", response_model=HealthResponse, tags=["meta"])
async def health() -> HealthResponse:
    return HealthResponse(status="ok", model=settings.vertex_model, offline=vertex_client.offline_mode)


@app.post("/chat", response_model=ChatResponse, tags=["chat"])
async def chat(
    payload: ChatRequest,
    request: Request,
    _claims: Optional[dict] = Depends(auth_dependency),
) -> ChatResponse:
    client_ip = request.client.host if request.client else "unknown"
    identity = payload.session_id or client_ip

    allowed = await rate_limiter.allow(identity)
    if not allowed:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Rate limit exceeded")

    response_text = await vertex_client.generate_response(payload.message, payload.context)
    return ChatResponse(response=response_text, model=settings.vertex_model, offline=vertex_client.offline_mode)
