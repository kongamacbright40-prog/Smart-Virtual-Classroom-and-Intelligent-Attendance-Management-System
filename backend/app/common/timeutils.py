from datetime import datetime, timedelta, timezone
from typing import Annotated, Optional

from pydantic import PlainSerializer


def utcnow() -> datetime:
    """Current time as naive UTC, the format the database stores.

    Replaces the deprecated ``datetime.utcnow()`` with identical values.
    """
    return datetime.now(timezone.utc).replace(tzinfo=None)


def to_naive_utc(value: Optional[datetime]) -> Optional[datetime]:
    """The database stores naive UTC timestamps (see ``utcnow``)."""
    if value is None or value.tzinfo is None:
        return value
    return value.astimezone(timezone.utc).replace(tzinfo=None)


def campus_time_label(value: datetime) -> str:
    """A naive UTC time written in campus time for people, e.g.
    ``Sat 07 Nov 2026 at 10:00 (UTC+01:00)``."""
    from app.config import settings

    offset = settings.campus_utc_offset_minutes
    local = value + timedelta(minutes=offset)
    sign = "+" if offset >= 0 else "-"
    zone = f"UTC{sign}{abs(offset) // 60:02d}:{abs(offset) % 60:02d}"
    return f"{local:%a %d %b %Y at %H:%M} ({zone})"


def _serialize(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


# Naive UTC datetimes serialized with an explicit "Z" so clients don't read
# them as local time.
UTCDateTime = Annotated[datetime, PlainSerializer(_serialize, return_type=str)]
