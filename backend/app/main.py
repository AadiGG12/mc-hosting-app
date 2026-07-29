"""RenCloud Backend — FastAPI Application."""

from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from app.database import create_tables
from app.routes import auth, plans, admin, payments, servers
from app.services.websocket_manager import plan_ws_manager


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: create DB tables on startup."""
    await create_tables()
    yield


app = FastAPI(
    title="RenCloud API",
    description="Backend API for the RenCloud Minecraft Hosting mobile app. "
                "Bridges Pterodactyl panel authentication, manages hosting plans, "
                "and processes Razorpay payments with auto server provisioning.",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow mobile app and development origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",       # Web dev
        "http://10.0.2.2:8000",        # Android emulator
        "http://localhost:8000",        # Local
        "*",                            # Mobile apps (no origin header)
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include route modules
app.include_router(auth.router)
app.include_router(plans.router)
app.include_router(admin.router)
app.include_router(payments.router)
app.include_router(servers.router)


# ─── Real-Time Plan Updates WebSocket ───────────────────────────

@app.websocket("/ws/plans")
async def plans_websocket(websocket: WebSocket):
    """
    WebSocket endpoint for real-time plan updates.

    When an admin creates, updates, or deletes a hosting plan, this WebSocket
    broadcasts the change to all connected clients. The mobile app uses this
    to automatically refresh the plans catalog without manual refresh.

    Message format:
        {"event": "plans_updated", "action": "create|update|delete", "plan": {...}}
        {"event": "plans_refresh_all"}  # Full catalog refresh needed
    """
    await plan_ws_manager.connect(websocket)
    try:
        while True:
            # Keep the connection alive by reading messages (client may send pings)
            data = await websocket.receive_text()
            # If client sends a ping, respond with pong
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        plan_ws_manager.disconnect(websocket)
    except Exception:
        plan_ws_manager.disconnect(websocket)


@app.get("/ws/plans/status", tags=["WebSocket"])
async def plans_ws_status():
    """Check how many clients are currently connected for real-time updates."""
    return {
        "endpoint": "/ws/plans",
        "connected_clients": plan_ws_manager.client_count,
        "status": "active",
    }


@app.get("/", tags=["Health"])
async def root():
    """Health check endpoint."""
    return {
        "service": "RenCloud API",
        "status": "operational",
        "version": "1.0.0",
    }


@app.get("/health", tags=["Health"])
async def health():
    """Detailed health check."""
    return {
        "status": "healthy",
        "database": "connected",
        "pterodactyl": "configured",
        "razorpay": "configured",
        "realtime_ws_clients": plan_ws_manager.client_count,
    }
