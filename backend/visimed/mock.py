"""DEMO_MOCK — deterministic gap-filling for showcase deployments.

When ``settings.DEMO_MOCK`` is on, the analytics endpoints fill *empty* fields
(a rep with no ``Objective`` row, zero orders, a zero coverage denominator,
blank doctor/pharmacy contact info) with plausible values so the délégué
médical, délégué pharma and admin views aren't full of ``—`` / ``0``.

Every synthesised number is a pure function of stable keys (rep id, ISO
period, metric name), so the *same* metric comes out identical whether it is
computed on a delegate view or aggregated on the admin view — the three stay
coherent. Real data is never read-around and stored rows are never modified.
Off by default.
"""
from __future__ import annotations

import hashlib

from django.conf import settings

_SEED = "visimed-demo-v1"


def enabled() -> bool:
    return bool(getattr(settings, "DEMO_MOCK", False))


def _unit(*parts) -> float:
    """Stable value in [0, 1) derived from the given keys."""
    raw = _SEED + "|" + "|".join(str(p) for p in parts)
    digest = hashlib.sha256(raw.encode()).hexdigest()
    return int(digest[:12], 16) / float(0x1000000000000)


def _int(lo: int, hi: int, *parts) -> int:
    if hi <= lo:
        return lo
    return lo + int(_unit(*parts) * (hi - lo + 1))


# ── objectives ─────────────────────────────────────────────────────────────
def objective_target(rep_id: int, period_start, actual_visits: int) -> int:
    """Synthetic weekly visits target for a rep with no Objective row.
    Tracks the rep's own activity so attainment lands in a believable band."""
    base = max(6, actual_visits)
    factor = 0.9 + _unit("obj", rep_id, period_start) * 0.4  # 0.90–1.30
    return max(5, round(base * factor))


def full_objective(rep_id: int, period_start, actual_visits: int) -> dict:
    return {
        "visits_target": objective_target(rep_id, period_start, actual_visits),
        "new_doctors_target": _int(2, 5, "objnd", rep_id, period_start),
        "orders_target": _int(3, 8, "objo", rep_id, period_start),
        "coverage_target_pct": _int(55, 75, "objc", rep_id, period_start),
    }


# ── scalar / mapping gap-fillers ───────────────────────────────────────────
def count(real: int, *parts, lo: int = 3, hi: int = 18) -> int:
    """Return ``real`` unless it is falsy and DEMO_MOCK is on."""
    if real or not enabled():
        return real
    return _int(lo, hi, *parts)


_MATERIAL_RANGES = {
    "vials": (40, 160),
    "meters": (20, 90),
    "reader": (10, 45),
    "readers": (10, 45),
    "brochure_m": (30, 110),
    "brochure_patient": (60, 200),
    "affiche": (10, 40),
}


def material_breakdown(real: dict, *parts) -> dict:
    if any(real.values()) or not enabled():
        return real
    out = {}
    for key in real:
        lo, hi = _MATERIAL_RANGES.get(key, (10, 60))
        out[key] = _int(lo, hi, "mat", key, *parts)
    return out


def distribution(real: dict, total: int, weights: dict, *parts) -> dict:
    """Fill an empty ``{bucket: count}`` map so it sums to ``total``."""
    if any(real.values()) or not enabled() or total <= 0:
        return real
    keys = list(weights)
    wsum = sum(weights.values()) or 1
    out, running = {}, 0
    for i, k in enumerate(keys):
        if i == len(keys) - 1:
            out[k] = total - running
        else:
            out[k] = round(total * weights[k] / wsum)
            running += out[k]
    return out


def coverage(covered: int, total: int, *parts) -> tuple[int, int]:
    """(covered, total). The denominator, when synthesised, is derived from a
    scope-independent key so it is the same on every view; only the numerator
    varies with ``parts`` (the caller's scope)."""
    if not enabled():
        return covered, total
    if total == 0:
        total = _int(20, 40, "covtotal")
    if covered == 0 and total:
        covered = _int(1, max(1, total // 2), "covdone", *parts)
    return min(covered, total), total


# ── contact-field decoration (serialised output only) ──────────────────────
_SPECIALTIES = ["Généraliste", "Cardiologue", "Pédiatre", "Interniste", "Gynécologue"]


def decorate_contact(kind: str, data: dict) -> dict:
    """Fill blank telephone / email / address / specialty on a serialised
    doctor or pharmacy. Mutates and returns ``data``. No-op unless enabled."""
    if not enabled():
        return data
    name = data.get("name") or "contact"
    wilaya = data.get("wilaya") or "Alger"
    slug = "".join(c for c in name.lower() if c.isalnum() or c == " ").strip()
    slug = slug.replace(" ", ".")[:40] or "contact"
    if not data.get("telephone"):
        data["telephone"] = f"05{_int(10_000_000, 59_999_999, 'tel', name)}"
    if "email" in data and not data.get("email"):
        data["email"] = f"{slug}@{'clinic' if kind == 'doctor' else 'pharma'}.dz"
    if not data.get("address"):
        data["address"] = f"Rue {_int(1, 80, 'addr', name)}, {wilaya}"
    if kind == "doctor" and not data.get("specialty"):
        data["specialty"] = _SPECIALTIES[_int(0, len(_SPECIALTIES) - 1, "spec", name)]
    return data
