from django.contrib.auth.models import AbstractUser
from django.db import models


class UserRole(models.TextChoices):
    ADMIN = "admin", "Admin"
    MED_REP = "med_rep", "Medical Representative"
    PHARMA_REP = "pharma_rep", "Pharmaceutical Representative"


class User(AbstractUser):
    role = models.CharField(
        max_length=20, choices=UserRole.choices, default=UserRole.MED_REP
    )
    assigned_regions = models.TextField(
        help_text="Comma-separated strings, e.g., 'Kabylie,Ouest'", blank=True
    )

    class Meta:
        db_table = "vm_users"


class Locality(models.Model):
    """Geographic data parsed from Listes_items.csv"""

    code_commune = models.CharField(max_length=10, primary_key=True)
    nom_commune = models.CharField(max_length=100, db_index=True)
    nom_wilaya = models.CharField(max_length=100, db_index=True)

    class Meta:
        db_table = "vm_localities"
        verbose_name_plural = "localities"


class VisitType(models.TextChoices):
    MEDICAL = "medical", "Médicale"
    PHARMACEUTICAL = "pharmaceutical", "Pharmaceutique"


class TargetPotential(models.TextChoices):
    KOL = "KOL", "Key Opinion Leader"
    A = "A", "High Potential"
    B = "B", "Medium Potential"
    C = "C", "Low Potential"


class VisitRecord(models.Model):
    id = models.CharField(max_length=50, primary_key=True)
    date = models.DateField(db_index=True)
    rep = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="visits", db_index=True
    )
    visit_type = models.CharField(max_length=20, choices=VisitType.choices)

    target_name = models.CharField(max_length=150)
    gender = models.CharField(
        max_length=1, choices=[("M", "M"), ("F", "F")], null=True, blank=True
    )
    specialty = models.CharField(max_length=50, default="N/A")
    structure_type = models.CharField(max_length=100)
    potential = models.CharField(
        max_length=5, choices=TargetPotential.choices, db_index=True
    )

    address = models.TextField()
    wilaya = models.CharField(max_length=100, db_index=True)
    commune = models.CharField(max_length=100)
    telephone = models.CharField(max_length=20)
    email = models.EmailField(blank=True, default='')

    patient_load = models.CharField(max_length=20, default="0-15")
    duration_minutes = models.IntegerField(default=0)
    qty_reader = models.IntegerField(default=0)
    qty_vials = models.IntegerField(default=0)
    qty_brochure_m = models.IntegerField(default=0)
    qty_brochure_patient = models.IntegerField(default=0)
    qty_affiche = models.IntegerField(default=0)
    photo_url = models.URLField(max_length=500, null=True, blank=True)
    comment = models.TextField(null=True, blank=True)

    class Meta:
        db_table = "vm_visit_records"
        ordering = ["-date"]
