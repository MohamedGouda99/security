from __future__ import annotations

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppSettings(BaseSettings):
    """Typed view over environment configuration for the chatbot service."""

    project_id: str = Field("", alias="GCP_PROJECT")
    location: str = Field("us-central1", alias="GCP_LOCATION")
    vertex_model: str = Field("text-bison", alias="VERTEX_MODEL")
    vertex_endpoint: str = Field("", alias="VERTEX_ENDPOINT")

    offline_mode: bool = Field(True, alias="OFFLINE_MODE")
    require_auth: bool = Field(True, alias="REQUIRE_AUTH")
    auth_audience: str = Field("", alias="AUTH_AUDIENCE")

    rate_limit_window_seconds: int = Field(60, alias="RATE_LIMIT_WINDOW_SECONDS")
    rate_limit_max_requests: int = Field(30, alias="RATE_LIMIT_MAX_REQUESTS")

    log_level: str = Field("INFO", alias="LOG_LEVEL")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


@lru_cache
def get_settings() -> AppSettings:
    """Return a cached settings instance."""

    return AppSettings()
