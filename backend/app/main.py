from fastapi import FastAPI, Request
from fastapi.responses import ORJSONResponse
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .routers.v1 import router as v1_router
from .utils.storage import ensure_bucket
from .errors import register_error_handlers
from .utils.observability import RequestIdMiddleware, MetricsMiddleware, RateLimiter, metrics_endpoint, JsonLoggingMiddleware


def create_app() -> FastAPI:
    app = FastAPI(
        title="SnapBudget API",
        default_response_class=ORJSONResponse,
        version="0.1.0",
    )

    # Observability & CORS
    if settings.log_json:
        app.add_middleware(JsonLoggingMiddleware)
    app.add_middleware(RequestIdMiddleware)
    app.add_middleware(MetricsMiddleware)
    app.add_middleware(RateLimiter, requests=120, window_seconds=60)

    # CORS
    if settings.cors_origin_list == ["*"]:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
            max_age=600,
        )
    else:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.cors_origin_list,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
            max_age=600,
        )

    # Basic security headers and request size guard
    @app.middleware("http")
    async def security_headers_and_size(request: Request, call_next):
        # Size guard for incoming JSON bodies
        content_length = request.headers.get("content-length")
        if content_length and content_length.isdigit():
            if int(content_length) > settings.max_request_bytes:
                return ORJSONResponse({"error": {"code": "REQUEST_TOO_LARGE", "message": "Body too large", "details": {}}}, status_code=413)

        response = await call_next(request)
        # Security headers
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "no-referrer")
        response.headers.setdefault("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
        response.headers.setdefault("X-XSS-Protection", "0")
        return response

    @app.get("/healthz")
    async def healthz():
        return {"status": "ok", "app": settings.app_name}

    @app.get("/metrics")
    async def metrics():
        return metrics_endpoint()

    app.include_router(v1_router)

    @app.on_event("startup")
    async def _startup():
        try:
            ensure_bucket()
        except Exception:
            # Non-fatal during local dev if MinIO not ready yet; compose dependency should cover it
            pass

    register_error_handlers(app)

    return app


app = create_app()


