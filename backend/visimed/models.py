import unicodedata
import uuid

from django.contrib.auth.models import AbstractUser
from django.db import models


def _new_visit_id() -> str:
    """Server-generated identifier for a visit record.

    Historically the Flutter client generated this UUID and the server trusted
    it (see inconsistencies.md §1.2). The column stays a CharField so existing
    rows — some of which are not valid UUIDs — keep working, but new rows are
    always minted here and the field is read-only in the serializer.
    """
    return uuid.uuid4().hex


def normalize_name(value: str) -> str:
    """Loose key for de-duplicating doctors / pharmacies typed by hand.

    Lowercases, strips accents, drops the ``dr`` / ``dr.`` honorific and
    collapses whitespace so "Dr. Karim  ZOURDANI" and "karim zourdani" cluster
    together.
    """
    if not value:
        return ""
    text = unicodedata.normalize("NFKD", value)
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = text.lower().strip()
    for prefix in ("dr.", "dr ", "pr.", "pr "):
        if text.startswith(prefix):
            text = text[len(prefix):]
    return " ".join(text.split())


class UserRole(models.TextChoices):
    ADMIN = "admin", "Admin"
    MANAGER = "manager", "Manager"
    MED_REP = "med_rep", "Medical Representative"
    PHARMA_REP = "pharma_rep", "Pharmaceutical Representative"


class Territory(models.Model):
    """Normalized sales territory — replaces free-text ``assigned_regions``
    parsing for access control (see inconsistencies.md §1.5)."""

    name = models.CharField(max_length=120, unique=True)
    wilayas = models.JSONField(
        default=list, blank=True, help_text="List of wilaya names covered."
    )

    class Meta:
        db_table = "vm_territories"
        verbose_name_plural = "territories"
        ordering = ["name"]

    def __str__(self):
        return self.name


class User(AbstractUser):
    role = models.CharField(
        max_length=20, choices=UserRole.choices, default=UserRole.MED_REP
    )
    assigned_regions = models.TextField(
        help_text="Legacy free-text regions, kept for display only.", blank=True
    )
    territory = models.ForeignKey(
        Territory,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="reps",
    )
    telephone = models.CharField(max_length=20, blank=True, default="")

    class Meta:
        db_table = "vm_users"

    # ── role helpers ────────────────────────────────────────────────────────
    @property
    def is_staff_role(self) -> bool:
        """True for admin & manager — the personas that see cross-rep data."""
        return self.role in (UserRole.ADMIN, UserRole.MANAGER)

    def scoped_wilayas(self) -> list[str]:
        """Wilayas this user is responsible for.

        Prefers the structured :class:`Territory`; falls back to a best-effort
        parse of the legacy ``assigned_regions`` string.
        """
        if self.territory_id and self.territory.wilayas:
            return [w.strip() for w in self.territory.wilayas if w and w.strip()]
        tokens: list[str] = []
        raw = self.assigned_regions or ""
        for chunk in raw.replace("(", ",").replace(")", ",").split(","):
            token = chunk.strip(" .;")
            # Drop obvious group labels like "Ouest" / "Est 1" / "Kabylie".
            if token and not token.lower().startswith(("ouest", "est ", "est,", "kabylie", "centre", "sud", "nord")):
                tokens.append(token)
        return tokens


class Locality(models.Model):
    """Geographic data parsed from Listes_items.csv"""

    code_commune = models.CharField(max_length=10, primary_key=True)
    nom_commune = models.CharField(max_length=100, db_index=True)
    nom_wilaya = models.CharField(max_length=100, db_index=True)

    class Meta:
        db_table = "vm_localities"
        verbose_name_plural = "localities"

    def __str__(self):
        return f"{self.nom_commune} ({self.nom_wilaya})"


class VisitType(models.TextChoices):
    MEDICAL = "medical", "Médicale"
    PHARMACEUTICAL = "pharmaceutical", "Pharmaceutique"


class TargetPotential(models.TextChoices):
    KOL = "KOL", "Key Opinion Leader"
    A = "A", "High Potential"
    B = "B", "Medium Potential"
    C = "C", "Low Potential"


