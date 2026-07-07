from django.contrib.auth.hashers import make_password
from rest_framework import serializers

from .models import Locality, User, UserRole, VisitRecord, VisitType


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)

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
        ]
        read_only_fields = fields


class LocalitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Locality
        fields = ["code_commune", "nom_commune", "nom_wilaya"]


class VisitRecordSerializer(serializers.ModelSerializer):
    rep_username = serializers.CharField(source="rep.username", read_only=True)

    class Meta:
        model = VisitRecord
        fields = [
            "id",
            "date",
            "rep",
            "rep_username",
            "visit_type",
            "target_name",
            "gender",
            "specialty",
            "structure_type",
            "potential",
            "address",
            "wilaya",
            "commune",
            "telephone",
            "email",
            "patient_load",
            "duration_minutes",
            "qty_reader",
            "qty_vials",
            "qty_brochure_m",
            "qty_brochure_patient",
            "qty_affiche",
            "photo_url",
            "comment",
        ]
        read_only_fields = ["rep", "rep_username"]

    def validate_visit_type(self, value):
        request = self.context.get("request")
        if not request or request.user.role == UserRole.ADMIN:
            return value
        if request.user.role == UserRole.MED_REP and value != VisitType.MEDICAL:
            raise serializers.ValidationError(
                "Medical representatives may only log medical visits."
            )
        if request.user.role == UserRole.PHARMA_REP and value != VisitType.PHARMACEUTICAL:
            raise serializers.ValidationError(
                "Pharmaceutical representatives may only log pharmaceutical visits."
            )
        return value
