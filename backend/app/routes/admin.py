"""Admin routes — plan CRUD and order management for Pterodactyl root admins."""

import re
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.auth import get_admin_user
from app.database import get_db
from app.models.plan import HostingPlan
from app.models.order import Order

router = APIRouter(prefix="/admin", tags=["Admin"])


# ─── Schemas ──────────────────────────────────────────────────────

class PlanCreateRequest(BaseModel):
    """Request body for creating a new hosting plan."""
    name: str
    description: str = ""
    price_monthly: float
    currency: str = "INR"
    ram_mb: int
    cpu_percent: int = 100
    storage_gb: int = 10
    max_players: int = 20
    database_limit: int = 1
    backup_limit: int = 1
    features: list[str] = []
    pterodactyl_nest_id: int | None = None
    pterodactyl_egg_id: int | None = None
    pterodactyl_node_id: int | None = None
    pterodactyl_location_id: int | None = None
    is_featured: bool = False
    sort_order: int = 0
    is_active: bool = True


class PlanUpdateRequest(BaseModel):
    """Request body for updating a plan. All fields optional."""
    name: str | None = None
    description: str | None = None
    price_monthly: float | None = None
    currency: str | None = None
    ram_mb: int | None = None
    cpu_percent: int | None = None
    storage_gb: int | None = None
    max_players: int | None = None
    database_limit: int | None = None
    backup_limit: int | None = None
    features: list[str] | None = None
    pterodactyl_nest_id: int | None = None
    pterodactyl_egg_id: int | None = None
    pterodactyl_node_id: int | None = None
    pterodactyl_location_id: int | None = None
    is_featured: bool | None = None
    sort_order: int | None = None
    is_active: bool | None = None


class AdminPlanResponse(BaseModel):
    """Full plan data for admin views (includes inactive + Pterodactyl IDs)."""
    id: int
    name: str
    slug: str
    description: str | None
    price_monthly: float
    currency: str
    ram_mb: int
    cpu_percent: int
    storage_gb: int
    max_players: int
    database_limit: int
    backup_limit: int
    features: list
    pterodactyl_nest_id: int | None
    pterodactyl_egg_id: int | None
    pterodactyl_node_id: int | None
    pterodactyl_location_id: int | None
    is_featured: bool
    sort_order: int
    is_active: bool
    created_at: str | None
    updated_at: str | None

    model_config = {"from_attributes": True}


class OrderResponse(BaseModel):
    """Order data for admin views."""
    id: int
    user_ptero_id: int
    user_email: str
    user_name: str
    plan_id: int
    plan_name: str
    razorpay_order_id: str
    razorpay_payment_id: str | None
    amount: float
    currency: str
    status: str
    pterodactyl_server_id: int | None
    pterodactyl_server_identifier: str | None
    created_at: str | None
    completed_at: str | None

    model_config = {"from_attributes": True}


# ─── Helper ──────────────────────────────────────────────────────

def slugify(text: str) -> str:
    """Convert text to URL-safe slug."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[-\s]+", "-", text)
    return text


# ─── Plan CRUD ───────────────────────────────────────────────────

@router.get("/plans", response_model=list[AdminPlanResponse])
async def admin_list_plans(
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(get_admin_user),
):
    """List ALL plans including inactive ones. Admin only."""
    result = await db.execute(
        select(HostingPlan).order_by(HostingPlan.sort_order, HostingPlan.id)
    )
    return result.scalars().all()


@router.post("/plans", response_model=AdminPlanResponse, status_code=201)
async def admin_create_plan(
    request: PlanCreateRequest,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(get_admin_user),
):
    """Create a new hosting plan. Admin only."""
    slug = slugify(request.name)

    # Check for duplicate slug
    existing = await db.execute(
        select(HostingPlan).where(HostingPlan.slug == slug)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A plan with slug '{slug}' already exists",
        )

    plan = HostingPlan(
        name=request.name,
        slug=slug,
        description=request.description,
        price_monthly=request.price_monthly,
        currency=request.currency,
        ram_mb=request.ram_mb,
        cpu_percent=request.cpu_percent,
        storage_gb=request.storage_gb,
        max_players=request.max_players,
        database_limit=request.database_limit,
        backup_limit=request.backup_limit,
        features=request.features,
        pterodactyl_nest_id=request.pterodactyl_nest_id,
        pterodactyl_egg_id=request.pterodactyl_egg_id,
        pterodactyl_node_id=request.pterodactyl_node_id,
        pterodactyl_location_id=request.pterodactyl_location_id,
        is_featured=request.is_featured,
        sort_order=request.sort_order,
        is_active=request.is_active,
    )

    db.add(plan)
    await db.flush()
    await db.refresh(plan)
    return plan


@router.patch("/plans/{plan_id}", response_model=AdminPlanResponse)
async def admin_update_plan(
    plan_id: int,
    request: PlanUpdateRequest,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(get_admin_user),
):
    """Update an existing plan. Admin only. Only provided fields are updated."""
    result = await db.execute(
        select(HostingPlan).where(HostingPlan.id == plan_id)
    )
    plan = result.scalar_one_or_none()

    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Plan {plan_id} not found",
        )

    # Update only provided fields
    update_data = request.model_dump(exclude_unset=True)
    if "name" in update_data:
        update_data["slug"] = slugify(update_data["name"])

    for field, value in update_data.items():
        setattr(plan, field, value)

    await db.flush()
    await db.refresh(plan)
    return plan


@router.delete("/plans/{plan_id}")
async def admin_delete_plan(
    plan_id: int,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(get_admin_user),
):
    """Soft-delete a plan (set is_active = false). Admin only."""
    result = await db.execute(
        select(HostingPlan).where(HostingPlan.id == plan_id)
    )
    plan = result.scalar_one_or_none()

    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Plan {plan_id} not found",
        )

    plan.is_active = False
    await db.flush()
    return {"message": f"Plan '{plan.name}' deactivated"}


# ─── Order Management ───────────────────────────────────────────

@router.get("/orders", response_model=list[OrderResponse])
async def admin_list_orders(
    status_filter: str | None = None,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(get_admin_user),
):
    """List all orders, optionally filtered by status. Admin only."""
    query = select(Order).order_by(Order.created_at.desc())

    if status_filter:
        query = query.where(Order.status == status_filter)

    result = await db.execute(query)
    return result.scalars().all()


@router.get("/orders/{order_id}", response_model=OrderResponse)
async def admin_get_order(
    order_id: int,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(get_admin_user),
):
    """Get a single order by ID. Admin only."""
    result = await db.execute(
        select(Order).where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order {order_id} not found",
        )
    return order
