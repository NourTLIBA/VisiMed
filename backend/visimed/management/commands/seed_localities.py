import csv
from pathlib import Path

from django.core.management.base import BaseCommand

from visimed.models import Locality


class Command(BaseCommand):
    help = "Seed vm_localities from Activity Report - Listes_items.csv"

    def add_arguments(self, parser):
        parser.add_argument(
            "--csv",
            default=None,
            help="Path to Listes_items.csv (defaults to repo root)",
        )

    def handle(self, *args, **options):
        csv_path = options["csv"]
        if not csv_path:
            csv_path = (
                Path(__file__).resolve().parents[4]
                / "Activity Report - Listes_items.csv"
            )
        csv_path = Path(csv_path)

        if not csv_path.exists():
            self.stderr.write(self.style.ERROR(f"CSV not found: {csv_path}"))
            return

        rows = []
        with open(csv_path, encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                code = row.get("Code_Commune", "").strip()
                if not code:
                    continue
                rows.append(
                    Locality(
                        code_commune=code,
                        nom_commune=row.get("Nom_Commune", "").strip(),
                        nom_wilaya=row.get("Nom_Wilaya", "").strip(),
                    )
                )

        Locality.objects.bulk_create(rows, ignore_conflicts=True)
        self.stdout.write(
            self.style.SUCCESS(f"Seeded {len(rows)} localities from {csv_path.name}")
        )
