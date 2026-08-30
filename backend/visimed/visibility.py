"""Single source of truth for 'what data can this user see'.

Previously the viewset and the export views implemented two different rules
(see inconsistencies.md §1.4). Everything now goes through here.
"""

from django.db.models import Q

from .models import Doctor, Pharmacy, UserRole, VisitRecord


def _rep_scope(user) -> Q:
    """Rows owned by the rep OR sitting in one of their territory wilayas."""
    wilayas = user.scoped_wilayas()
    scope = Q(rep=user)
    if wilayas:
        scope |= Q(wilaya__in=wilayas)
    return scope


def visible_visits(user):
    qs = VisitRecord.objects.select_related("rep", "doctor", "pharmacy")
    if user.is_staff_role:
        return qs
    return qs.filter(_rep_scope(user))


def visible_doctors(user):
    qs = Doctor.objects.all()
    if user.is_staff_role:
        return qs
    wilayas = user.scoped_wilayas()
    scope = Q(owner=user) | Q(visits__rep=user)
    if wilayas:
        scope |= Q(wilaya__in=wilayas)
    return qs.filter(scope).distinct()


def visible_pharmacies(user):
    qs = Pharmacy.objects.all()
    if user.is_staff_role:
        return qs
    wilayas = user.scoped_wilayas()
    scope = Q(owner=user) | Q(visits__rep=user)
    if wilayas:
        scope |= Q(wilaya__in=wilayas)
    return qs.filter(scope).distinct()


def managed_reps(user):
    """Reps whose activity `user` may roll up (managers/admins see all)."""
    from .models import User

    reps = User.objects.filter(role__in=[UserRole.MED_REP, UserRole.PHARMA_REP])
    if user.role == UserRole.ADMIN or user.role == UserRole.MANAGER:
        return reps
    return reps.filter(pk=user.pk)
