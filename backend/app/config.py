from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="", extra="ignore")
    app_name: str = "snapbudget-api"
    env: str = "dev"

    db_host: str = "db"
    db_port: int = 5432
    db_user: str = "app"
    db_password: str = "password"
    db_name: str = "appdb"

    s3_endpoint: str = "http://minio:9000"
    s3_access_key: str = "minioadmin"
    s3_secret_key: str = "minioadmin"
    s3_region: str = "us-east-1"
    s3_bucket: str = "receipts"
    s3_use_ssl: bool = False
    s3_public_endpoint: str = ""  # if set, presigned URLs will be rewritten to this base (e.g., http://localhost:9000)

    cors_origins: str = "*"  # comma-separated list or '*'
    allowed_hosts: str = "*"  # comma-separated list or '*'
    max_request_bytes: int = 1048576  # 1 MiB default for JSON bodies

    cursor_secret: str = "dev-change-me"

    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""
    stripe_price_id: str = ""

    log_json: bool = True
    upload_max_bytes: int = 10 * 1024 * 1024  # 10 MiB
    upload_allowed_mime: str = "image/jpeg,image/png,application/pdf"

    google_client_ids: str = ""  # comma-separated
    apple_audience: str = ""  # bundle or service id
    admin_secret: str = ""

    # Admin operations (rules management). If empty, write operations allowed only in dev.
    admin_secret: str = ""

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def allowed_host_list(self) -> list[str]:
        if self.allowed_hosts.strip() == "*":
            return ["*"]
        return [h.strip() for h in self.allowed_hosts.split(",") if h.strip()]

    @property
    def allowed_mime_list(self) -> list[str]:
        return [m.strip().lower() for m in self.upload_allowed_mime.split(",") if m.strip()]


settings = Settings()

    
