"""
Email service using Resend for sending workout reminders and notifications.
"""

import os
import json
from datetime import datetime, date
from typing import Optional, List, Dict, Any
import resend

from core.logger import get_logger

logger = get_logger(__name__)


class EmailService:
    """Service for sending emails via Resend."""

    def __init__(self):
        """Initialize the Resend client with API key from environment."""
        self.api_key = os.getenv("RESEND_API_KEY")
        if not self.api_key:
            logger.warning("RESEND_API_KEY not found in environment variables")
        else:
            resend.api_key = self.api_key
            logger.info("✅ Email service initialized with Resend")

        # Default sender email (must be verified in Resend)
        self.from_email = os.getenv("RESEND_FROM_EMAIL", "FitWiz <onboarding@resend.dev>")

    def is_configured(self) -> bool:
        """Check if the email service is properly configured."""
        return bool(self.api_key)

    async def send_workout_reminder(
        self,
        to_email: str,
        user_name: str,
        workout_name: str,
        workout_type: str,
        scheduled_date: date,
        exercises: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Send a workout reminder email to a user.

        Args:
            to_email: User's email address
            user_name: User's display name
            workout_name: Name of the workout
            workout_type: Type of workout (e.g., "upper_body", "legs")
            scheduled_date: Date the workout is scheduled
            exercises: List of exercises in the workout

        Returns:
            Response from Resend API
        """
        if not self.is_configured():
            logger.error("❌ Cannot send email - Resend API key not configured")
            return {"error": "Email service not configured"}

        # Format the exercise list for the email
        exercise_list_html = ""
        for i, exercise in enumerate(exercises[:8], 1):  # Limit to first 8
            exercise_name = exercise.get("name", "Unknown Exercise")
            sets = exercise.get("sets", 3)
            reps = exercise.get("reps", 10)
            exercise_list_html += f"<li><strong>{exercise_name}</strong> - {sets} sets x {reps} reps</li>"

        if len(exercises) > 8:
            exercise_list_html += f"<li><em>...and {len(exercises) - 8} more exercises</em></li>"

        # Format the date nicely
        formatted_date = scheduled_date.strftime("%A, %B %d, %Y")

        # Build the HTML email
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                }}
                .header {{
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 30px;
                    border-radius: 12px 12px 0 0;
                    text-align: center;
                }}
                .header h1 {{
                    margin: 0;
                    font-size: 24px;
                }}
                .content {{
                    background: #f8f9fa;
                    padding: 30px;
                    border-radius: 0 0 12px 12px;
                }}
                .workout-card {{
                    background: white;
                    border-radius: 8px;
                    padding: 20px;
                    margin: 20px 0;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }}
                .workout-type {{
                    display: inline-block;
                    background: #667eea;
                    color: white;
                    padding: 4px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    text-transform: uppercase;
                }}
                .exercise-list {{
                    list-style: none;
                    padding: 0;
                }}
                .exercise-list li {{
                    padding: 10px 0;
                    border-bottom: 1px solid #eee;
                }}
                .exercise-list li:last-child {{
                    border-bottom: none;
                }}
                .cta-button {{
                    display: inline-block;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 14px 28px;
                    border-radius: 8px;
                    text-decoration: none;
                    font-weight: 600;
                    margin-top: 20px;
                }}
                .footer {{
                    text-align: center;
                    color: #666;
                    font-size: 12px;
                    margin-top: 30px;
                }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Time to Train!</h1>
            </div>
            <div class="content">
                <p>Hey {user_name or 'there'},</p>
                <p>You have a workout scheduled for <strong>{formatted_date}</strong>. Let's crush it!</p>

                <div class="workout-card">
                    <span class="workout-type">{workout_type.replace('_', ' ')}</span>
                    <h2 style="margin: 10px 0;">{workout_name}</h2>

                    <h3>Today's Exercises:</h3>
                    <ul class="exercise-list">
                        {exercise_list_html}
                    </ul>
                </div>

                <p style="text-align: center;">
                    <a href="#" class="cta-button">Open App & Start Workout</a>
                </p>

                <p style="color: #666; font-size: 14px;">
                    Remember: Consistency is key! Even a shorter workout is better than no workout.
                </p>
            </div>
            <div class="footer">
                <p>FitWiz - Your Personal Training Assistant</p>
                <p>You received this email because you have workout reminders enabled.</p>
            </div>
        </body>
        </html>
        """

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"Workout Reminder: {workout_name} - {formatted_date}",
                "html": html_content,
            }

            response = resend.Emails.send(params)
            logger.info(f"✅ Email sent successfully to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}

        except Exception as e:
            logger.error(f"❌ Failed to send email to {to_email}: {e}")
            return {"error": str(e)}

    async def send_weekly_summary(
        self,
        to_email: str,
        user_name: str,
        completed_workouts: int,
        total_workouts: int,
        total_volume_kg: float,
        top_exercises: List[str],
    ) -> Dict[str, Any]:
        """
        Send a weekly workout summary email.

        Args:
            to_email: User's email address
            user_name: User's display name
            completed_workouts: Number of workouts completed this week
            total_workouts: Total workouts scheduled this week
            total_volume_kg: Total weight lifted this week
            top_exercises: List of most performed exercises
        """
        if not self.is_configured():
            logger.error("❌ Cannot send email - Resend API key not configured")
            return {"error": "Email service not configured"}

        completion_rate = (completed_workouts / total_workouts * 100) if total_workouts > 0 else 0

        top_exercises_html = "".join([f"<li>{ex}</li>" for ex in top_exercises[:5]])

        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                }}
                .header {{
                    background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
                    color: white;
                    padding: 30px;
                    border-radius: 12px 12px 0 0;
                    text-align: center;
                }}
                .stats-grid {{
                    display: grid;
                    grid-template-columns: repeat(2, 1fr);
                    gap: 15px;
                    margin: 20px 0;
                }}
                .stat-card {{
                    background: white;
                    border-radius: 8px;
                    padding: 20px;
                    text-align: center;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }}
                .stat-value {{
                    font-size: 32px;
                    font-weight: bold;
                    color: #11998e;
                }}
                .stat-label {{
                    color: #666;
                    font-size: 14px;
                }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Your Weekly Summary</h1>
            </div>
            <div style="background: #f8f9fa; padding: 30px; border-radius: 0 0 12px 12px;">
                <p>Great work this week, {user_name or 'champ'}!</p>

                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-value">{completed_workouts}/{total_workouts}</div>
                        <div class="stat-label">Workouts Completed</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">{completion_rate:.0f}%</div>
                        <div class="stat-label">Completion Rate</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">{total_volume_kg:,.0f}</div>
                        <div class="stat-label">Total Volume (kg)</div>
                    </div>
                </div>

                <h3>Your Top Exercises:</h3>
                <ul>{top_exercises_html}</ul>

                <p>Keep up the momentum!</p>
            </div>
        </body>
        </html>
        """

        try:
            params = {
                "from": self.from_email,
                "to": [to_email],
                "subject": f"Your Weekly Fitness Summary - {completed_workouts}/{total_workouts} Workouts",
                "html": html_content,
            }

            response = resend.Emails.send(params)
            logger.info(f"✅ Weekly summary sent to {to_email}: {response}")
            return {"success": True, "id": response.get("id")}

        except Exception as e:
            logger.error(f"❌ Failed to send weekly summary to {to_email}: {e}")
            return {"error": str(e)}


# Singleton instance
_email_service: Optional[EmailService] = None


def get_email_service() -> EmailService:
    """Get or create the email service singleton."""
    global _email_service
    if _email_service is None:
        _email_service = EmailService()
    return _email_service
