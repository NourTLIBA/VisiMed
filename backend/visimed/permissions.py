from rest_framework import permissions

from .models import UserRole


class IsAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and request.user.role == UserRole.ADMIN
        )


class IsManagerOrAdmin(permissions.BasePermission):
    """Cross-rep read access: dashboards, leaderboard, alerts."""

    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in (
            UserRole.ADMIN,
            UserRole.MANAGER,
        )


class IsAdminOrManagerReadOnly(permissions.BasePermission):
    """Admin may write; manager may read; reps are denied."""

    def has_permission(self, request, view):
        user = request.user
        if not user.is_authenticated:
            return False
        if user.role == UserRole.ADMIN:
            return True
        if user.role == UserRole.MANAGER:
            return request.method in permissions.SAFE_METHODS
        return False


class IsAdminOrReadOwn(permissions.BasePermission):
    """Admin full access; reps read only their own profile."""

    def has_permission(self, request, view):
        return request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if request.user.role in (UserRole.ADMIN, UserRole.MANAGER):
            return True
        return obj == request.user
