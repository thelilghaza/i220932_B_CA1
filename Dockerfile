FROM python:3.12-slim

WORKDIR /app

# Arguments for version and git commit traceability
ARG APP_VERSION=1.0.0
ARG GIT_COMMIT=unknown
ARG MODEL_VERSION=1.0

ENV APP_VERSION=${APP_VERSION}
ENV GIT_COMMIT=${GIT_COMMIT}
ENV MODEL_VERSION=${MODEL_VERSION}
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py VERSION ./

EXPOSE 5000

CMD ["python", "app.py"]
