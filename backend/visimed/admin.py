from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import (
    Doctor,
    Locality,
    Objective,
    Pharmacy,
    Prescription,
    Product,
    Territory,
    User,
    VisitProduct,
    VisitRecord,
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        (
            "VisiMed",
            {"fields": ("role", "assigned_regions", "territory", "telephone")},
        ),
    )
    list_display = ("username", "email", "role", "territory", "is_active")
    list_filter = ("role", "is_active", "territory")


@admin.register(Territory)
class TerritoryAdmin(admin.ModelAdmin):
    list_display = ("name", "wilayas")


@admin.register(Locality)
class LocalityAdmin(admin.ModelAdmin):
    list_display = ("code_commune", "nom_commune", "nom_wilaya")
    search_fields = ("nom_commune", "nom_wilaya")
    list_filter = ("nom_wilaya",)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "is_active")
    list_filter = ("is_active", "category")
    search_fields = ("name",)


class VisitProductInline(admin.TabularInline):
    model = VisitProduct
    extra = 0


class PrescriptionInline(admin.TabularInline):
    model = Prescription
    extra = 0
    fk_name = "visit"


@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
    list_display = ("name", "specialty", "potential", "wilaya", "gco_status", "owner")
    list_filter = ("potential", "gco_status", "wilaya", "specialty")
    search_fields = ("name", "telephone", "email")


@admin.register(Pharmacy)
class PharmacyAdmin(admin.ModelAdmin):
    list_display = ("name", "structure_type", "potential", "wilaya", "owner")
    list_filter = ("potential", "wilaya", "structure_type")
    search_fields = ("name", "telephone", "email")


@admin.register(VisitRecord)
class VisitRecordAdmin(admin.ModelAdmin):
    list_display = ("id", "date", "rep", "visit_type", "target_name", "potential")
    list_filter = ("visit_type", "potential", "wilaya")
    search_fields = ("target_name", "rep__username")
    inlines = [VisitProductInline, PrescriptionInline]


@admin.register(Prescription)
class PrescriptionAdmin(admin.ModelAdmin):
    list_display = ("__str__", "doctor", "pharmacy", "rep", "status", "created_at")
    list_filter = ("status", "created_at")


@admin.register(Objective)
class ObjectiveAdmin(admin.ModelAdmin):
    list_display = (
        "rep",
        "period_type",
        "period_start",
        "visits_target",
        "orders_target",
    )
    list_filter = ("period_type",)
