"""Payment routes — Razorpay order creation, verification, and server provisioning."""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_user
from app.database import get_db
from app.models.order import Order
from app.models.plan import HostingPlan
from app.services.pterodactyl_client import ptero_client
from app.services.razorpay_service import razorpay_service
from app.config import get_settings

router = APIRouter(prefix="/payments", tags=["Payments"])


# ─── Schemas ──────────────────────────────────────────────────────

class CreateOrderRequest(BaseModel):
    """Request to create a Razorpay order for a plan."""
    plan_id: int
    server_name: str = "My Minecraft Server"


class CreateOrderResponse(BaseModel):
    """Razorpay order details for the mobile app checkout."""
    order_id: int  # Our internal order ID
    razorpay_order_id: str
    razorpay_key_id: str
    amount: int  # In paise
    currency: str
    plan_name: str
    user_email: str
    user_name: str


class VerifyPaymentRequest(BaseModel):
    """Payment verification after Razorpay checkout completes."""
    order_id: int
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str


class VerifyPaymentResponse(BaseModel):
    """Response after successful payment and server provisioning."""
    status: str
    message: str
    server_identifier: str | None = None
    order_id: int


class OrderStatusResponse(BaseModel):
    """Order status for the user."""
    id: int
    plan_name: str
    amount: float
    currency: str
    status: str
    server_identifier: str | None
    created_at: str | None

    model_config = {"from_attributes": True}


# ─── Routes ──────────────────────────────────────────────────────

