"""Public plans routes — browse available hosting plans."""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.plan import HostingPlan

router = APIRouter(prefix="/plans", tags=["Plans"])


class PlanResponse(BaseModel):
    """Public plan data returned to the mobile app."""
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
    is_featured: bool
    sort_order: int

    model_config = {"from_attributes": True}


@router.get("", response_model=list[PlanResponse])
async def list_plans(db: AsyncSession = Depends(get_db)):
    """Get all active hosting plans, sorted by sort_order.

    This endpoint is public — no authentication required.
    The mobile app calls this to display the plans catalog.
    """
    result = await db.execute(
        select(HostingPlan)
        .where(HostingPlan.is_active == True)
        .order_by(HostingPlan.sort_order, HostingPlan.price_monthly)
    )
    plans = result.scalars().all()
    return plans


@router.get("/{slug}", response_model=PlanResponse)
async def get_plan(slug: str, db: AsyncSession = Depends(get_db)):
    """Get a single plan by slug.

    Returns 404 if the plan doesn't exist or is inactive.
    """
    result = await db.execute(
        select(HostingPlan)
        .where(HostingPlan.slug == slug, HostingPlan.is_active == True)
    )
    plan = result.scalar_one_or_none()

    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Plan '{slug}' not found",
        )
    return plan
