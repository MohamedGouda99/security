from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1024)
    context: Optional[str] = Field(default=None, max_length=2048)
    session_id: Optional[str] = Field(default=None, max_length=128)


class ChatResponse(BaseModel):
    response: str = Field(..., max_length=4096)
    model: str
    offline: bool


class HealthResponse(BaseModel):
    status: str
    model: str
    offline: bool