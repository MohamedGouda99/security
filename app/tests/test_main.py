from __future__ import annotations

from fastapi.testclient import TestClient

from chatbot_service import main as app_module

app = app_module.app
app.dependency_overrides[app_module.auth_dependency] = lambda: None
client = TestClient(app)


def test_health_endpoint_reports_offline_mode() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["offline"] is True


def test_chat_endpoint_returns_offline_stub() -> None:
    response = client.post("/chat", json={"message": "Hello", "session_id": "test"})
    assert response.status_code == 200
    payload = response.json()
    assert payload["model"] == app_module.settings.vertex_model
    assert payload["offline"] is True
    assert "offline-mode" in payload["response"]