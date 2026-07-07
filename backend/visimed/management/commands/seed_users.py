from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand

from visimed.models import User, UserRole


class Command(BaseCommand):
    help = "Create default admin and sample representative accounts"

    def handle(self, *args, **options):
        admin, created = User.objects.get_or_create(
            username="admin",
            defaults={
                "email": "admin@visimed.dz",
                "role": UserRole.ADMIN,
                "is_staff": True,
                "is_superuser": True,
                "password": make_password("admin123"),
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created admin (admin / admin123)"))
        else:
            self.stdout.write("Admin already exists")

        samples = [
            ("medrep1", UserRole.MED_REP, "Alger,Blida", "med123"),
            ("pharmrep1", UserRole.PHARMA_REP, "Oran,Mostaganem", "pharma123"),
        ]
        for username, role, regions, password in samples:
            _, created = User.objects.get_or_create(
                username=username,
                defaults={
                    "email": f"{username}@visimed.dz",
                    "role": role,
                    "assigned_regions": regions,
                    "password": make_password(password),
                },
            )
            if created:
                self.stdout.write(
                    self.style.SUCCESS(f"Created {username} / {password}")
                )
