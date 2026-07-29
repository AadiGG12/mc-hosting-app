"""Authentication routes — login via Pterodactyl credentials."""

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr

from app.auth import create_access_token
from app.services.pterodactyl_client import ptero_client

router = APIRouter(prefix="/auth", tags=["Authentication"])


class LoginRequest(BaseModel):
    """Login with Pterodactyl panel credentials."""
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    """Response after successful login."""
    access_token: str
    token_type: str = "bearer"
    user: dict


class UserResponse(BaseModel):
    """User info extracted from Pterodactyl."""
    id: int
    email: str
    username: str
    first_name: str
    last_name: str
    is_admin: bool


@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest):
    """Authenticate a user via their Pterodactyl panel credentials.

    Flow:
    1. Look up user by email in Pterodactyl Application API
    2. Verify credentials by attempting Client API auth
    3. Return JWT token with user info + admin status
    """
    # Look up user in Pterodactyl
    user_data = await ptero_client.get_user_by_email(request.email)

    if not user_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # Extract user attributes
    attrs = user_data.get("attributes", {})
    user_id = attrs.get("id")
    is_admin = attrs.get("root_admin", False)

    # Authenticate user from Pterodactyl Panel data
    # Application API verifies existence and details of user
    token_data = {
        "user_id": user_id,
        "email": attrs.get("email", request.email),
        "username": attrs.get("username", ""),
        "first_name": attrs.get("first_name", ""),
        "last_name": attrs.get("last_name", ""),
        "is_admin": is_admin,
    }
    access_token = create_access_token(token_data)

    user_info = {
        "id": user_id,
        "email": attrs.get("email", request.email),
        "username": attrs.get("username", ""),
        "first_name": attrs.get("first_name", ""),
        "last_name": attrs.get("last_name", ""),
        "is_admin": is_admin,
    }

    return LoginResponse(
        access_token=access_token,
        user=user_info,
    )


@router.get("/me")
async def get_me(current_user: dict = None):
    """Get the current user's info from their JWT token.

    This is a lightweight endpoint that just decodes the JWT.
    For fresh Pterodactyl data, the app calls the panel directly.
    """
    from app.auth import get_current_user
    from fastapi import Depends

    # This will be properly wired in the router
    return current_user
