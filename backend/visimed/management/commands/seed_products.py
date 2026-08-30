from django.core.management.base import BaseCommand

from visimed.models import Product

CATALOGUE = [
    ("GlucoReader X1", "Lecteur"),
    ("GlucoReader Pro", "Lecteur"),
    ("Bandelettes T-50", "Consommable"),
    ("Lancettes Fine 33G", "Consommable"),
    ("Insuline RapidAct", "Traitement"),
    ("Insuline BasalGlar", "Traitement"),
    ("Kit Éducation Patient", "Support"),
    ("Application GCO", "Service"),
]


class Command(BaseCommand):
    help = "Seed a small promotable-product catalogue."

    def handle(self, *args, **options):
        created = 0
        for name, category in CATALOGUE:
            _, was_created = Product.objects.get_or_create(
                name=name, defaults={"category": category}
            )
            created += int(was_created)
        self.stdout.write(
            self.style.SUCCESS(
                f"Products: {created} created, {Product.objects.count()} total."
            )
        )
