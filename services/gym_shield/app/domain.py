"""Pure Gym Shield port of src/domain/gymShield.ts.

Do not use this module to make privacy decisions on client-provided profiles.
The REST endpoint currently delegates authoritative discovery to the existing
server-side SQL RPC; repository migration requires dedicated integration tests.
"""
from dataclasses import dataclass, field

Mode = str
BUFFER_MINUTES = 30


@dataclass(frozen=True)
class WeeklySlot:
    day: int
    start_minutes: int
    end_minutes: int


@dataclass(frozen=True)
class Profile:
    id: str
    gym_id: str | None
    mode: Mode
    dating_enabled: bool
    weekly_slots: tuple[WeeklySlot, ...] = ()
    blocked_ids: frozenset[str] = field(default_factory=frozenset)


def valid_slot(slot: WeeklySlot) -> bool:
    return (type(slot.day) is int and 0 <= slot.day <= 6
            and type(slot.start_minutes) is int and type(slot.end_minutes) is int
            and 0 <= slot.start_minutes < slot.end_minutes <= 1440)


def schedules_separated(a: tuple[WeeklySlot, ...],
                        b: tuple[WeeklySlot, ...],
                        buffer: int = BUFFER_MINUTES) -> bool:
    if not a or not b or type(buffer) is not int or buffer < 0:
        return False
    if not all(map(valid_slot, a + b)):
        return False
    for first in a:
        for second in b:
            if first.day != second.day:
                continue
            gap = max(second.start_minutes - first.end_minutes,
                      first.start_minutes - second.end_minutes)
            if gap < buffer:
                return False
    return True


def eligible(viewer: Profile, candidate: Profile) -> bool:
    if not viewer.dating_enabled or not candidate.dating_enabled:
        return False
    if not viewer.id or not candidate.id or viewer.id == candidate.id:
        return False
    if candidate.id in viewer.blocked_ids or viewer.id in candidate.blocked_ids:
        return False
    if not viewer.gym_id or not candidate.gym_id:
        return False
    if viewer.gym_id != candidate.gym_id:
        return True
    return (viewer.mode == candidate.mode == "same_gym_other_time"
            and schedules_separated(viewer.weekly_slots, candidate.weekly_slots))
