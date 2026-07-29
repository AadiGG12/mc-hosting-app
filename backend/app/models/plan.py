"""HostingPlan database model."""

from datetime import datetime
from decimal import Decimal

from sqlalchemy import JSON, Boolean, DateTime, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class HostingPlan(Base):
    """Minecraft hosting plan stored in PostgreSQL."""

    __tablename__ = "hosting_plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    description: Mapped[str] = mapped_column(String(500), nullable=True, default="")

    # Pricing
    price_monthly: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="INR")

    # Resources
    ram_mb: Mapped[int] = mapped_column(Integer, nullable=False)
    cpu_percent: Mapped[int] = mapped_column(Integer, nullable=False, default=100)
    storage_gb: Mapped[int] = mapped_column(Integer, nullable=False, default=10)
    max_players: Mapped[int] = mapped_column(Integer, nullable=False, default=20)
    database_limit: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    backup_limit: Mapped[int] = mapped_column(Integer, nullable=False, default=1)

    # Features list (JSON array of strings)
    features: Mapped[list] = mapped_column(JSON, nullable=False, default=list)

    # Pterodactyl provisioning config
    pterodactyl_nest_id: Mapped[int] = mapped_column(Integer, nullable=True)
    pterodactyl_egg_id: Mapped[int] = mapped_column(Integer, nullable=True)
    pterodactyl_node_id: Mapped[int] = mapped_column(Integer, nullable=True)
    pterodactyl_location_id: Mapped[int] = mapped_column(Integer, nullable=True)

    # Display
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    def __repr__(self) -> str:
        return f"<HostingPlan {self.name} ({self.ram_mb}MB ₹{self.price_monthly})>"
