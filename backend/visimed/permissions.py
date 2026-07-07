from rest_framework import permissions

from .models import UserRole


class IsAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and request.user.role == UserRole.ADMIN
        )


class IsAdminOrReadOwn(permissions.BasePermission):
    """Admin full access; reps read only their own profile."""

    def has_permission(self, request, view):
        return request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if request.user.role == UserRole.ADMIN:
            return True
        return obj == request.user
