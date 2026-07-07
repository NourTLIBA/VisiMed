"""
Management command: seed_visits
Creates realistic demo visit records for all three demo users so
the export (CSV / XLSX / PDF) and admin KPI screens have data to show.

Usage:
    python manage.py seed_visits
    python manage.py seed_visits --clear   # wipe existing visits first
"""
import random
import uuid
from datetime import date, timedelta

from django.core.management.base import BaseCommand

from visimed.models import TargetPotential, User, VisitRecord, VisitType


class Command(BaseCommand):
    help = "Seed demo visit records for all representative accounts."

    MED_DOCTORS = [
        ("Dr. Karim Bensalem", "M", "Cardiologue", "Alger"),
        ("Dr. Nadia Ouali", "F", "Généraliste", "Alger"),
        ("Dr. Mohamed Cherif", "M", "Pédiatre", "Blida"),
        ("Dr. Samira Hadj", "F", "Généraliste", "Blida"),
        ("Dr. Youcef Amrani", "M", "Interniste", "Alger"),
        ("Dr. Fatima Meziani", "F", "Cardiologue", "Blida"),
        ("Dr. Rachid Khelil", "M", "Neurologue", "Alger"),
        ("Dr. Leila Bouzid", "F", "Gynécologue", "Blida"),
    ]

    PHARMA_TARGETS = [
        ("Pharmacie Centrale Oran", "Officine", "Oran"),
        ("Pharmacie El Watan", "Officine", "Oran"),
        ("Grossiste SantéPharma", "Grossiste", "Mostaganem"),
        ("CHU Oran Annexe", "CHU", "Oran"),
        ("Pharmacie Ibn Sina", "Officine", "Mostaganem"),
        ("Grossiste AlgériePharm", "Grossiste", "Oran"),
        ("Pharmacie de Garde Est", "Officine", "Mostaganem"),
        ("Pharmacie Beni M'hamed", "Officine", "Oran"),
    ]

    COMMUNES_BY_WILAYA = {
        "Alger": ["Alger Centre", "Bab El Oued", "Hussein Dey", "Bir Mourad Raïs"],
        "Blida": ["Blida", "Boufarik", "Larbaa", "Chiffa"],
        "Oran": ["Oran", "Es Sénia", "Bir El Djir", "Ain Turk"],
        "Mostaganem": ["Mostaganem", "Mazagran", "Khadra", "Sayada"],
    }

    STRUCTURES_MED = ["Cabinet Privé", "CHU", "Clinique"]

    def add_arguments(self, parser):
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Delete all existing visit records before seeding.",
        )

    def handle(self, *args, **options):
        if options["clear"]:
            deleted, _ = VisitRecord.objects.all().delete()
            self.stdout.write(self.style.WARNING(f"Deleted {deleted} existing visits."))

        created = 0

        try:
            medrep = User.objects.get(username="medrep1")
            created += self._seed_medical(medrep)
        except User.DoesNotExist:
            self.stdout.write(self.style.WARNING("medrep1 not found — skipping."))

        try:
            pharmarep = User.objects.get(username="pharmrep1")
            created += self._seed_pharma(pharmarep)
        except User.DoesNotExist:
            self.stdout.write(self.style.WARNING("pharmrep1 not found — skipping."))

        self.stdout.write(self.style.SUCCESS(f"OK  Created {created} demo visits."))

    # ── helpers ────────────────────────────────────────────────────────────

    def _rand_date(self, days_back=60):
        """Random date within the last `days_back` days."""
        return date.today() - timedelta(days=random.randint(0, days_back))

    def _seed_medical(self, rep):
        potentials = [TargetPotential.A, TargetPotential.B, TargetPotential.C]
        records = []
        for i in range(20):
            doctor, gender, specialty, wilaya = random.choice(self.MED_DOCTORS)
            commune = random.choice(self.COMMUNES_BY_WILAYA[wilaya])
            potential = random.choice(potentials)
            records.append(
                VisitRecord(
                    id=str(uuid.uuid4()),
                    date=self._rand_date(),
                    rep=rep,
                    visit_type=VisitType.MEDICAL,
                    target_name=doctor,
                    gender=gender,
                    specialty=specialty,
                    structure_type=random.choice(self.STRUCTURES_MED),
                    potential=potential,
                    address=f"Rue {random.randint(1, 50)} {commune}",
                    wilaya=wilaya,
                    commune=commune,
                    telephone=f"0{random.randint(500000000, 799999999)}",
                    email=f"{doctor.lower().replace(' ', '.').replace('dr.', '')}@clinic.dz",
                    patient_load=random.choice(["0-15", "16-30", "30+"]),
                    duration_minutes=random.choice([20, 30, 45, 60]),
                    qty_vials=random.randint(0, 10),
                    comment=random.choice(
                        [
                            "Intéressé par le nouveau protocole.",
                            "Demande documentation complémentaire.",
                            "Visite de suivi — bon accueil.",
                            "RDV confirmé pour le mois prochain.",
                            "",
                        ]
                    ),
                )
            )
        VisitRecord.objects.bulk_create(records, ignore_conflicts=True)
        return len(records)

    def _seed_pharma(self, rep):
        potentials = [TargetPotential.A, TargetPotential.B, TargetPotential.C]
        records = []
        for i in range(15):
            target, structure, wilaya = random.choice(self.PHARMA_TARGETS)
            commune = random.choice(self.COMMUNES_BY_WILAYA[wilaya])
            potential = random.choice(potentials)
            records.append(
                VisitRecord(
                    id=str(uuid.uuid4()),
                    date=self._rand_date(),
                    rep=rep,
                    visit_type=VisitType.PHARMACEUTICAL,
                    target_name=target,
                    specialty="N/A",
                    structure_type=structure,
                    potential=potential,
                    address=f"Avenue {random.randint(1, 20)} {commune}",
                    wilaya=wilaya,
                    commune=commune,
                    telephone=f"0{random.randint(500000000, 799999999)}",
                    email="",
                    patient_load="0-15",
                    duration_minutes=random.choice([15, 20, 30]),
                    qty_reader=random.randint(0, 5),
                    comment=random.choice(
                        [
                            "Stock vérifié — réapprovisionnement demandé.",
                            "Nouveau lecteur installé.",
                            "Pharmacien satisfait de la visite.",
                            "Commande en cours de traitement.",
                            "",
                        ]
                    ),
                )
            )
        VisitRecord.objects.bulk_create(records, ignore_conflicts=True)
        return len(records)
