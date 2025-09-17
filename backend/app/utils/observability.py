import time
import uuid
from typing import Callable

from fastapi import Request
from starlette.types import ASGIApp, Receive, Scope, Send
from prometheus_client import Counter, Histogram, CollectorRegistry, CONTENT_TYPE_LATEST, generate_latest
from fastapi.responses import Response
import json


REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_latency_seconds",
    "HTTP request latency",
    ["method", "path"],
)


class RequestIdMiddleware:
    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        request_id = str(uuid.uuid4())
        scope.setdefault("headers", [])

        async def send_wrapper(message):
            if message.get("type") == "http.response.start":
                headers = list(message.get("headers", []))
                headers.append((b"x-request-id", request_id.encode("utf-8")))
                message["headers"] = headers
            await send(message)

        await self.app(scope, receive, send_wrapper)


class MetricsMiddleware:
    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        start = time.time()
        method = scope.get("method", "").upper()
        path = scope.get("path", "")
        status_code = 500

        async def send_wrapper(message):
            nonlocal status_code
            if message.get("type") == "http.response.start":
                status_code = message.get("status")
            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            REQUEST_COUNT.labels(method=method, path=path, status=str(status_code)).inc()
            REQUEST_LATENCY.labels(method=method, path=path).observe(time.time() - start)


class JsonLoggingMiddleware:
    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        method = scope.get("method", "").upper()
        path = scope.get("path", "")
        client = scope.get("client")[0] if scope.get("client") else "unknown"
        start = time.time()
        request_id = str(uuid.uuid4())

        async def send_wrapper(message):
            if message.get("type") == "http.response.start":
                headers = list(message.get("headers", []))
                headers.append((b"x-request-id", request_id.encode("utf-8")))
                message["headers"] = headers
            await send(message)

        await self.app(scope, receive, send_wrapper)
        duration = time.time() - start
        # Simple stdout JSON log
        print(json.dumps({
            "ts": int(time.time()*1000),
            "lvl": "info",
            "msg": "request",
            "request_id": request_id,
            "method": method,
            "path": path,
            "client": client,
            "duration_ms": int(duration * 1000)
        }))


class RateLimiter:
    def __init__(self, app: ASGIApp, requests: int = 60, window_seconds: int = 60):
        self.app = app
        self.requests = requests
        self.window = window_seconds
        self.buckets = {}

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        client = None
        for k, v in scope.get("headers", []):
            if k == b"x-forwarded-for":
                client = v.decode("utf-8").split(",")[0].strip()
                break
        if not client:
            client = scope.get("client")[0] if scope.get("client") else "unknown"

        now = int(time.time())
        window_start = now - (now % self.window)
        key = (client, window_start)
        count = self.buckets.get(key, 0) + 1
        self.buckets[key] = count

        # cleanup
        for (c, ws) in list(self.buckets.keys()):
            if ws < window_start:
                self.buckets.pop((c, ws), None)

        if count > self.requests:
            response = Response(
                content=b'{"error": {"code": "RATE_LIMITED", "message": "Too many requests", "details": {}}}',
                status_code=429,
                media_type="application/json",
            )
            await response(scope, receive, send)
            return

        await self.app(scope, receive, send)


def metrics_endpoint():
    data = generate_latest()
    return Response(content=data, media_type=CONTENT_TYPE_LATEST)


