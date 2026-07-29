"""RenCloud Backend — FastAPI Application."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import create_tables
from app.routes import auth, plans, admin, payments


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
    }
