"""
Trello integration for support ticket tracking.

Creates Trello cards when users submit support tickets, giving the dev team
a visual Kanban board to track and manage user issues.

Setup:
1. Get API key: https://trello.com/power-ups/admin
2. Get token: https://trello.com/1/authorize?expiration=never&scope=read,write&response_type=token&key=YOUR_KEY
3. Get board/list IDs: https://api.trello.com/1/boards/BOARD_ID/lists?key=KEY&token=TOKEN
4. Set env vars: TRELLO_API_KEY, TRELLO_TOKEN, TRELLO_LIST_ID
"""

import httpx
import logging
from typing import Optional, Dict, Any

from core.config import get_settings

logger = logging.getLogger(__name__)

# Trello API base URL
TRELLO_API = "https://api.trello.com/1"

# Map ticket priority to Trello label colors
PRIORITY_COLORS = {
    "urgent": "red",
    "high": "orange",
    "medium": "yellow",
    "low": "green",
}

# Map ticket category to emoji for quick visual scanning
CATEGORY_EMOJI = {
    "bug_report": "🐛",
    "feature_request": "✨",
    "technical": "🔧",
    "billing": "💳",
    "account": "👤",
    "other": "📋",
}


class TrelloService:
    """Lightweight Trello API client for support ticket cards."""

    def __init__(self):
        settings = get_settings()
        self.api_key = settings.trello_api_key
        self.token = settings.trello_token
        self.list_id = settings.trello_list_id
        self.enabled = bool(self.api_key and self.token and self.list_id)

        if not self.enabled:
            logger.info("Trello integration disabled (missing TRELLO_API_KEY, TRELLO_TOKEN, or TRELLO_LIST_ID)")

    @property
    def _auth_params(self) -> Dict[str, str]:
        return {"key": self.api_key, "token": self.token}

    async def create_card(
        self,
        ticket_id: str,
        subject: str,
        category: str,
        priority: str,
        message: str,
        user_email: Optional[str] = None,
        user_name: Optional[str] = None,
        username: Optional[str] = None,
        user_id: Optional[str] = None,
        device_info: Optional[Dict[str, Any]] = None,
        attachments: Optional[list] = None,
        steps_to_reproduce: Optional[str] = None,
        screen_context: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a Trello card for a new support ticket.

        Args:
            ticket_id: DB ticket ID
            subject: Ticket subject
            category: Ticket category (bug_report, feature_request, etc.)
            priority: Ticket priority (low, medium, high, urgent)
            message: Initial message from user
            user_email: User's email for context
            user_name: User's display name
            username: User's @username
            user_id: User's DB ID
            device_info: Device details (model, platform, os_version, screen size)
            attachments: List of S3 keys for screenshot attachments
            steps_to_reproduce: Steps to reproduce the issue
            screen_context: Which screen/feature the issue occurred on

        Returns:
            Trello card data dict, or None if disabled/failed
        """
        if not self.enabled:
            return None

        emoji = CATEGORY_EMOJI.get(category, "📋")
        card_name = f"{emoji} [{priority.upper()}] {subject}"

        # Build description with ticket context
        desc_parts = [
            f"**Ticket ID:** {ticket_id}",
            f"**Category:** {category.replace('_', ' ').title()}",
            f"**Priority:** {priority.upper()}",
        ]
        if screen_context:
            desc_parts.append(f"**Screen/Feature:** {screen_context}")
        if user_name:
            desc_parts.append(f"**Name:** {user_name}")
        if username:
            desc_parts.append(f"**Username:** @{username}")
        if user_email:
            desc_parts.append(f"**Email:** {user_email}")
        if user_id:
            desc_parts.append(f"**User ID:** {user_id}")

        # Device info section
        if device_info:
            desc_parts.append("\n**Device Info:**")
            if device_info.get("device_model"):
                desc_parts.append(f"- Model: {device_info['device_model']}")
            if device_info.get("device_platform"):
                desc_parts.append(f"- Platform: {device_info['device_platform']}")
            if device_info.get("os_version"):
                desc_parts.append(f"- OS: {device_info['os_version']}")
            if device_info.get("screen_width") and device_info.get("screen_height"):
                desc_parts.append(f"- Screen: {device_info['screen_width']}x{device_info['screen_height']}")

        desc_parts.append(f"\n---\n\n{message}")

        if steps_to_reproduce:
            desc_parts.append(f"\n---\n\n**Steps to Reproduce:**\n{steps_to_reproduce}")

        description = "\n".join(desc_parts)

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(
                    f"{TRELLO_API}/cards",
                    params={
                        **self._auth_params,
                        "idList": self.list_id,
                        "name": card_name,
                        "desc": description,
                        "pos": "top" if priority in ("urgent", "high") else "bottom",
                    },
                )
                response.raise_for_status()
                card = response.json()
                card_id = card.get("id")
                logger.info(f"Trello card created: {card.get('shortUrl')} for ticket {ticket_id}")

                # Attach screenshots to the Trello card
                if attachments and card_id:
                    await self._attach_screenshots(client, card_id, attachments)

                return card

        except Exception as e:
            logger.error(f"Failed to create Trello card for ticket {ticket_id}: {e}", exc_info=True)
            return None

    async def _attach_screenshots(
        self, client: httpx.AsyncClient, card_id: str, s3_keys: list
    ):
        """Attach screenshot images to a Trello card via presigned GET URLs."""
        try:
            from core.config import get_settings
            settings = get_settings()

            if not settings.s3_bucket_name:
                return

            import boto3
            s3_client = boto3.client(
                "s3",
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
                region_name=settings.aws_default_region,
            )

            for s3_key in s3_keys:
                try:
                    # Generate a presigned GET URL (valid for 7 days)
                    url = s3_client.generate_presigned_url(
                        "get_object",
                        Params={"Bucket": settings.s3_bucket_name, "Key": s3_key},
                        ExpiresIn=7 * 24 * 3600,
                    )
                    filename = s3_key.split("/")[-1]
                    await client.post(
                        f"{TRELLO_API}/cards/{card_id}/attachments",
                        params={**self._auth_params, "url": url, "name": filename},
                    )
                    logger.info(f"Attached {filename} to Trello card {card_id}")
                except Exception as e:
                    logger.warning(f"Failed to attach {s3_key} to Trello card {card_id}: {e}", exc_info=True)

        except Exception as e:
            logger.warning(f"Failed to attach screenshots to Trello card {card_id}: {e}", exc_info=True)

    async def add_comment(self, card_id: str, text: str) -> bool:
        """Add a comment to an existing Trello card (e.g., new reply on ticket)."""
        if not self.enabled or not card_id:
            return False

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    f"{TRELLO_API}/cards/{card_id}/actions/comments",
                    params={**self._auth_params, "text": text},
                )
                response.raise_for_status()
                return True
        except Exception as e:
            logger.error(f"Failed to add Trello comment to card {card_id}: {e}", exc_info=True)
            return False

    async def close_card(self, card_id: str) -> bool:
        """Archive a Trello card when ticket is closed."""
        if not self.enabled or not card_id:
            return False

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.put(
                    f"{TRELLO_API}/cards/{card_id}",
                    params={**self._auth_params, "closed": "true"},
                )
                response.raise_for_status()
                logger.info(f"Trello card archived: {card_id}")
                return True
        except Exception as e:
            logger.error(f"Failed to archive Trello card {card_id}: {e}", exc_info=True)
            return False


# Singleton
_trello_service: Optional[TrelloService] = None


def get_trello_service() -> TrelloService:
    global _trello_service
    if _trello_service is None:
        _trello_service = TrelloService()
    return _trello_service
