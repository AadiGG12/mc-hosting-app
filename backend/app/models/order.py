"""Order database model for tracking Razorpay payments and server provisioning."""

from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Order(Base):
    """Tracks a plan purchase from Razorpay payment to Pterodactyl server creation."""

    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # User info (from Pterodactyl, not stored separately)
    user_ptero_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    user_email: Mapped[str] = mapped_column(String(255), nullable=False)
    user_name: Mapped[str] = mapped_column(String(255), nullable=False, default="")

    # Plan reference
    plan_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("hosting_plans.id"), nullable=False
    )
    plan_name: Mapped[str] = mapped_column(String(100), nullable=False)

    # Razorpay details
    razorpay_order_id: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, index=True
    )
    razorpay_payment_id: Mapped[str] = mapped_column(
        String(100), nullable=True
    )
    razorpay_signature: Mapped[str] = mapped_column(String(500), nullable=True)

    # Payment
    amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="INR")

    # Status: created → paid → provisioning → active | failed
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="created", index=True
    )

    # Pterodactyl server (after provisioning)
    pterodactyl_server_id: Mapped[int] = mapped_column(Integer, nullable=True)
    pterodactyl_server_identifier: Mapped[str] = mapped_column(
        String(20), nullable=True
    )

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    completed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Relationship
    plan = relationship("HostingPlan", lazy="selectin")

    def __repr__(self) -> str:
        return f"<Order {self.razorpay_order_id} status={self.status}>"
