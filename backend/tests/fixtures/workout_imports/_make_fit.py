"""Generate a minimal Garmin FIT fixture with one cardio session and one
strength session. Uses `fit-tool` (a writer library) since `fitparse` is
read-only. Run manually: `python _make_fit.py`.
"""
import os
from datetime import datetime, timezone

from fit_tool.fit_file_builder import FitFileBuilder
from fit_tool.profile.messages.file_id_message import FileIdMessage
from fit_tool.profile.messages.session_message import SessionMessage
from fit_tool.profile.messages.lap_message import LapMessage
from fit_tool.profile.messages.set_message import SetMessage
from fit_tool.profile.messages.activity_message import ActivityMessage
from fit_tool.profile.profile_type import (
    FileType, Sport, SubSport, Manufacturer, SetType, ExerciseCategory,
)


OUT_DIR = os.path.dirname(__file__)


def _fit_ms(ts: datetime) -> int:
    return int(ts.timestamp() * 1000)


def build_cardio():
    builder = FitFileBuilder(auto_define=True, min_string_size=50)

    start = datetime(2025, 3, 28, 17, 29, 0, tzinfo=timezone.utc)

    fid = FileIdMessage()
    fid.type = FileType.ACTIVITY
    fid.manufacturer = Manufacturer.GARMIN.value
    fid.product = 2172        # Forerunner 255 product ID
    fid.time_created = _fit_ms(start)
    fid.serial_number = 1234567890
    builder.add(fid)

    lap = LapMessage()
    lap.timestamp = _fit_ms(start)
    lap.start_time = _fit_ms(start)
    lap.total_elapsed_time = 1800
    lap.total_timer_time = 1800
    lap.total_distance = 5200.0
    lap.avg_heart_rate = 148
    lap.max_heart_rate = 172
    builder.add(lap)

    session = SessionMessage()
    session.timestamp = _fit_ms(start)
    session.start_time = _fit_ms(start)
    session.sport = Sport.RUNNING
    session.sub_sport = SubSport.GENERIC
    session.total_elapsed_time = 1800
    session.total_timer_time = 1800
    session.total_distance = 5200.0
    session.total_ascent = 42
    session.avg_heart_rate = 148
    session.max_heart_rate = 172
    session.total_calories = 480
    builder.add(session)

    act = ActivityMessage()
    act.timestamp = _fit_ms(start)
    act.total_timer_time = 1800
    act.num_sessions = 1
    builder.add(act)

    out = os.path.join(OUT_DIR, "garmin_sample_run.fit")
    file = builder.build()
    file.to_file(out)
    print(f"Wrote {out}")


def build_strength():
    builder = FitFileBuilder(auto_define=True, min_string_size=50)
    start = datetime(2025, 3, 31, 18, 0, 0, tzinfo=timezone.utc)

    fid = FileIdMessage()
    fid.type = FileType.ACTIVITY
    fid.manufacturer = Manufacturer.GARMIN.value
    fid.product = 2172
    fid.time_created = _fit_ms(start)
    fid.serial_number = 1234567891
    builder.add(fid)

    # Two active sets (bench press)
    for i in range(2):
        set_msg = SetMessage()
        set_msg.timestamp = _fit_ms(start)
        set_msg.set_type = SetType.ACTIVE
        set_msg.repetitions = 8
        set_msg.weight = 60.0 + i * 2.5
        set_msg.category = [ExerciseCategory.BENCH_PRESS]
        builder.add(set_msg)

    session = SessionMessage()
    session.timestamp = _fit_ms(start)
    session.start_time = _fit_ms(start)
    session.sport = Sport.TRAINING
    session.sub_sport = SubSport.STRENGTH_TRAINING
    session.total_elapsed_time = 3300
    session.total_timer_time = 3300
    session.total_calories = 280
    builder.add(session)

    act = ActivityMessage()
    act.timestamp = _fit_ms(start)
    act.total_timer_time = 3300
    act.num_sessions = 1
    builder.add(act)

    out = os.path.join(OUT_DIR, "garmin_sample_strength.fit")
    file = builder.build()
    file.to_file(out)
    print(f"Wrote {out}")


if __name__ == "__main__":
    build_cardio()
    build_strength()
