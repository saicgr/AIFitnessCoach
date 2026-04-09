"""
Push Notification Service using Firebase Admin SDK
Sends push notifications to users via Firebase Cloud Messaging (FCM)
"""

from .notification_service_helpers import (  # noqa: F401
    NotificationService,
    get_notification_service,
)

import os
import json
import logging
import random
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime

logger = logging.getLogger(__name__)

# Global Firebase app instance
_firebase_app = None


def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    import firebase_admin
    from firebase_admin import credentials

    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    try:
        # Check for credentials file path
        cred_path = os.environ.get('FIREBASE_CREDENTIALS_PATH')

        if cred_path and os.path.exists(cred_path):
            # Use credentials file
            cred = credentials.Certificate(cred_path)
            _firebase_app = firebase_admin.initialize_app(cred)
            logger.info("✅ Firebase initialized with credentials file")
        else:
            # Try to use credentials from environment variable (JSON string)
            cred_json = os.environ.get('FIREBASE_CREDENTIALS_JSON')
            if cred_json:
                cred_dict = json.loads(cred_json)
                cred = credentials.Certificate(cred_dict)
                _firebase_app = firebase_admin.initialize_app(cred)
                logger.info("✅ Firebase initialized with credentials from environment")
            else:
                # Use default credentials (for GCP environments)
                _firebase_app = firebase_admin.initialize_app()
                logger.info("✅ Firebase initialized with default credentials")

        return _firebase_app
    except Exception as e:
        logger.error(f"❌ Failed to initialize Firebase: {e}", exc_info=True)
        raise


