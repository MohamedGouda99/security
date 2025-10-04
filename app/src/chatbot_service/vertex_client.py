from __future__ import annotations

import asyncio
import logging
from typing import Optional

from .config import AppSettings

try:
    import vertexai
    from vertexai.preview.language_models import TextGenerationModel
except ImportError:  # pragma: no cover - optional dependency in offline mode
    vertexai = None  # type: ignore
    TextGenerationModel = None  # type: ignore

_LOGGER = logging.getLogger(__name__)


class VertexAIClient:
    """Wrapper around Vertex AI text generation with offline fallback."""

    def __init__(self, settings: AppSettings) -> None:
        self._settings = settings
        self._model: Optional[TextGenerationModel] = None
        self._offline_mode = settings.offline_mode

        if not self._offline_mode and vertexai and TextGenerationModel:
            vertexai.init(project=settings.project_id, location=settings.location)
            self._model = TextGenerationModel.from_pretrained(settings.vertex_model)
            _LOGGER.info("Vertex AI client initialised for model %s", settings.vertex_model)
        elif not self._offline_mode:
            _LOGGER.warning("Vertex AI libraries unavailable; using offline fallback")
            self._offline_mode = True

    async def generate_response(self, prompt: str, context: Optional[str] = None) -> str:
        safe_prompt = prompt.strip()
        if context:
            safe_context = context.strip()
            safe_prompt = f"{safe_context}\n\nUser: {safe_prompt}\nAssistant:"

        if self._offline_mode or not self._model:
            return self._offline_stub(safe_prompt)

        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(None, self._model.predict, safe_prompt)
        if hasattr(response, "text"):
            return response.text  # type: ignore[attr-defined]
        return str(response)

    @property
    def offline_mode(self) -> bool:
        return self._offline_mode

    def _offline_stub(self, prompt: str) -> str:
        truncated = (prompt[:120] + "...") if len(prompt) > 120 else prompt
        return f"[offline-mode] Echoing intent for: {truncated}"
