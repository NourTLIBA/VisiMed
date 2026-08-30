"""Cluster existing free-text visits into Doctor / Pharmacy rows and link them.

Idempotent: re-running only fills gaps. Safe to run in a release phase.

    python manage.py backfill_targets
"""
from django.core.management.base import BaseCommand
from django.db import transaction

from visimed.models import (
    Doctor,
    Pharmacy,
    VisitRecord,
    VisitType,
    normalize_name,
)


class Command(BaseCommand):
    help = "Create Doctor/Pharmacy records from historical VisitRecord rows."

    @transaction.atomic
    def handle(self, *args, **options):
        linked_doctors = 0
        linked_pharmacies = 0

        for visit in VisitRecord.objects.filter(
            visit_type=VisitType.MEDICAL, doctor__isnull=True
        ).iterator():
            key = normalize_name(visit.target_name)
            if not key:
                continue
            doctor, _ = Doctor.objects.get_or_create(
                normalized_name=key,
                wilaya=visit.wilaya or "",
                defaults=dict(
                    name=visit.target_name,
                    gender=visit.gender or "",
                    specialty=visit.specialty or "",
                    structure_type=visit.structure_type or "",
                    potential=visit.potential,
                    gco_status=visit.gco_status,
                    address=visit.address or "",
                    commune=visit.commune or "",
                    telephone=visit.telephone or "",
                    email=visit.email or "",
                    owner=visit.rep,
                ),
            )
            visit.doctor = doctor
            visit.save(update_fields=["doctor"])
            linked_doctors += 1

        for visit in VisitRecord.objects.filter(
            visit_type=VisitType.PHARMACEUTICAL, pharmacy__isnull=True
        ).iterator():
            key = normalize_name(visit.target_name)
            if not key:
                continue
            pharmacy, _ = Pharmacy.objects.get_or_create(
                normalized_name=key,
                wilaya=visit.wilaya or "",
                defaults=dict(
                    name=visit.target_name,
                    structure_type=visit.structure_type or "",
                    potential=visit.potential,
                    address=visit.address or "",
                    commune=visit.commune or "",
                    telephone=visit.telephone or "",
                    email=visit.email or "",
                    owner=visit.rep,
                ),
            )
            visit.pharmacy = pharmacy
            visit.save(update_fields=["pharmacy"])
            linked_pharmacies += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Linked {linked_doctors} medical visits to "
                f"{Doctor.objects.count()} doctors and "
                f"{linked_pharmacies} pharma visits to "
                f"{Pharmacy.objects.count()} pharmacies."
            )
        )
