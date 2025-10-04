# syntax=docker/dockerfile:1.7
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UVICORN_HOST=0.0.0.0 \
    UVICORN_PORT=8080

RUN groupadd --system app && useradd --system --gid app --create-home app

WORKDIR /opt/app

COPY pyproject.toml README.md ./
COPY src ./src
COPY .env.example ./

RUN pip install --upgrade pip && \
    pip install --no-cache-dir .

USER app

EXPOSE 8080

CMD ["uvicorn", "chatbot_service.main:app", "--host", "0.0.0.0", "--port", "8080"]
