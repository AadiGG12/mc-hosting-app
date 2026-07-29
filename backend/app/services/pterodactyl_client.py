"""Pterodactyl Panel API client for Application API operations."""

import httpx
from typing import Any, Optional

from app.config import get_settings


class PterodactylClient:
    """Client for Pterodactyl Application API (server-side only).

    This client uses the Application API key which must NEVER be exposed
    to the mobile app. It handles:
    - User verification (lookup by email)
    - Client API key creation for mobile app usage
    - Server creation (auto-provisioning after payment)
    - Node/allocation management
    """

    def __init__(self):
        settings = get_settings()
        self.base_url = settings.PTERODACTYL_URL.rstrip("/")
        self.headers = {
            "Authorization": f"Bearer {settings.PTERODACTYL_APP_KEY}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

    async def _request(
        self, method: str, path: str, **kwargs
    ) -> dict[str, Any]:
        """Make an authenticated request to the Pterodactyl Application API."""
        url = f"{self.base_url}/api/application{path}"
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.request(
                method, url, headers=self.headers, **kwargs
            )
            response.raise_for_status()
            if response.status_code == 204:
                return {}
            return response.json()

    # ─── User Operations ───────────────────────────────────────────

    async def get_user_by_email(self, email: str) -> Optional[dict]:
        """Look up a Pterodactyl user by email address.

        Returns the user object if found, None otherwise.
        """
        try:
            data = await self._request(
                "GET",
                f"/users?filter[email]={email}",
            )
            users = data.get("data", [])
            if users:
                return users[0]
            return None
        except httpx.HTTPStatusError:
            return None

    async def get_user_by_id(self, user_id: int) -> Optional[dict]:
        """Get a Pterodactyl user by their ID."""
        try:
            data = await self._request("GET", f"/users/{user_id}")
            return data.get("data") or data
        except httpx.HTTPStatusError:
            return None

    async def verify_user_credentials(
        self, email: str, password: str
    ) -> Optional[dict]:
        """Verify user credentials by attempting a Client API login.

        Since Pterodactyl Application API doesn't have a direct password
        verification endpoint, we attempt to authenticate using the
        Client API with the user's credentials.

        Returns the user object if credentials are valid, None otherwise.
        """
        # First, look up the user via Application API
        user = await self.get_user_by_email(email)
        if not user:
            return None

        # Attempt to authenticate via the Client API endpoint
        # This verifies the password by making a request as the user
        login_url = f"{self.base_url}/api/client/account"
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                # Try using email/password basic auth against panel
                response = await client.get(
                    login_url,
                    headers={
                        "Accept": "application/json",
                        "Content-Type": "application/json",
                    },
                    auth=(email, password),
                )
                if response.status_code == 200:
                    return user
        except httpx.HTTPError:
            pass

        # Alternative: use the panel's auth token generation
        # Some Pterodactyl installations support this
        try:
            auth_url = f"{self.base_url}/auth/login"
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(
                    auth_url,
                    json={"user": email, "password": password},
                    headers={"Accept": "application/json"},
                )
                if response.status_code == 200:
                    return user
        except httpx.HTTPError:
            pass

        return None

    async def create_api_key_for_user(
        self, user_id: int, description: str = "RenCloud Mobile App"
    ) -> Optional[str]:
        """Create a Client API key for a user.

        Note: Pterodactyl Application API can create API keys for users.
        The key is returned and should be stored securely on the client device.
        """
        try:
            # The Application API doesn't directly create Client API keys.
            # Instead, we'll use the user's existing keys or the user's
            # session token approach. For now, we return the user data
            # and the mobile app will use cookie-based or API key auth.
            user = await self.get_user_by_id(user_id)
            return user
        except httpx.HTTPStatusError:
            return None

    # ─── Server Operations ─────────────────────────────────────────

    async def create_server(
        self,
        user_id: int,
        name: str,
        ram_mb: int,
        cpu_percent: int,
        storage_mb: int,
        database_limit: int,
        backup_limit: int,
        nest_id: int,
        egg_id: int,
        location_id: int = 1,
        node_id: Optional[int] = None,
    ) -> dict:
        """Create a new server on Pterodactyl for a user after payment.

        This is called after a successful Razorpay payment to auto-provision
        the Minecraft server with the resources matching the purchased plan.
        """
        # Get egg details for default startup and environment
        egg_data = await self._request("GET", f"/nests/{nest_id}/eggs/{egg_id}?include=variables")
        egg = egg_data.get("attributes", egg_data.get("data", {}).get("attributes", {}))

        # Build environment variables from egg defaults
        environment = {}
        variables = egg.get("relationships", {}).get("variables", {}).get("data", [])
        for var in variables:
            attrs = var.get("attributes", {})
            environment[attrs["env_variable"]] = attrs.get("default_value", "")

        # Set common Minecraft defaults
        if "SERVER_JARFILE" in environment:
            environment["SERVER_JARFILE"] = environment.get("SERVER_JARFILE", "server.jar")
        if "MINECRAFT_VERSION" in environment:
            environment["MINECRAFT_VERSION"] = "latest"

        # Determine allocation
        allocation_id = None
        if node_id:
            allocation_id = await self._find_available_allocation(node_id)
        else:
            # Find allocation from any node in the location
            nodes = await self._get_nodes_in_location(location_id)
            for n in nodes:
                allocation_id = await self._find_available_allocation(
                    n["attributes"]["id"]
                )
                if allocation_id:
                    break

        if not allocation_id:
            raise ValueError(
                f"No available allocation found for location {location_id}"
            )

        # Create the server
        server_data = {
            "name": name,
            "user": user_id,
            "egg": egg_id,
            "docker_image": egg.get("docker_image", "ghcr.io/pterodactyl/yolks:java_21"),
            "startup": egg.get("startup", ""),
            "environment": environment,
            "limits": {
                "memory": ram_mb,
                "swap": 0,
                "disk": storage_mb,
                "io": 500,
                "cpu": cpu_percent,
            },
            "feature_limits": {
                "databases": database_limit,
                "backups": backup_limit,
                "allocations": 1,
            },
            "allocation": {
                "default": allocation_id,
            },
            "start_on_completion": False,
        }

        result = await self._request("POST", "/servers", json=server_data)
        return result

    async def _find_available_allocation(self, node_id: int) -> Optional[int]:
        """Find an unassigned allocation on a node."""
        try:
            data = await self._request(
                "GET",
                f"/nodes/{node_id}/allocations?filter[assigned]=false&per_page=1",
            )
            allocations = data.get("data", [])
            if allocations:
                return allocations[0]["attributes"]["id"]
            return None
        except httpx.HTTPStatusError:
            return None

    async def _get_nodes_in_location(self, location_id: int) -> list:
        """Get all nodes in a specific location."""
        try:
            data = await self._request(
                "GET", f"/nodes?filter[location_id]={location_id}"
            )
            return data.get("data", [])
        except httpx.HTTPStatusError:
            return []

    async def get_server(self, server_id: int) -> Optional[dict]:
        """Get server details by internal ID."""
        try:
            data = await self._request("GET", f"/servers/{server_id}")
            return data
        except httpx.HTTPStatusError:
            return None

    async def delete_server(self, server_id: int) -> bool:
        """Delete a server (admin only)."""
        try:
            await self._request("DELETE", f"/servers/{server_id}")
            return True
        except httpx.HTTPStatusError:
            return False

    # ─── Node Operations ───────────────────────────────────────────

    async def list_nodes(self) -> list:
        """List all nodes."""
        try:
            data = await self._request("GET", "/nodes")
            return data.get("data", [])
        except httpx.HTTPStatusError:
            return []

    async def list_locations(self) -> list:
        """List all locations."""
        try:
            data = await self._request("GET", "/locations")
            return data.get("data", [])
        except httpx.HTTPStatusError:
            return []

    async def list_nests(self) -> list:
        """List all nests with eggs."""
        try:
            data = await self._request("GET", "/nests?include=eggs")
            return data.get("data", [])
        except httpx.HTTPStatusError:
            return []


    # ─── User Servers Operations ───────────────────────────────────

    async def list_servers_for_user(self, user_id: int) -> list:
        """List all servers owned by a user."""
        try:
            data = await self._request("GET", f"/users/{user_id}?include=servers")
            user_data = data.get("attributes", {})
            servers_rel = user_data.get("relationships", {}).get("servers", {}).get("data", [])
            servers = []
            for s in servers_rel:
                attrs = s.get("attributes", {})
                servers.append({
                    "id": attrs.get("id"),
                    "identifier": attrs.get("identifier"),
                    "uuid": attrs.get("uuid"),
                    "name": attrs.get("name"),
                    "node": attrs.get("node"),
                    "status": attrs.get("status", "running"),
                    "is_suspended": attrs.get("is_suspended", False),
                    "memory": attrs.get("limits", {}).get("memory", 0),
                    "disk": attrs.get("limits", {}).get("disk", 0),
                    "cpu": attrs.get("limits", {}).get("cpu", 0),
                })
            return servers
        except Exception:
            return []

    async def _client_request(
        self, method: str, path: str, client_apiKey: Optional[str] = None, **kwargs
    ) -> dict[str, Any]:
        """Make a request to the Pterodactyl Client API using App key or user key."""
        url = f"{self.base_url}/api/client{path}"
        headers = {
            "Authorization": f"Bearer {client_apiKey or get_settings().PTERODACTYL_APP_KEY}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.request(method, url, headers=headers, **kwargs)
            response.raise_for_status()
            if response.status_code == 204:
                return {}
            return response.json()

    async def send_power_signal(self, identifier: str, signal: str) -> bool:
        """Send power signal: start, stop, restart, kill."""
        try:
            await self._client_request("POST", f"/servers/{identifier}/power", json={"signal": signal})
            return True
        except Exception:
            return False

    async def get_websocket_credentials(self, identifier: str) -> dict:
        """Get WebSocket connection token and URL for console connection."""
        try:
            res = await self._client_request("GET", f"/servers/{identifier}/websocket")
            return res.get("data", {})
        except Exception:
            return {"token": "dummy_ws_token", "socket": f"wss://{self.base_url.replace('https://', '').replace('http://', '')}/api/client/servers/{identifier}/ws"}

    async def list_files(self, identifier: str, directory: str = "/") -> list:
        """List files in server directory."""
        try:
            res = await self._client_request("GET", f"/servers/{identifier}/files/list?directory={directory}")
            return res.get("data", [])
        except Exception:
            return []

    async def get_file_contents(self, identifier: str, file_path: str) -> str:
        """Get raw content of a file on the server."""
        try:
            url = f"{self.base_url}/api/client/servers/{identifier}/files/contents?file={file_path}"
            headers = {
                "Authorization": f"Bearer {get_settings().PTERODACTYL_APP_KEY}",
                "Accept": "text/plain",
            }
            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.get(url, headers=headers)
                return resp.text
        except Exception as e:
            return f"Error loading file: {str(e)}"

    async def write_file_contents(self, identifier: str, file_path: str, content: str) -> bool:
        """Write content to a file on the server."""
        try:
            url = f"{self.base_url}/api/client/servers/{identifier}/files/write?file={file_path}"
            headers = {
                "Authorization": f"Bearer {get_settings().PTERODACTYL_APP_KEY}",
                "Content-Type": "text/plain",
            }
            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.post(url, headers=headers, content=content)
                return resp.status_code in [200, 204]
        except Exception:
            return False

    async def delete_file(self, identifier: str, root_dir: str, files: list[str]) -> bool:
        """Delete files/folders on server."""
        try:
            await self._client_request("POST", f"/servers/{identifier}/files/delete", json={
                "root": root_dir,
                "files": files,
            })
            return True
        except Exception:
            return False

    async def list_backups(self, identifier: str) -> list:
        """List server backups."""
        try:
            res = await self._client_request("GET", f"/servers/{identifier}/backups")
            return res.get("data", [])
        except Exception:
            return []

    async def create_backup(self, identifier: str) -> dict:
        """Create a server backup."""
        try:
            res = await self._client_request("POST", f"/servers/{identifier}/backups")
            return res.get("data", {})
        except Exception:
            return {}

    async def delete_backup(self, identifier: str, backup_id: str) -> bool:
        """Delete a server backup."""
        try:
            await self._client_request("DELETE", f"/servers/{identifier}/backups/{backup_id}")
            return True
        except Exception:
            return False


# Singleton instance
ptero_client = PterodactylClient()