@router.post("/create-order", response_model=CreateOrderResponse)
async def create_payment_order(
    request: CreateOrderRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Create a Razorpay order for a hosting plan.

    Flow:
    1. Look up the plan
    2. Create a Razorpay order
    3. Create an Order record in our DB
    4. Return Razorpay details for the mobile app to open checkout
    """
    settings = get_settings()

    # Get the plan
    result = await db.execute(
        select(HostingPlan).where(
            HostingPlan.id == request.plan_id,
            HostingPlan.is_active == True,
        )
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Plan not found or inactive",
        )

    # Convert price to paise (₹1 = 100 paise)
    amount_paise = int(float(plan.price_monthly) * 100)

    # Create Razorpay order
    try:
        rz_order = razorpay_service.create_order(
            amount_paise=amount_paise,
            currency=plan.currency,
            receipt=f"plan_{plan.id}_{current_user['user_id']}",
            notes={
                "plan_id": str(plan.id),
                "plan_name": plan.name,
                "user_id": str(current_user["user_id"]),
                "user_email": current_user["email"],
                "server_name": request.server_name,
            },
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to create Razorpay order: {str(e)}",
        )

    # Create our Order record
    user_name = f"{current_user.get('first_name', '')} {current_user.get('last_name', '')}".strip()
    order = Order(
        user_ptero_id=current_user["user_id"],
        user_email=current_user["email"],
        user_name=user_name or current_user.get("username", ""),
        plan_id=plan.id,
        plan_name=plan.name,
        razorpay_order_id=rz_order["id"],
        amount=plan.price_monthly,
        currency=plan.currency,
        status="created",
    )
    db.add(order)
    await db.flush()
    await db.refresh(order)

    return CreateOrderResponse(
        order_id=order.id,
        razorpay_order_id=rz_order["id"],
        razorpay_key_id=settings.RAZORPAY_KEY_ID,
        amount=amount_paise,
        currency=plan.currency,
        plan_name=plan.name,
        user_email=current_user["email"],
        user_name=user_name,
    )


@router.post("/verify", response_model=VerifyPaymentResponse)
async def verify_payment(
    request: VerifyPaymentRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Verify Razorpay payment and auto-provision a Pterodactyl server.

    Flow:
    1. Verify Razorpay signature (HMAC-SHA256)
    2. Update order status to 'paid'
    3. Create Pterodactyl server with plan resources
    4. Update order with server details, status 'active'
    """
    # Look up our order
    result = await db.execute(
        select(Order).where(
            Order.id == request.order_id,
            Order.razorpay_order_id == request.razorpay_order_id,
            Order.user_ptero_id == current_user["user_id"],
        )
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )

    if order.status != "created":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order already processed (status: {order.status})",
        )

    # Verify Razorpay signature
    is_valid = razorpay_service.verify_payment(
        request.razorpay_order_id,
        request.razorpay_payment_id,
        request.razorpay_signature,
    )
    if not is_valid:
        order.status = "failed"
        await db.flush()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment verification failed — invalid signature",
        )

    # Update order as paid
    order.razorpay_payment_id = request.razorpay_payment_id
    order.razorpay_signature = request.razorpay_signature
    order.status = "paid"
    await db.flush()

    # Get the plan for provisioning config
    plan_result = await db.execute(
        select(HostingPlan).where(HostingPlan.id == order.plan_id)
    )
    plan = plan_result.scalar_one_or_none()
    if not plan:
        order.status = "failed"
        await db.flush()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Plan not found for provisioning",
        )

    # Check if plan has Pterodactyl provisioning config
    if not plan.pterodactyl_egg_id or not plan.pterodactyl_nest_id:
        # If no auto-provisioning config, mark as paid but not provisioned
        order.status = "paid"
        order.completed_at = datetime.now(timezone.utc)
        await db.flush()
        return VerifyPaymentResponse(
            status="paid",
            message="Payment verified. Server will be provisioned manually by admin.",
            order_id=order.id,
        )

    # Auto-provision Pterodactyl server
    order.status = "provisioning"
    await db.flush()

    try:
        # Generate server name
        server_name = f"{order.user_name}'s {plan.name} Server"

        server_data = await ptero_client.create_server(
            user_id=order.user_ptero_id,
            name=server_name,
            ram_mb=plan.ram_mb,
            cpu_percent=plan.cpu_percent,
            storage_mb=plan.storage_gb * 1024,  # Convert GB to MB
            database_limit=plan.database_limit,
            backup_limit=plan.backup_limit,
            nest_id=plan.pterodactyl_nest_id,
            egg_id=plan.pterodactyl_egg_id,
            location_id=plan.pterodactyl_location_id or 1,
            node_id=plan.pterodactyl_node_id,
        )

        # Extract server info from response
        server_attrs = server_data.get("attributes", {})
        server_id = server_attrs.get("id")
        server_identifier = server_attrs.get("identifier", "")

        order.pterodactyl_server_id = server_id
        order.pterodactyl_server_identifier = server_identifier
        order.status = "active"
        order.completed_at = datetime.now(timezone.utc)
        await db.flush()

        return VerifyPaymentResponse(
            status="active",
            message="Payment verified and server provisioned successfully!",
            server_identifier=server_identifier,
            order_id=order.id,
        )

    except Exception as e:
        order.status = "failed"
        order.completed_at = datetime.now(timezone.utc)
        await db.flush()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Payment verified but server provisioning failed: {str(e)}. "
                   "Please contact support — your payment is safe.",
        )


@router.get("/orders", response_model=list[OrderStatusResponse])
async def list_my_orders(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """List orders for the current user."""
    result = await db.execute(
        select(Order)
        .where(Order.user_ptero_id == current_user["user_id"])
        .order_by(Order.created_at.desc())
    )
    return result.scalars().all()


@router.post("/webhook")
async def razorpay_webhook(request: Request):
    """Razorpay webhook endpoint for backup payment verification.

    This handles the payment.captured event in case the app's
    verify endpoint wasn't called (e.g., user closed the app).
    """
    body = await request.body()
    signature = request.headers.get("X-Razorpay-Signature", "")

    if not signature:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing webhook signature",
        )

    # Verify webhook signature
    is_valid = razorpay_service.verify_webhook_signature(body, signature)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid webhook signature",
        )

    # Process the event
    import json
    event = json.loads(body)
    event_type = event.get("event", "")

    if event_type == "payment.captured":
        payment = event.get("payload", {}).get("payment", {}).get("entity", {})
        rz_order_id = payment.get("order_id")

        if rz_order_id:
            # TODO: Process webhook payment - similar to verify endpoint
            # This is a backup path for when the app doesn't call verify
            pass

    return {"status": "ok"}
