"""
Dynamic Duration Service
========================
Derives any arbitrary week count from anchor data stored in program_variant_weeks.

Anchor durations are the specific week counts stored in the database (e.g., 4w, 8w, 12w).
When a user requests a non-anchor duration (e.g., 5 weeks), this service:
1. Finds the smallest anchor >= desired_weeks
2. Takes the first N weeks from that anchor
3. Falls back to the largest anchor if desired_weeks exceeds all anchors

Usage:
    from backend.services.program_duration_service import ProgramDurationService
    service = ProgramDurationService(supabase_client)
    weeks = await service.get_program_for_duration("5x5 Linear Progression", 5, 3)
"""

import logging
from typing import Optional

logger = logging.getLogger(__name__)


class ProgramDurationService:
    """Derives arbitrary-length programs from anchor duration data."""

    def __init__(self, supabase_client):
        self.supabase = supabase_client

    async def get_available_anchors(
        self, program_name: str, sessions_per_week: int
    ) -> list[int]:
        """Get sorted list of anchor durations for a program+sessions combo."""
        result = (
            self.supabase.table("program_variants")
            .select("id, duration_weeks, variant_name")
            .eq("sessions_per_week", sessions_per_week)
            .order("duration_weeks")
            .execute()
        )

        anchors = []
        for variant in result.data:
            vname = variant.get("variant_name", "")
            if program_name.lower() in vname.lower():
                # Verify this variant has actual week data
                weeks_result = (
                    self.supabase.table("program_variant_weeks")
                    .select("week_number", count="exact")
                    .eq("variant_id", variant["id"])
                    .execute()
                )
                if weeks_result.data:
                    anchors.append(variant["duration_weeks"])

        return sorted(set(anchors))

    async def get_anchor_weeks(
        self, program_name: str, duration: int, sessions_per_week: int
    ) -> list[dict]:
        """Get all week data for a specific anchor duration."""
        # Find the variant
        variants_result = (
            self.supabase.table("program_variants")
            .select("id, variant_name, duration_weeks")
            .eq("duration_weeks", duration)
            .eq("sessions_per_week", sessions_per_week)
            .execute()
        )

        variant_id = None
        for v in variants_result.data:
            if program_name.lower() in v.get("variant_name", "").lower():
                variant_id = v["id"]
                break

        if not variant_id:
            logger.warning(
                f"No variant found for {program_name} {duration}w {sessions_per_week}/wk"
            )
            return []

        # Fetch weeks
        weeks_result = (
            self.supabase.table("program_variant_weeks")
            .select("*")
            .eq("variant_id", variant_id)
            .order("week_number")
            .execute()
        )

        return weeks_result.data or []

    async def get_program_for_duration(
        self,
        program_name: str,
        desired_weeks: int,
        sessions_per_week: int,
    ) -> list[dict]:
        """
        Derive a program of any duration from anchor data.

        Strategy:
        1. If desired_weeks matches an anchor, return it directly
        2. Find smallest anchor >= desired_weeks, take first N weeks
        3. If desired_weeks > all anchors, take the largest anchor
           and repeat weeks cyclically with progressive overload
        """
        anchors = await self.get_available_anchors(program_name, sessions_per_week)

        if not anchors:
            logger.warning(f"No anchors found for {program_name} {sessions_per_week}/wk")
            return []

        # Exact match
        if desired_weeks in anchors:
            return await self.get_anchor_weeks(
                program_name, desired_weeks, sessions_per_week
            )

        # Find smallest anchor >= desired_weeks
        ceiling = next((a for a in anchors if a >= desired_weeks), None)

        if ceiling:
            weeks = await self.get_anchor_weeks(
                program_name, ceiling, sessions_per_week
            )
            return weeks[:desired_weeks]

        # desired_weeks exceeds all anchors - use largest and extend
        largest = max(anchors)
        base_weeks = await self.get_anchor_weeks(
            program_name, largest, sessions_per_week
        )

        if not base_weeks:
            return []

        # Extend by cycling through the program
        extended = list(base_weeks)
        extra_needed = desired_weeks - len(base_weeks)

        for i in range(extra_needed):
            # Cycle through weeks, starting from the build phase (skip week 1)
            source_idx = (i % max(1, len(base_weeks) - 1)) + 1
            if source_idx >= len(base_weeks):
                source_idx = 0

            week_copy = dict(base_weeks[source_idx])
            week_copy["week_number"] = len(extended) + 1
            week_copy["phase"] = self._derive_phase(
                len(extended) + 1, desired_weeks
            )
            extended.append(week_copy)

        return extended[:desired_weeks]

    async def get_branded_program_variants(
        self, branded_program_id: str
    ) -> list[dict]:
        """Get all variants for a branded program."""
        result = (
            self.supabase.table("program_variants")
            .select("id, variant_name, duration_weeks, sessions_per_week, intensity_level")
            .eq("base_program_id", branded_program_id)
            .order("duration_weeks")
            .execute()
        )
        return result.data or []

    async def get_program_info(self, program_name: str) -> Optional[dict]:
        """Get branded program info by name."""
        result = (
            self.supabase.table("branded_programs")
            .select("*")
            .ilike("name", f"%{program_name}%")
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None

    def _derive_phase(self, week_num: int, total_weeks: int) -> str:
        """Determine training phase for extended weeks."""
        progress = week_num / total_weeks
        if progress <= 0.25:
            return "Foundation (Base Building)"
        elif progress <= 0.5:
            return "Build (Progressive Overload)"
        elif progress <= 0.75:
            return "Peak (Intensification)"
        elif progress <= 0.9:
            return "Taper (Deload)"
        else:
            return "Test/Maintenance"
