# Backend (FastAPI)

## Run
```powershell
# From repo root
docker compose up -d --build db minio api worker
```

- API Health: http://localhost:8000/healthz
- API Ready: http://localhost:8000/readyz (DB + S3 readiness)
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
  - ADMIN_SECRET (required for rules writes outside dev)

## Auth (providers)
- Email/password:
  - POST /v1/auth/signup
  - POST /v1/auth/login
  - GET /v1/auth/me
  - POST /v1/auth/logout
  - POST /v1/auth/logout_all
  - POST /v1/auth/rotate
- Google:
  - POST /v1/auth/google { id_token }
  - Set GOOGLE_CLIENT_IDS to your OAuth client ID(s)
- Apple:
  - POST /v1/auth/apple { identity_token }
  - Set APPLE_AUDIENCE to your bundle/service ID

## Rate limiting & headers
- Default: 120 requests/min per client IP (simple in-memory)
- Standard security headers are applied to responses

## Premium gating
- Manual transactions and CSV exports require an active premium subscription (`subscriptions.plan='premium'` and `status='active'`).

## Pagination
- GET /v1/transactions?limit=50&cursor=opaqueToken&from_date=YYYY-MM-DD&to_date=YYYY-MM-DD&category=dining

## Receipt flow
1) POST /v1/auth/signup → /v1/auth/login (get Bearer token)
2) POST /v1/receipts/upload → presigned PUT URL and object_key
3) PUT the file to upload_url
4) POST /v1/receipts/confirm with receipt_id + object_key (size/type validated)
5) Worker picks job, OCRs image, writes transaction
6) Account deletion also cleans up S3 objects under `receipts/<user_id>/` and `exports/<user_id>/` (best-effort)

## Exports
- POST /v1/export/csv {from_date,to_date,wait?,timeout_seconds?} → job_id or { job_id, download_url } when wait=true and job finishes within timeout
- GET /v1/export/csv/{job_id} → when done, returns download_url
  - Premium required: Exports are gated to users with plan=premium and status=active

## Usage & Badges
- GET /v1/usage → month_key, scans_used, scans_remaining
- GET /v1/badges → global badges
- GET /v1/user/badges → current user badges

## Budgets & Dashboard
- PUT /v1/budgets → upsert a budget row
- GET /v1/budgets?period_start=&period_end= → list budgets
- GET /v1/dashboard/summary?period=month&anchor=YYYY-MM-DD
- GET /v1/dashboard/categories?period=month&anchor=YYYY-MM-DD

## Categorization rules
- Endpoints (admin):
  - GET /v1/rules/merchant
  - POST /v1/rules/merchant { merchant_pattern, category, confidence, active }
  - GET /v1/rules/keyword
  - POST /v1/rules/keyword { keyword, scope, category, confidence, active }
- Authorization:
  - In dev: writes allowed without secret
  - In non-dev: set ADMIN_SECRET and include header `X-Admin-Secret: <secret>`
- Application:
  - Manual transactions auto-category when `category` omitted
  - Receipt OCR pipeline applies rules using OCR text

## Stripe
- POST /v1/subscription/checkout → returns Stripe checkout URL
- POST /v1/subscription/webhook → Stripe webhook endpoint (verified)
  - Handles: checkout.session.completed, customer.subscription.* (created/updated/deleted), invoice.payment_succeeded, invoice.payment_failed
- GET /v1/subscription → current plan/status

## Postman
- Import `backend/postman_collection.json`
- Set variables: `base_url` (default http://localhost:8000), `token` (from /v1/auth/login), `admin_secret` (if set)

## Testing
- Local:
  - Install: `pip install -r backend/requirements.txt && pip install pytest requests`
  - Start stack: `docker compose up -d --build db minio api worker`
  - Run: `pytest -q backend/tests`
- CI:
  - If you add a workflow, ensure it starts db+minio, applies migrations, builds api/worker, and runs pytest.
