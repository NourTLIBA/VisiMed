"""Management command: seed_visits

Creates realistic demo data (doctors, pharmacies, visits, presented products,
orders and current-week objectives) so the dashboards, doctor history and
alerts screens have something to show.

    python manage.py seed_visits
    python manage.py seed_visits --clear
"""
import random
import uuid
from datetime import date, timedelta

from django.core.management.base import BaseCommand

from visimed.models import (
    Doctor,
    Objective,
    Pharmacy,
    Prescription,
    PrescriptionStatus,
    Product,
    TargetPotential,
    User,
    VisitProduct,
    VisitRecord,
    VisitType,
    normalize_name,
)


class Command(BaseCommand):
    help = "Seed demo doctors, pharmacies, visits, orders and objectives."

    MED_DOCTORS = [
        ("Dr. Karim Bensalem", "M", "Cardiologue", "Alger", TargetPotential.KOL),
        ("Dr. Nadia Ouali", "F", "Généraliste", "Alger", TargetPotential.B),
        ("Dr. Mohamed Cherif", "M", "Pédiatre", "Blida", TargetPotential.A),
        ("Dr. Samira Hadj", "F", "Généraliste", "Blida", TargetPotential.C),
        ("Dr. Youcef Amrani", "M", "Interniste", "Alger", TargetPotential.A),
        ("Dr. Fatima Meziani", "F", "Cardiologue", "Blida", TargetPotential.KOL),
        ("Dr. Rachid Khelil", "M", "Neurologue", "Alger", TargetPotential.B),
        ("Dr. Leila Bouzid", "F", "Gynécologue", "Blida", TargetPotential.C),
    ]

    PHARMA_TARGETS = [
        ("Pharmacie Centrale Oran", "Officine", "Oran", TargetPotential.A),
        ("Pharmacie El Watan", "Officine", "Oran", TargetPotential.B),
        ("Grossiste SantéPharma", "Grossiste", "Mostaganem", TargetPotential.A),
        ("CHU Oran Annexe", "CHU", "Oran", TargetPotential.B),
        ("Pharmacie Ibn Sina", "Officine", "Mostaganem", TargetPotential.C),
        ("Grossiste AlgériePharm", "Grossiste", "Oran", TargetPotential.A),
        ("Pharmacie de Garde Est", "Officine", "Mostaganem", TargetPotential.C),
        ("Pharmacie Beni M'hamed", "Officine", "Oran", TargetPotential.B),
    ]

    COMMUNES_BY_WILAYA = {
        "Alger": ["Alger Centre", "Bab El Oued", "Hussein Dey", "Bir Mourad Raïs"],
        "Blida": ["Blida", "Boufarik", "Larbaa", "Chiffa"],
        "Oran": ["Oran", "Es Sénia", "Bir El Djir", "Ain Turk"],
        "Mostaganem": ["Mostaganem", "Mazagran", "Khadra", "Sayada"],
    }

    STRUCTURES_MED = ["Cabinet Privé", "CHU", "Clinique"]

    OBJECTIONS = [
        "", "", "Prix jugé élevé.", "Préfère la molécule concurrente.",
        "Manque de données locales.", "Pas de budget ce trimestre.",
    ]
    NEXT_ACTIONS = [
        "", "Rappeler avec une étude clinique.", "Programmer une réunion staff.",
        "Apporter des échantillons.", "Inviter au symposium régional.",
    ]

    def add_arguments(self, parser):
        parser.add_argument("--clear", action="store_true")

    def handle(self, *args, **options):
        if options["clear"]:
            Prescription.objects.all().delete()
            VisitProduct.objects.all().delete()
            VisitRecord.objects.all().delete()
            Doctor.objects.all().delete()
            Pharmacy.objects.all().delete()
            self.stdout.write(self.style.WARNING("Cleared visits / targets."))

        products = list(Product.objects.all())
        if not products:
            self.stdout.write(
                self.style.WARNING("No products — run `seed_products` first.")
            )

        created = 0
        try:
            medrep = User.objects.get(username="medrep1")
            created += self._seed_medical(medrep, products)
            self._seed_objective(medrep, target=15)
        except User.DoesNotExist:
            self.stdout.write(self.style.WARNING("medrep1 not found — skipping."))

        try:
            pharmarep = User.objects.get(username="pharmrep1")
            created += self._seed_pharma(pharmarep, products)
            self._seed_objective(pharmarep, target=12)
        except User.DoesNotExist:
            self.stdout.write(self.style.WARNING("pharmrep1 not found — skipping."))

        self.stdout.write(self.style.SUCCESS(f"OK  Created {created} demo visits."))

    # ── helpers ────────────────────────────────────────────────────────────
    def _rand_date(self, days_back=50):
        return date.today() - timedelta(days=random.randint(0, days_back))

    def _future_date(self, days_ahead=14):
        return date.today() + timedelta(days=random.randint(1, days_ahead))

    def _seed_objective(self, rep, target):
        monday = date.today() - timedelta(days=date.today().weekday())
        Objective.objects.get_or_create(
            rep=rep,
            period_type="weekly",
            period_start=monday,
            defaults=dict(
                visits_target=target,
                new_doctors_target=3,
                orders_target=4,
                coverage_target_pct=60,
            ),
        )

    def _seed_medical(self, rep, products):
        doctors = {}
        for name, gender, specialty, wilaya, potential in self.MED_DOCTORS:
            commune = random.choice(self.COMMUNES_BY_WILAYA[wilaya])
            doctors[name], _ = Doctor.objects.get_or_create(
                normalized_name=normalize_name(name),
                wilaya=wilaya,
                defaults=dict(
                    name=name,
                    gender=gender,
                    specialty=specialty,
                    structure_type=random.choice(self.STRUCTURES_MED),
                    potential=potential,
                    address=f"Rue {random.randint(1, 50)} {commune}",
                    commune=commune,
                    telephone=f"0{random.randint(500000000, 799999999)}",
                    email=f"{normalize_name(name).replace(' ', '.')}@clinic.dz",
                    owner=rep,
                ),
            )

        count = 0
        for _ in range(24):
            name, gender, specialty, wilaya, potential = random.choice(
                self.MED_DOCTORS
            )
            doctor = doctors[name]
            visit = VisitRecord.objects.create(
                id=uuid.uuid4().hex,
                date=self._rand_date(),
                rep=rep,
                visit_type=VisitType.MEDICAL,
                doctor=doctor,
                target_name=name,
                gender=gender,
                specialty=specialty,
                structure_type=doctor.structure_type,
                potential=potential,
                address=doctor.address,
                wilaya=wilaya,
                commune=doctor.commune,
                telephone=doctor.telephone,
                email=doctor.email,
                patient_load=random.choice(["0-15", "16-30", "30+"]),
                duration_minutes=random.choice([20, 30, 45, 60]),
                qty_vials=random.randint(0, 10),
                qty_meters=random.randint(0, 6),
                qty_brochure_m=random.randint(0, 5),
                qty_brochure_patient=random.randint(0, 12),
                qty_affiche=random.randint(0, 2),
                comment=random.choice(
                    ["Bon accueil.", "Demande de documentation.", "", "Suivi à faire."]
                ),
                objections=random.choice(self.OBJECTIONS),
                next_action=random.choice(self.NEXT_ACTIONS),
                next_action_date=self._future_date() if random.random() > 0.5 else None,
            )
            count += 1
            if products:
                for prod in random.sample(products, k=min(2, len(products))):
                    VisitProduct.objects.get_or_create(
                        visit=visit, product=prod,
                        defaults={"samples_qty": random.randint(0, 3)},
                    )
                if random.random() > 0.6:
                    Prescription.objects.create(
                        visit=visit, doctor=doctor, rep=rep,
                        product=random.choice(products),
                        quantity=random.randint(1, 20),
                        status=random.choice(list(PrescriptionStatus.values)),
                    )
        return count

    def _seed_pharma(self, rep, products):
        pharmacies = {}
        for name, structure, wilaya, potential in self.PHARMA_TARGETS:
            commune = random.choice(self.COMMUNES_BY_WILAYA[wilaya])
            pharmacies[name], _ = Pharmacy.objects.get_or_create(
                normalized_name=normalize_name(name),
                wilaya=wilaya,
                defaults=dict(
                    name=name,
                    structure_type=structure,
                    potential=potential,
                    address=f"Avenue {random.randint(1, 20)} {commune}",
                    commune=commune,
                    telephone=f"0{random.randint(500000000, 799999999)}",
                    owner=rep,
                ),
            )

        count = 0
        for _ in range(18):
            name, structure, wilaya, potential = random.choice(self.PHARMA_TARGETS)
            pharmacy = pharmacies[name]
            visit = VisitRecord.objects.create(
                id=uuid.uuid4().hex,
                date=self._rand_date(),
                rep=rep,
                visit_type=VisitType.PHARMACEUTICAL,
                pharmacy=pharmacy,
                target_name=name,
                specialty="N/A",
                structure_type=structure,
                potential=potential,
                address=pharmacy.address,
                wilaya=wilaya,
                commune=pharmacy.commune,
                telephone=pharmacy.telephone,
                email="",
                patient_load="0-15",
                duration_minutes=random.choice([15, 20, 30]),
                qty_reader=random.randint(0, 5),
                qty_affiche=random.randint(0, 2),
                comment=random.choice(
                    ["Stock vérifié.", "Réappro demandé.", "", "Commande en cours."]
                ),
            )
            count += 1
            if products and random.random() > 0.4:
                Prescription.objects.create(
                    visit=visit, pharmacy=pharmacy, rep=rep,
                    product=random.choice(products),
                    quantity=random.randint(5, 50),
                    status=random.choice(list(PrescriptionStatus.values)),
                )
        return count
