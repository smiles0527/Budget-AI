# Backend (FastAPI)

## Run
```powershell
# From repo root
docker compose up -d --build db minio api worker
```

- API Health: http://localhost:8000/healthz
- API Metrics: http://localhost:8000/metrics (Prometheus format)
- Worker Metrics: http://localhost:9100 (Prometheus format)
- MinIO Console: http://localhost:9001 (minioadmin / minioadmin)

## Config
- Env via docker-compose:
  - DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
  - S3_ENDPOINT, S3_ACCESS_KEY, S3_SECRET_KEY, S3_REGION, S3_BUCKET, S3_USE_SSL, S3_PUBLIC_ENDPOINT
  - CORS_ORIGINS (comma-separated or '*'), ALLOWED_HOSTS, MAX_REQUEST_BYTES
  - CURSOR_SECRET (HMAC for cursors)
  - STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, STRIPE_PRICE_ID
  - LOG_JSON=true|false
  - UPLOAD_MAX_BYTES (default 10 MiB), UPLOAD_ALLOWED_MIME (csv of types)
  - GOOGLE_CLIENT_IDS (csv)
  - APPLE_AUDIENCE (bundle/service id)

## Auth (providers)
- Email/password:
  - POST /v1/auth/signup, POST /v1/auth/login
- Google:
  - POST /v1/auth/google { id_token }
  - Set GOOGLE_CLIENT_IDS to your OAuth client ID(s)
- Apple:
  - POST /v1/auth/apple { identity_token }
  - Set APPLE_AUDIENCE to your bundle/service ID

## Rate limiting & headers
- Default: 120 requests/min per client IP (simple in-memory)
- Standard security headers are applied to responses

## Pagination
- GET /v1/transactions?limit=50&cursor=opaqueToken ⇒ returns next_cursor

## Receipt flow
1) POST /v1/auth/signup → /v1/auth/login (get Bearer token)
2) POST /v1/receipts/upload → presigned PUT URL and object_key
3) PUT the file to upload_url
4) POST /v1/receipts/confirm with receipt_id + object_key (size/type validated)
5) Worker picks job, OCRs image, writes transaction

## Exports
- POST /v1/export/csv {from_date,to_date} → job_id
- GET /v1/export/csv/{job_id} → when done, returns download_url

## Stripe
- POST /v1/subscription/checkout → returns Stripe checkout URL
- POST /v1/subscription/webhook → Stripe webhook endpoint (verified)

## Testing
- Local:
  - Install: `pip install -r backend/requirements.txt && pip install pytest requests`
  - Start stack: `docker compose up -d --build db minio api worker`
  - Run: `pytest -q backend/tests`
- CI:
  - GitHub Actions workflow `.github/workflows/ci.yml` spins up services, applies migrations, builds api/worker, then runs pytest.
