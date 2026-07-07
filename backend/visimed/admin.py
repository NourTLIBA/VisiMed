from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import Locality, User, VisitRecord


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        ("VisiMed", {"fields": ("role", "assigned_regions")}),
    )
    list_display = ("username", "email", "role", "is_active")
    list_filter = ("role", "is_active")


@admin.register(Locality)
class LocalityAdmin(admin.ModelAdmin):
    list_display = ("code_commune", "nom_commune", "nom_wilaya")
    search_fields = ("nom_commune", "nom_wilaya")
    list_filter = ("nom_wilaya",)


@admin.register(VisitRecord)
class VisitRecordAdmin(admin.ModelAdmin):
    list_display = ("id", "date", "rep", "visit_type", "target_name", "potential")
    list_filter = ("visit_type", "potential", "wilaya")
    search_fields = ("target_name", "rep__username")
