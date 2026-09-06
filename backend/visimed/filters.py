"""Shared query-param filtering for visit querysets.

Used by the visit list endpoint and the analytics / dashboard endpoints so a
filter the client picks once applies everywhere consistently.

Recognised params (all optional):
  date_from, date_to : ISO dates (YYYY-MM-DD), inclusive
  wilaya             : one name, or a comma-separated list
  visit_type         : "medical" | "pharmaceutical"
  potential          : "KOL"/"A"/"B"/"C", or a comma-separated list
  q                  : case-insensitive substring of target_name
  doctor, pharmacy   : id
"""
from __future__ import annotations

import datetime

from django.utils.dateparse import parse_date

from .models import TargetPotential, VisitType


def _csv(value: str) -> list[str]:
    return [p.strip() for p in value.split(",") if p.strip()]


def parse_range(params, *, default_days: int | None = None):
    """Return (date_from, date_to) as dates. Falls back to the last
    ``default_days`` when nothing is supplied (and default_days is given)."""
    today = datetime.date.today()
    date_to = parse_date(params.get("date_to") or "") or today
    date_from = parse_date(params.get("date_from") or "")
    if date_from is None and default_days is not None:
        date_from = date_to - datetime.timedelta(days=default_days)
    return date_from, date_to


def apply_visit_filters(qs, params):
    """Apply the recognised params to a VisitRecord queryset."""
    date_from, date_to = parse_range(params)
    if date_from:
        qs = qs.filter(date__gte=date_from)
    if params.get("date_to"):
        qs = qs.filter(date__lte=date_to)

    wilayas = _csv(params.get("wilaya", ""))
    if len(wilayas) == 1:
        qs = qs.filter(wilaya__iexact=wilayas[0])
    elif wilayas:
        qs = qs.filter(wilaya__in=wilayas)

    vt = params.get("visit_type")
    if vt in (VisitType.MEDICAL, VisitType.PHARMACEUTICAL):
        qs = qs.filter(visit_type=vt)

    potentials = [p for p in _csv(params.get("potential", "")) if p in TargetPotential.values]
    if potentials:
        qs = qs.filter(potential__in=potentials)

    q = (params.get("q") or "").strip()
    if q:
        qs = qs.filter(target_name__icontains=q)

    if params.get("doctor"):
        qs = qs.filter(doctor_id=params["doctor"])
    if params.get("pharmacy"):
        qs = qs.filter(pharmacy_id=params["pharmacy"])

    return qs
