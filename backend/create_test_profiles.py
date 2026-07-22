import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from visimed.models import User, UserRole

def create_users():
    users_to_create = [
        {"username": "admin1", "password": "password123", "role": UserRole.ADMIN, "email": "admin1@visimed.com"},
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

if __name__ == '__main__':
    create_users()