class GCOStatus(models.TextChoices):
    NOT_INTERESTED = "Pas intéressé(e)", "Pas intéressé(e)"
    INTERESTED = "Intéressé(e)", "Intéressé(e)"
    TRAINED = "Formé(e)", "Formé(e)"
    ACCOUNT_CREATED = "Compte GCO créé", "Compte GCO créé"
    ACCOUNT_INACTIVE = "Compte non actif", "Compte non actif"
    ACCOUNT_ACTIVE = "Compte actif", "Compte actif"


class Product(models.Model):
    """Promotable product / device — the catalogue behind 'produits présentés'."""

    name = models.CharField(max_length=120, unique=True)
    category = models.CharField(max_length=60, blank=True, default="")
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "vm_products"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Doctor(models.Model):
    """A physician tracked across visits (see inconsistencies.md §2.1)."""

    name = models.CharField(max_length=150, db_index=True)
    normalized_name = models.CharField(max_length=150, db_index=True, default="")
    gender = models.CharField(
        max_length=1, choices=[("M", "M"), ("F", "F")], blank=True, default=""
    )
    specialty = models.CharField(max_length=80, blank=True, default="")
    structure_type = models.CharField(max_length=100, blank=True, default="")
    potential = models.CharField(
        max_length=5,
        choices=TargetPotential.choices,
        default=TargetPotential.C,
        db_index=True,
    )
    gco_status = models.CharField(
        max_length=50, choices=GCOStatus.choices, default=GCOStatus.NOT_INTERESTED
    )
    address = models.TextField(blank=True, default="")
    wilaya = models.CharField(max_length=100, db_index=True, blank=True, default="")
    commune = models.CharField(max_length=100, blank=True, default="")
    telephone = models.CharField(max_length=30, blank=True, default="")
    email = models.EmailField(blank=True, default="")
    owner = models.ForeignKey(
        User,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="doctors",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "vm_doctors"
        ordering = ["name"]
        constraints = [
            models.UniqueConstraint(
                fields=["normalized_name", "wilaya"], name="uniq_doctor_name_wilaya"
            )
        ]

    def save(self, *args, **kwargs):
        if not self.normalized_name:
            self.normalized_name = normalize_name(self.name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name


class Pharmacy(models.Model):
    """An officine / grossiste tracked across visits."""

    name = models.CharField(max_length=150, db_index=True)
    normalized_name = models.CharField(max_length=150, db_index=True, default="")
    structure_type = models.CharField(max_length=100, blank=True, default="")
    potential = models.CharField(
        max_length=5,
        choices=TargetPotential.choices,
        default=TargetPotential.C,
        db_index=True,
    )
    address = models.TextField(blank=True, default="")
    wilaya = models.CharField(max_length=100, db_index=True, blank=True, default="")
    commune = models.CharField(max_length=100, blank=True, default="")
    telephone = models.CharField(max_length=30, blank=True, default="")
    email = models.EmailField(blank=True, default="")
    owner = models.ForeignKey(
        User,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="pharmacies",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "vm_pharmacies"
        verbose_name_plural = "pharmacies"
        ordering = ["name"]
        constraints = [
            models.UniqueConstraint(
                fields=["normalized_name", "wilaya"],
                name="uniq_pharmacy_name_wilaya",
            )
        ]

    def save(self, *args, **kwargs):
        if not self.normalized_name:
            self.normalized_name = normalize_name(self.name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name


class VisitRecord(models.Model):
    id = models.CharField(
        max_length=50, primary_key=True, default=_new_visit_id, editable=False
    )
    date = models.DateField(db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, null=True, db_index=True)
    rep = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="visits", db_index=True
    )
    visit_type = models.CharField(max_length=20, choices=VisitType.choices)

    doctor = models.ForeignKey(
        Doctor,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="visits",
    )
    pharmacy = models.ForeignKey(
        Pharmacy,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="visits",
    )

    target_name = models.CharField(max_length=150)
    gender = models.CharField(
        max_length=1, choices=[("M", "M"), ("F", "F")], null=True, blank=True
    )
    specialty = models.CharField(max_length=50, default="N/A")
    structure_type = models.CharField(max_length=100)
    potential = models.CharField(
        max_length=5, choices=TargetPotential.choices, db_index=True
    )
    gco_status = models.CharField(
        max_length=50,
        choices=GCOStatus.choices,
        default=GCOStatus.NOT_INTERESTED,
    )

    address = models.TextField()
    wilaya = models.CharField(max_length=100, db_index=True)
    commune = models.CharField(max_length=100)
    telephone = models.CharField(max_length=20)
    email = models.EmailField(blank=True, default="")

    patient_load = models.CharField(max_length=20, default="0-15")
    duration_minutes = models.IntegerField(default=0)
    qty_reader = models.IntegerField(default=0)
    qty_vials = models.IntegerField(default=0)
    qty_meters = models.IntegerField(default=0)
    qty_brochure_m = models.IntegerField(default=0)
    qty_brochure_patient = models.IntegerField(default=0)
    qty_affiche = models.IntegerField(default=0)
    photo_url = models.URLField(max_length=500, null=True, blank=True)

    # Structured visit outcome (see inconsistencies.md §2.5)
    comment = models.TextField(null=True, blank=True, help_text="Remarques")
    objections = models.TextField(blank=True, default="")
    next_action = models.TextField(blank=True, default="")
    next_action_date = models.DateField(null=True, blank=True, db_index=True)

    class Meta:
        db_table = "vm_visit_records"
        ordering = ["-date", "-created_at"]

    def total_material(self) -> int:
        return (
            self.qty_reader
            + self.qty_vials
            + self.qty_meters
            + self.qty_brochure_m
            + self.qty_brochure_patient
            + self.qty_affiche
        )


class VisitProduct(models.Model):
    """Which catalogue products were detailed during a visit."""

    visit = models.ForeignKey(
        VisitRecord, on_delete=models.CASCADE, related_name="presented_products"
    )
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    samples_qty = models.IntegerField(default=0)

    class Meta:
        db_table = "vm_visit_products"
        unique_together = ("visit", "product")

    def __str__(self):
        return f"{self.product} @ {self.visit_id}"


class PrescriptionStatus(models.TextChoices):
    PENDING = "pending", "En attente"
    CONFIRMED = "confirmed", "Confirmée"
    DELIVERED = "delivered", "Livrée"
    CANCELLED = "cancelled", "Annulée"


class Prescription(models.Model):
    """An order obtained ('commande') — from a doctor or a pharmacy."""

    visit = models.ForeignKey(
        VisitRecord,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="prescriptions",
    )
    doctor = models.ForeignKey(
        Doctor,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="prescriptions",
    )
    pharmacy = models.ForeignKey(
        Pharmacy,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="prescriptions",
    )
    product = models.ForeignKey(
        Product, null=True, blank=True, on_delete=models.SET_NULL
    )
    rep = models.ForeignKey(
        User,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="prescriptions",
    )
    quantity = models.IntegerField(default=0)
    status = models.CharField(
        max_length=20,
        choices=PrescriptionStatus.choices,
        default=PrescriptionStatus.PENDING,
    )
    note = models.CharField(max_length=255, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = "vm_prescriptions"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.product or 'order'} x{self.quantity} ({self.status})"


class ObjectivePeriod(models.TextChoices):
    WEEKLY = "weekly", "Hebdomadaire"
    MONTHLY = "monthly", "Mensuel"


class Objective(models.Model):
    """Per-rep target for a period. Ships empty — the client has not supplied
    numbers yet (see inconsistencies.md §2.4)."""

    rep = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="objectives"
    )
    period_type = models.CharField(
        max_length=10,
        choices=ObjectivePeriod.choices,
        default=ObjectivePeriod.WEEKLY,
    )
    period_start = models.DateField(help_text="First day of the target period.")
    visits_target = models.IntegerField(default=0)
    new_doctors_target = models.IntegerField(default=0)
    orders_target = models.IntegerField(default=0)
    coverage_target_pct = models.IntegerField(default=0)

    class Meta:
        db_table = "vm_objectives"
        ordering = ["-period_start"]
        unique_together = ("rep", "period_type", "period_start")

    def __str__(self):
        return f"{self.rep} · {self.period_type} · {self.period_start}"
