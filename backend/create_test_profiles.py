"""Ad-hoc weak-credential seeder for throwaway demo environments only.

Guarded so it can never run by accident in production (see inconsistencies.md
§4.3). Set ALLOW_TEST_PROFILES=1 to enable. Prefer `manage.py seed_users`.
"""
import os

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from visimed.models import User, UserRole  # noqa: E402


def create_users():
    if os.environ.get("ALLOW_TEST_PROFILES") != "1":
        print("ALLOW_TEST_PROFILES != 1 — refusing to seed weak test credentials.")
        return

    users_to_create = [
        {"username": "admin1", "password": "password123", "role": UserRole.ADMIN, "email": "admin1@visimed.com"},
        {"username": "manager1", "password": "password123", "role": UserRole.MANAGER, "email": "manager1@visimed.com"},
        {"username": "medrep2", "password": "password123", "role": UserRole.MED_REP, "email": "medrep2@visimed.com"},
        {"username": "pharmarep2", "password": "password123", "role": UserRole.PHARMA_REP, "email": "pharmarep2@visimed.com"},
        {"username": "medrep3", "password": "password123", "role": UserRole.MED_REP, "email": "medrep3@visimed.com"},
    ]

    for data in users_to_create:
        if not User.objects.filter(username=data["username"]).exists():
            User.objects.create_user(**data)
            print(f"Created user {data['username']}")
        else:
            print(f"User {data['username']} already exists")


if __name__ == "__main__":
    create_users()
