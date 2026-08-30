from django.contrib.auth.hashers import make_password
from rest_framework import serializers

from .models import (
    Doctor,
    Locality,
    Objective,
    Pharmacy,
    Prescription,
    Product,
    Territory,
    User,
    UserRole,
    VisitProduct,
    VisitRecord,
    VisitType,
)


class TerritorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Territory
        fields = ["id", "name", "wilayas"]


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)
    territory_name = serializers.CharField(source="territory.name", read_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "role",
            "assigned_regions",
            "territory",
            "territory_name",
            "telephone",
            "password",
            "is_active",
        ]
        read_only_fields = ["id"]

    def create(self, validated_data):
        password = validated_data.pop("password", None)
        user = User(**validated_data)
        if password:
            user.password = make_password(password)
        else:
            user.set_unusable_password()
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.password = make_password(password)
        instance.save()
        return instance


class UserProfileSerializer(serializers.ModelSerializer):
    territory_name = serializers.CharField(source="territory.name", read_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "role",
            "assigned_regions",
            "territory",
            "territory_name",
            "telephone",
        ]
        read_only_fields = fields


class LocalitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Locality
        fields = ["code_commune", "nom_commune", "nom_wilaya"]


class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ["id", "name", "category", "is_active"]


class DoctorSerializer(serializers.ModelSerializer):
    visit_count = serializers.IntegerField(read_only=True, required=False)
    last_visit_date = serializers.DateField(read_only=True, required=False)

    class Meta:
        model = Doctor
        fields = [
            "id",
            "name",
            "gender",
            "specialty",
            "structure_type",
            "potential",
            "gco_status",
            "address",
            "wilaya",
            "commune",
            "telephone",
            "email",
            "owner",
            "created_at",
            "visit_count",
            "last_visit_date",
        ]
        read_only_fields = ["owner", "created_at"]


class PharmacySerializer(serializers.ModelSerializer):
    visit_count = serializers.IntegerField(read_only=True, required=False)
    last_visit_date = serializers.DateField(read_only=True, required=False)

    class Meta:
        model = Pharmacy
        fields = [
            "id",
            "name",
            "structure_type",
            "potential",
            "address",
            "wilaya",
            "commune",
            "telephone",
            "email",
            "owner",
            "created_at",
            "visit_count",
            "last_visit_date",
        ]
        read_only_fields = ["owner", "created_at"]


class VisitProductSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="product.name", read_only=True)

    class Meta:
        model = VisitProduct
        fields = ["id", "product", "product_name", "samples_qty"]


class PrescriptionSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="product.name", read_only=True)
    rep_username = serializers.CharField(source="rep.username", read_only=True)

    class Meta:
        model = Prescription
        fields = [
            "id",
            "visit",
            "doctor",
            "pharmacy",
            "product",
            "product_name",
            "rep",
            "rep_username",
            "quantity",
            "status",
            "note",
            "created_at",
        ]
        read_only_fields = ["rep", "created_at"]


class ObjectiveSerializer(serializers.ModelSerializer):
    rep_username = serializers.CharField(source="rep.username", read_only=True)

    class Meta:
        model = Objective
        fields = [
            "id",
            "rep",
            "rep_username",
            "period_type",
            "period_start",
            "visits_target",
            "new_doctors_target",
            "orders_target",
            "coverage_target_pct",
        ]


class VisitRecordSerializer(serializers.ModelSerializer):
    rep_username = serializers.CharField(source="rep.username", read_only=True)
    presented_products = VisitProductSerializer(many=True, read_only=True)
    prescriptions = PrescriptionSerializer(many=True, read_only=True)
    doctor_name = serializers.CharField(source="doctor.name", read_only=True)

    # Write-only nested payloads (optional).
    product_ids = serializers.ListField(
        child=serializers.IntegerField(), write_only=True, required=False
    )
    order_items = serializers.ListField(
        child=serializers.DictField(), write_only=True, required=False
    )

    class Meta:
        model = VisitRecord
        fields = [
            "id",
            "date",
            "created_at",
            "rep",
            "rep_username",
            "visit_type",
            "doctor",
            "doctor_name",
            "pharmacy",
            "target_name",
            "gender",
            "specialty",
            "structure_type",
            "potential",
            "gco_status",
            "address",
            "wilaya",
            "commune",
            "telephone",
            "email",
            "patient_load",
            "duration_minutes",
            "qty_reader",
            "qty_vials",
            "qty_meters",
            "qty_brochure_m",
            "qty_brochure_patient",
            "qty_affiche",
            "photo_url",
            "comment",
            "objections",
            "next_action",
            "next_action_date",
            "presented_products",
            "prescriptions",
            "product_ids",
            "order_items",
        ]
        read_only_fields = ["id", "rep", "rep_username", "created_at"]

    def validate_visit_type(self, value):
        request = self.context.get("request")
        if not request or request.user.is_staff_role:
            return value
        if request.user.role == UserRole.MED_REP and value != VisitType.MEDICAL:
            raise serializers.ValidationError(
                "Medical representatives may only log medical visits."
            )
        if (
            request.user.role == UserRole.PHARMA_REP
            and value != VisitType.PHARMACEUTICAL
        ):
            raise serializers.ValidationError(
                "Pharmaceutical representatives may only log pharmaceutical visits."
            )
        return value
