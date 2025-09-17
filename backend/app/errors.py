from typing import Any, Dict
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException


class AppError(Exception):
    def __init__(self, code: str, message: str, details: Dict[str, Any] | None = None, status_code: int = 400):
        self.code = code
        self.message = message
        self.details = details or {}
        self.status_code = status_code


def _format_error(code: str, message: str, details: Dict[str, Any] | None = None) -> Dict[str, Any]:
    return {"error": {"code": code, "message": message, "details": details or {}}}


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def app_error_handler(_: Request, exc: AppError):
        return JSONResponse(status_code=exc.status_code, content=_format_error(exc.code, exc.message, exc.details))

    @app.exception_handler(HTTPException)
    async def http_error_handler(_: Request, exc: HTTPException):
        # Map to our shape
        code = f"HTTP_{exc.status_code}"
        message = exc.detail if isinstance(exc.detail, str) else "HTTP error"
        return JSONResponse(status_code=exc.status_code, content=_format_error(code, message))

    @app.exception_handler(Exception)
    async def unhandled_error_handler(_: Request, exc: Exception):
        # Avoid leaking internals in production; log if needed
        return JSONResponse(status_code=500, content=_format_error("INTERNAL_SERVER_ERROR", "An unexpected error occurred"))


