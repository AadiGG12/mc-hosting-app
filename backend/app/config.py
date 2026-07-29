"""RenCloud Backend Configuration."""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Pterodactyl Panel
    PTERODACTYL_URL: str = "https://panel.rencloud.online"
    PTERODACTYL_APP_KEY: str = ""

    # JWT Authentication
    JWT_SECRET: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 1440  # 24 hours

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://rencloud:rencloud_dev_password@db:5432/rencloud"

    # Razorpay
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""
    RAZORPAY_WEBHOOK_SECRET: str = ""

    # Default currency
    DEFAULT_CURRENCY: str = "INR"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
