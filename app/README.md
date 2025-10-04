# Chatbot Service

FastAPI application acting as the secure entry point for the Vertex AI powered chatbot workflow. It enforces authentication, applies rate limits, and records audit trails while providing an offline stub for local development.

## Quickstart
1. Create a virtual environment: `python -m venv .venv && .venv\Scripts\activate` (Windows) or `source .venv/bin/activate` (Linux/macOS).
2. Install dependencies: `pip install -e .[dev]`.
3. Run tests: `pytest`.
4. Start the API locally: `uvicorn chatbot_service.main:app --reload`.

Environment variables (or `.env` file) control integration with GCP resources. Set `OFFLINE_MODE=true` to bypass Vertex AI calls when running locally.

## Container Image
Build and run the production image with Docker:
```bash
# from the repository root
cd app
docker build -t chatbot-service:latest .
docker run -p 8080:8080 --env-file .env.example chatbot-service:latest
```
The GitHub Actions deploy workflow uses `gcloud builds submit app` to build this Dockerfile automatically before rolling out to Cloud Run.
