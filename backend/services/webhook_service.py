"""
Webhook Notification Service for alerting admins about support chat events.

Supports:
- Slack webhooks with Block Kit formatting
- Discord webhooks with embeds (optional)

Usage:
    from services.webhook_service import get_webhook_service

    webhook_service = get_webhook_service()
    await webhook_service.notify_new_live_chat(
        user_name="John",
        message_preview="I need help with...",
        ticket_id="ticket-123",
        category="technical"
    )
"""

import os
import asyncio
from datetime import datetime
from typing import Optional, Dict, Any, List
from enum import Enum

import httpx

from core.logger import get_logger
from core.config import get_settings

logger = get_logger(__name__)


class WebhookPriority(str, Enum):
    """Priority levels for support tickets."""
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"


class WebhookService:
    """
    Service for sending webhook notifications to Slack and Discord.

    Notifies admins about:
    - New live chat sessions
    - New messages in existing chats
    - Chat session endings
    """

    # Retry configuration
    MAX_RETRIES = 3
    RETRY_DELAY_SECONDS = 1
    REQUEST_TIMEOUT_SECONDS = 10

    # Priority colors for Slack
    PRIORITY_COLORS = {
        WebhookPriority.LOW: "#36a64f",      # Green
        WebhookPriority.NORMAL: "#2196F3",   # Blue
        WebhookPriority.HIGH: "#FF9800",     # Orange
        WebhookPriority.URGENT: "#F44336",   # Red
    }

    # Priority colors for Discord (decimal format)
    DISCORD_PRIORITY_COLORS = {
        WebhookPriority.LOW: 3584095,        # Green
        WebhookPriority.NORMAL: 2201331,     # Blue
        WebhookPriority.HIGH: 16750848,      # Orange
        WebhookPriority.URGENT: 15684408,    # Red
    }

    def __init__(self):
        """Initialize the webhook service with configuration from settings."""
        settings = get_settings()

        # Primary: use settings from config, fallback to direct env vars
        self.slack_webhook_url = (
            settings.slack_support_webhook
            or os.getenv("SLACK_SUPPORT_WEBHOOK")
        )
        self.discord_webhook_url = (
            settings.discord_support_webhook
            or os.getenv("DISCORD_SUPPORT_WEBHOOK")
        )
        self.admin_dashboard_url = settings.admin_dashboard_url

        # Log configuration status
        if self.slack_webhook_url:
            logger.info("✅ Slack webhook configured for support notifications")
        else:
            logger.warning("⚠️ SLACK_SUPPORT_WEBHOOK not configured")

        if self.discord_webhook_url:
            logger.info("✅ Discord webhook configured for support notifications")

    def is_configured(self) -> bool:
        """Check if at least one webhook is configured."""
        return bool(self.slack_webhook_url or self.discord_webhook_url)

    def _truncate_message(self, message: str, max_length: int = 100) -> str:
        """Truncate message to max_length characters with ellipsis."""
        if len(message) <= max_length:
            return message
        return message[:max_length - 3] + "..."

    def _get_ticket_url(self, ticket_id: str) -> str:
        """Generate the admin dashboard URL for a ticket."""
        return f"{self.admin_dashboard_url}/support/tickets/{ticket_id}"

    def _get_priority_from_category(self, category: str) -> WebhookPriority:
        """
        Determine priority based on category.

        Categories like 'billing', 'account_access' are higher priority.
        """
        high_priority_categories = {"billing", "account_access", "payment", "subscription"}
        urgent_categories = {"security", "data_breach", "urgent"}

        category_lower = category.lower() if category else ""

        if category_lower in urgent_categories:
            return WebhookPriority.URGENT
        elif category_lower in high_priority_categories:
            return WebhookPriority.HIGH
        elif category_lower in {"bug", "technical", "feature_request"}:
            return WebhookPriority.NORMAL
        else:
            return WebhookPriority.LOW

    async def _send_with_retry(
        self,
        url: str,
        payload: Dict[str, Any],
        platform: str = "webhook"
    ) -> bool:
        """
        Send HTTP POST request with retry logic.

        Args:
            url: Webhook URL
            payload: JSON payload to send
            platform: Platform name for logging (slack/discord)

        Returns:
            True if sent successfully, False otherwise
        """
        for attempt in range(1, self.MAX_RETRIES + 1):
            try:
                async with httpx.AsyncClient(timeout=self.REQUEST_TIMEOUT_SECONDS) as client:
                    response = await client.post(
                        url,
                        json=payload,
                        headers={"Content-Type": "application/json"}
                    )

                    if response.status_code in (200, 204):
                        logger.info(
                            f"✅ [{platform}] Webhook notification sent successfully",
                            extra={"attempt": attempt}
                        )
                        return True

                    # Rate limiting
                    if response.status_code == 429:
                        retry_after = int(response.headers.get("Retry-After", 5))
                        logger.warning(
                            f"⚠️ [{platform}] Rate limited, retrying after {retry_after}s",
                            extra={"attempt": attempt}
                        )
                        await asyncio.sleep(retry_after)
                        continue

                    logger.warning(
                        f"⚠️ [{platform}] Webhook returned status {response.status_code}",
                        extra={"attempt": attempt, "response": response.text[:200]}
                    )

            except httpx.TimeoutException:
                logger.warning(
                    f"⚠️ [{platform}] Webhook timeout",
                    extra={"attempt": attempt}
                )
            except httpx.RequestError as e:
                logger.warning(
                    f"⚠️ [{platform}] Webhook request error: {e}",
                    extra={"attempt": attempt}
                )
            except Exception as e:
                logger.error(
                    f"❌ [{platform}] Unexpected error sending webhook: {e}",
                    extra={"attempt": attempt}
                )

            # Wait before retry (exponential backoff)
            if attempt < self.MAX_RETRIES:
                await asyncio.sleep(self.RETRY_DELAY_SECONDS * attempt)

        logger.error(f"❌ [{platform}] Failed to send webhook after {self.MAX_RETRIES} attempts")
        return False

    # ─────────────────────────────────────────────────────────────────
    # Slack Webhook Methods
    # ─────────────────────────────────────────────────────────────────

    def _build_slack_blocks_new_chat(
        self,
        user_name: str,
        message_preview: str,
        ticket_id: str,
        category: str,
        priority: WebhookPriority,
        user_email: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """Build Slack Block Kit blocks for new live chat notification."""
        ticket_url = self._get_ticket_url(ticket_id)
        truncated_message = self._truncate_message(message_preview)
        timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "New Live Chat Request",
                    "emoji": True
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*User:*\n{user_name}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Category:*\n{category.replace('_', ' ').title()}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Priority:*\n:{self._get_priority_emoji(priority)}: {priority.value.upper()}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Ticket ID:*\n`{ticket_id}`"
                    }
                ]
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Message Preview:*\n>{truncated_message}"
                }
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": f"Received at {timestamp}"
                    }
                ]
            },
            {
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {
                            "type": "plain_text",
                            "text": "Reply in Dashboard",
                            "emoji": True
                        },
                        "url": ticket_url,
                        "style": "primary"
                    }
                ]
            },
            {
                "type": "divider"
            }
        ]

        # Add email if available
        if user_email:
            blocks[1]["fields"].append({
                "type": "mrkdwn",
                "text": f"*Email:*\n{user_email}"
            })

        return blocks

    def _build_slack_blocks_new_message(
        self,
        user_name: str,
        message_preview: str,
        ticket_id: str,
    ) -> List[Dict[str, Any]]:
        """Build Slack Block Kit blocks for new message in existing chat."""
        ticket_url = self._get_ticket_url(ticket_id)
        truncated_message = self._truncate_message(message_preview)
        timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

        return [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*New message from {user_name}* in ticket `{ticket_id}`"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f">{truncated_message}"
                }
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": f"Received at {timestamp}"
                    }
                ]
            },
            {
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {
                            "type": "plain_text",
                            "text": "View Conversation",
                            "emoji": True
                        },
                        "url": ticket_url
                    }
                ]
            }
        ]

    def _build_slack_blocks_chat_ended(
        self,
        user_name: str,
        ticket_id: str,
        resolution: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """Build Slack Block Kit blocks for chat ended notification."""
        ticket_url = self._get_ticket_url(ticket_id)
        timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f":white_check_mark: *Chat ended* - {user_name} (Ticket `{ticket_id}`)"
                }
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": f"Closed at {timestamp}"
                    }
                ]
            }
        ]

        if resolution:
            blocks.insert(1, {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Resolution:* {resolution}"
                }
            })

        blocks.append({
            "type": "actions",
            "elements": [
                {
                    "type": "button",
                    "text": {
                        "type": "plain_text",
                        "text": "View Summary",
                        "emoji": True
                    },
                    "url": ticket_url
                }
            ]
        })

        return blocks

    def _get_priority_emoji(self, priority: WebhookPriority) -> str:
        """Get Slack emoji name for priority level."""
        emoji_map = {
            WebhookPriority.LOW: "large_green_circle",
            WebhookPriority.NORMAL: "large_blue_circle",
            WebhookPriority.HIGH: "warning",
            WebhookPriority.URGENT: "rotating_light",
        }
        return emoji_map.get(priority, "white_circle")

    async def _send_slack_notification(
        self,
        blocks: List[Dict[str, Any]],
        text: str,
        priority: WebhookPriority = WebhookPriority.NORMAL,
    ) -> bool:
        """
        Send a notification to Slack.

        Args:
            blocks: Slack Block Kit blocks
            text: Fallback text for notifications
            priority: Priority level for color coding

        Returns:
            True if sent successfully, False otherwise
        """
        if not self.slack_webhook_url:
            logger.debug("Slack webhook not configured, skipping")
            return False

        payload = {
            "text": text,
            "blocks": blocks,
            "attachments": [
                {
                    "color": self.PRIORITY_COLORS.get(priority, "#2196F3"),
                    "blocks": []
                }
            ]
        }

        return await self._send_with_retry(
            self.slack_webhook_url,
            payload,
            platform="slack"
        )

    # ─────────────────────────────────────────────────────────────────
    # Discord Webhook Methods
    # ─────────────────────────────────────────────────────────────────

    def _build_discord_embed_new_chat(
        self,
        user_name: str,
        message_preview: str,
        ticket_id: str,
        category: str,
        priority: WebhookPriority,
        user_email: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Build Discord embed for new live chat notification."""
        ticket_url = self._get_ticket_url(ticket_id)
        truncated_message = self._truncate_message(message_preview)

        embed = {
            "title": "New Live Chat Request",
            "color": self.DISCORD_PRIORITY_COLORS.get(priority, 2201331),
            "fields": [
                {
                    "name": "User",
                    "value": user_name,
                    "inline": True
                },
                {
                    "name": "Category",
                    "value": category.replace("_", " ").title(),
                    "inline": True
                },
                {
                    "name": "Priority",
                    "value": priority.value.upper(),
                    "inline": True
                },
                {
                    "name": "Ticket ID",
                    "value": f"`{ticket_id}`",
                    "inline": True
                },
                {
                    "name": "Message Preview",
                    "value": truncated_message,
                    "inline": False
                }
            ],
            "timestamp": datetime.utcnow().isoformat(),
            "footer": {
                "text": "FitWiz Support"
            },
            "url": ticket_url
        }

        if user_email:
            embed["fields"].insert(1, {
                "name": "Email",
                "value": user_email,
                "inline": True
            })

        return embed

    def _build_discord_embed_new_message(
        self,
        user_name: str,
        message_preview: str,
        ticket_id: str,
    ) -> Dict[str, Any]:
        """Build Discord embed for new message in existing chat."""
        ticket_url = self._get_ticket_url(ticket_id)
        truncated_message = self._truncate_message(message_preview)

        return {
            "title": f"New message from {user_name}",
            "description": truncated_message,
            "color": 2201331,  # Blue
            "fields": [
                {
                    "name": "Ticket ID",
                    "value": f"`{ticket_id}`",
                    "inline": True
                }
            ],
            "timestamp": datetime.utcnow().isoformat(),
            "footer": {
                "text": "FitWiz Support"
            },
            "url": ticket_url
        }

    def _build_discord_embed_chat_ended(
        self,
        user_name: str,
        ticket_id: str,
        resolution: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Build Discord embed for chat ended notification."""
        ticket_url = self._get_ticket_url(ticket_id)

        embed = {
            "title": "Chat Ended",
            "description": f"{user_name} has ended the chat session.",
            "color": 3584095,  # Green
            "fields": [
                {
                    "name": "Ticket ID",
                    "value": f"`{ticket_id}`",
                    "inline": True
                }
            ],
            "timestamp": datetime.utcnow().isoformat(),
            "footer": {
                "text": "FitWiz Support"
            },
            "url": ticket_url
        }

        if resolution:
            embed["fields"].append({
                "name": "Resolution",
                "value": resolution,
                "inline": False
            })

        return embed

    async def _send_discord_notification(
        self,
        embed: Dict[str, Any],
        content: Optional[str] = None,
    ) -> bool:
        """
        Send a notification to Discord.

        Args:
            embed: Discord embed object
            content: Optional text content

        Returns:
            True if sent successfully, False otherwise
        """
        if not self.discord_webhook_url:
            logger.debug("Discord webhook not configured, skipping")
            return False

        payload = {
            "embeds": [embed],
            "username": "FitWiz Support"
        }

        if content:
            payload["content"] = content

        return await self._send_with_retry(
            self.discord_webhook_url,
            payload,
            platform="discord"
        )

    # ─────────────────────────────────────────────────────────────────
    # Public API Methods
    # ─────────────────────────────────────────────────────────────────

    async def notify_new_live_chat(
        self,
        user_name: str,
        message_preview: str,
        ticket_id: str,
        category: str,
        user_email: Optional[str] = None,
        priority: Optional[WebhookPriority] = None,
    ) -> Dict[str, bool]:
        """
        Notify admins about a new live chat session.

        Args:
            user_name: Name of the user starting the chat
            message_preview: First 100 chars of the user's message
            ticket_id: Unique identifier for the support ticket
            category: Category of the support request
            user_email: Optional user email address
            priority: Optional priority override

        Returns:
            Dict with 'slack' and 'discord' keys indicating success
        """
        if not self.is_configured():
            logger.warning("⚠️ No webhooks configured, cannot send notification")
            return {"slack": False, "discord": False}

        # Determine priority from category if not specified
        if priority is None:
            priority = self._get_priority_from_category(category)

        logger.info(
            f"🔔 Notifying new live chat: user={user_name}, ticket={ticket_id}, "
            f"category={category}, priority={priority.value}"
        )

        results = {"slack": False, "discord": False}

        # Send to Slack
        if self.slack_webhook_url:
            try:
                blocks = self._build_slack_blocks_new_chat(
                    user_name=user_name,
                    message_preview=message_preview,
                    ticket_id=ticket_id,
                    category=category,
                    priority=priority,
                    user_email=user_email,
                )
                results["slack"] = await self._send_slack_notification(
                    blocks=blocks,
                    text=f"New live chat from {user_name}: {self._truncate_message(message_preview, 50)}",
                    priority=priority,
                )
            except Exception as e:
                logger.error(f"❌ Failed to send Slack notification: {e}")

        # Send to Discord
        if self.discord_webhook_url:
            try:
                embed = self._build_discord_embed_new_chat(
                    user_name=user_name,
                    message_preview=message_preview,
                    ticket_id=ticket_id,
                    category=category,
                    priority=priority,
                    user_email=user_email,
                )
                results["discord"] = await self._send_discord_notification(embed=embed)
            except Exception as e:
                logger.error(f"❌ Failed to send Discord notification: {e}")

        return results

    async def notify_new_message(
        self,
        user_name: str,
        message_preview: str,
        ticket_id: str,
    ) -> Dict[str, bool]:
        """
        Notify admins about a new message in an existing chat.

        Args:
            user_name: Name of the user sending the message
            message_preview: First 100 chars of the message
            ticket_id: Ticket identifier

        Returns:
            Dict with 'slack' and 'discord' keys indicating success
        """
        if not self.is_configured():
            logger.warning("⚠️ No webhooks configured, cannot send notification")
            return {"slack": False, "discord": False}

        logger.info(f"🔔 Notifying new message: user={user_name}, ticket={ticket_id}")

        results = {"slack": False, "discord": False}

        # Send to Slack
        if self.slack_webhook_url:
            try:
                blocks = self._build_slack_blocks_new_message(
                    user_name=user_name,
                    message_preview=message_preview,
                    ticket_id=ticket_id,
                )
                results["slack"] = await self._send_slack_notification(
                    blocks=blocks,
                    text=f"New message from {user_name} in ticket {ticket_id}",
                )
            except Exception as e:
                logger.error(f"❌ Failed to send Slack notification: {e}")

        # Send to Discord
        if self.discord_webhook_url:
            try:
                embed = self._build_discord_embed_new_message(
                    user_name=user_name,
                    message_preview=message_preview,
                    ticket_id=ticket_id,
                )
                results["discord"] = await self._send_discord_notification(embed=embed)
            except Exception as e:
                logger.error(f"❌ Failed to send Discord notification: {e}")

        return results

    async def notify_chat_ended(
        self,
        user_name: str,
        ticket_id: str,
        resolution: Optional[str] = None,
    ) -> Dict[str, bool]:
        """
        Notify admins when a user ends a chat session.

        Args:
            user_name: Name of the user who ended the chat
            ticket_id: Ticket identifier
            resolution: Optional resolution status/notes

        Returns:
            Dict with 'slack' and 'discord' keys indicating success
        """
        if not self.is_configured():
            logger.warning("⚠️ No webhooks configured, cannot send notification")
            return {"slack": False, "discord": False}

        logger.info(f"🔔 Notifying chat ended: user={user_name}, ticket={ticket_id}")

        results = {"slack": False, "discord": False}

        # Send to Slack
        if self.slack_webhook_url:
            try:
                blocks = self._build_slack_blocks_chat_ended(
                    user_name=user_name,
                    ticket_id=ticket_id,
                    resolution=resolution,
                )
                results["slack"] = await self._send_slack_notification(
                    blocks=blocks,
                    text=f"Chat ended: {user_name} (Ticket {ticket_id})",
                    priority=WebhookPriority.LOW,
                )
            except Exception as e:
                logger.error(f"❌ Failed to send Slack notification: {e}")

        # Send to Discord
        if self.discord_webhook_url:
            try:
                embed = self._build_discord_embed_chat_ended(
                    user_name=user_name,
                    ticket_id=ticket_id,
                    resolution=resolution,
                )
                results["discord"] = await self._send_discord_notification(embed=embed)
            except Exception as e:
                logger.error(f"❌ Failed to send Discord notification: {e}")

        return results

    async def send_custom_notification(
        self,
        title: str,
        message: str,
        fields: Optional[Dict[str, str]] = None,
        priority: WebhookPriority = WebhookPriority.NORMAL,
        action_url: Optional[str] = None,
        action_text: str = "View Details",
    ) -> Dict[str, bool]:
        """
        Send a custom notification to all configured webhooks.

        Args:
            title: Notification title
            message: Notification message
            fields: Optional key-value pairs to display
            priority: Priority level
            action_url: Optional URL for action button
            action_text: Text for action button

        Returns:
            Dict with 'slack' and 'discord' keys indicating success
        """
        if not self.is_configured():
            return {"slack": False, "discord": False}

        results = {"slack": False, "discord": False}
        timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

        # Build and send Slack notification
        if self.slack_webhook_url:
            try:
                blocks = [
                    {
                        "type": "header",
                        "text": {"type": "plain_text", "text": title, "emoji": True}
                    },
                    {
                        "type": "section",
                        "text": {"type": "mrkdwn", "text": message}
                    }
                ]

                if fields:
                    field_blocks = [
                        {"type": "mrkdwn", "text": f"*{k}:*\n{v}"}
                        for k, v in fields.items()
                    ]
                    blocks.append({
                        "type": "section",
                        "fields": field_blocks[:10]  # Slack limit
                    })

                blocks.append({
                    "type": "context",
                    "elements": [{"type": "mrkdwn", "text": f"Sent at {timestamp}"}]
                })

                if action_url:
                    blocks.append({
                        "type": "actions",
                        "elements": [{
                            "type": "button",
                            "text": {"type": "plain_text", "text": action_text},
                            "url": action_url,
                            "style": "primary"
                        }]
                    })

                results["slack"] = await self._send_slack_notification(
                    blocks=blocks,
                    text=f"{title}: {message}",
                    priority=priority,
                )
            except Exception as e:
                logger.error(f"❌ Failed to send custom Slack notification: {e}")

        # Build and send Discord notification
        if self.discord_webhook_url:
            try:
                embed = {
                    "title": title,
                    "description": message,
                    "color": self.DISCORD_PRIORITY_COLORS.get(priority, 2201331),
                    "timestamp": datetime.utcnow().isoformat(),
                    "footer": {"text": "FitWiz Support"}
                }

                if fields:
                    embed["fields"] = [
                        {"name": k, "value": v, "inline": True}
                        for k, v in list(fields.items())[:25]  # Discord limit
                    ]

                if action_url:
                    embed["url"] = action_url

                results["discord"] = await self._send_discord_notification(embed=embed)
            except Exception as e:
                logger.error(f"❌ Failed to send custom Discord notification: {e}")

        return results


# Singleton instance
_webhook_service: Optional[WebhookService] = None


def get_webhook_service() -> WebhookService:
    """Get or create the webhook service singleton."""
    global _webhook_service
    if _webhook_service is None:
        _webhook_service = WebhookService()
    return _webhook_service
