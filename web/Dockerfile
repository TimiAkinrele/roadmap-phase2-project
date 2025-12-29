# STAGE 1: The "Builder"
FROM python:3.10 AS builder

RUN apt-get update && apt-get install -y build-essential libpq-dev

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=web/requirements.txt,target=requirements.txt \
    pip install --no-compile -r requirements.txt

COPY web/ .

# STAGE 2: The "Final"
FROM python:3.10-slim

RUN apt-get update && apt-get install -y libpq5 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN adduser --system --no-create-home appuser

USER appuser

COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

COPY --from=builder /app .

EXPOSE 5000

CMD ["python", "app.py"]
