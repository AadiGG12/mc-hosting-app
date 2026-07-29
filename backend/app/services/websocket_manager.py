"""WebSocket connection manager for broadcasting real-time plan updates.

When an admin creates, updates, or deletes a hosting plan, this manager
broadcasts the change to all connected mobile app clients so their
plan catalog updates in real-time without requiring a manual refresh.
"""

import json
from fastapi import WebSocket
from typing import Any


class ConnectionManager:
    """Manages WebSocket connections and broadcasts messages to all clients."""

    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        """Accept a new WebSocket connection and add it to the pool."""
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        """Remove a WebSocket connection from the pool."""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict[str, Any]):
        """Send a JSON message to every connected WebSocket client.

        If a client is disconnected, it is removed from the pool silently.
        """
        stale = []
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                stale.append(connection)
        for conn in stale:
            self.active_connections.remove(conn)

    @property
    def client_count(self) -> int:
        """Number of currently connected clients."""
        return len(self.active_connections)


# Singleton instance — shared across all route handlers
plan_ws_manager = ConnectionManager()
