import csv
import datetime
import io

from django.conf import settings
from django.contrib.auth.hashers import make_password
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import Avg, Count, Max, Q, Sum
from django.http import HttpResponse
from django.utils import timezone
from openpyxl import Workbook
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import Paragraph, SimpleDocTemplate, Table, TableStyle
from rest_framework import permissions, status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    Doctor,
    Locality,
    Objective,
    Pharmacy,
    Prescription,
    PrescriptionStatus,
    Product,
    TargetPotential,
    User,
    UserRole,
    VisitProduct,
    VisitRecord,
    VisitType,
    normalize_name,
)
from .permissions import IsAdmin, IsManagerOrAdmin
from .serializers import (
    DoctorSerializer,
    LocalitySerializer,
    ObjectiveSerializer,
    PharmacySerializer,
    PrescriptionSerializer,
    ProductSerializer,
    UserProfileSerializer,
    UserSerializer,
    VisitRecordSerializer,
)
from .visibility import (
    managed_reps,
    visible_doctors,
    visible_pharmacies,
    visible_visits,
)


# ── date helpers ─────────────────────────────────────────────────────────────
def _today():
    return timezone.localdate()


def _week_start(day=None):
    day = day or _today()
    return day - datetime.timedelta(days=day.weekday())


def _month_start(day=None):
    day = day or _today()
    return day.replace(day=1)


def issue_fresh_token(user):
    """Return a valid token, rotating it if the existing one has expired.

    The expiry rule lives in ``ExpiringTokenAuthentication``; this helper simply
    keeps the login path in sync with it (see inconsistencies.md §1.7).
    """
    token, created = Token.objects.get_or_create(user=user)
    if not created:
        ttl = getattr(settings, "TOKEN_EXPIRED_AFTER_HOURS", 24)
        if token.created < timezone.now() - datetime.timedelta(hours=ttl):
            token.delete()
            token = Token.objects.create(user=user)
    return token


class OptionalPagination(PageNumberPagination):
    """Standard page-number pagination, unless the caller passes ``?all=1``
    (used by the Flutter client to hydrate its full working set — see
    inconsistencies.md §6.3)."""

    page_size = 100

    def paginate_queryset(self, queryset, request, view=None):
        if request.query_params.get("all") in ("1", "true", "yes"):
            return None
        return super().paginate_queryset(queryset, request, view)


class AuthTokenView(ObtainAuthToken):
    """Login — returns token + user profile."""

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token = issue_fresh_token(user)
        return Response(
            {"token": token.key, "user": UserProfileSerializer(user).data}
        )


class RepresentativeCRUDViewSet(viewsets.ModelViewSet):
    queryset = User.objects.exclude(role=UserRole.ADMIN).order_by("username")
    serializer_class = UserSerializer

    def get_permissions(self):
        if self.request.method in permissions.SAFE_METHODS:
            return [IsManagerOrAdmin()]
        return [IsAdmin()]

    @action(detail=True, methods=["post"], permission_classes=[IsAdmin])
    def reset_password(self, request, pk=None):
        user = self.get_object()
        new_password = request.data.get("password")
        if not new_password:
            return Response(
                {"error": "Password is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            validate_password(new_password, user)
        except DjangoValidationError as exc:
            return Response(
                {"error": exc.messages}, status=status.HTTP_400_BAD_REQUEST
            )
        user.password = make_password(new_password)
        user.save(update_fields=["password"])
        return Response({"status": "password set"})


class VisitRecordViewSet(viewsets.ModelViewSet):
    serializer_class = VisitRecordSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OptionalPagination

    def get_queryset(self):
        return visible_visits(self.request.user).prefetch_related(
            "presented_products__product", "prescriptions__product"
        )

    def perform_create(self, serializer):
        product_ids = serializer.validated_data.pop("product_ids", [])
        order_items = serializer.validated_data.pop("order_items", [])
        visit = serializer.save(rep=self.request.user)
        self._link_target(visit)
        self._attach_products(visit, product_ids)
        self._attach_orders(visit, order_items)

    def perform_update(self, serializer):
        serializer.validated_data.pop("product_ids", None)
        serializer.validated_data.pop("order_items", None)
        visit = serializer.save()
        self._link_target(visit)

    # ── helpers ─────────────────────────────────────────────────────────────
    def _link_target(self, visit):
        """Attach (or create) the Doctor / Pharmacy this visit is about."""
        if visit.visit_type == VisitType.MEDICAL and not visit.doctor_id:
            doctor, _ = Doctor.objects.get_or_create(
                normalized_name=normalize_name(visit.target_name),
                wilaya=visit.wilaya,
                defaults=dict(
                    name=visit.target_name,
                    gender=visit.gender or "",
                    specialty=visit.specialty or "",
                    structure_type=visit.structure_type,
                    potential=visit.potential,
                    gco_status=visit.gco_status,
                    address=visit.address,
                    commune=visit.commune,
                    telephone=visit.telephone,
                    email=visit.email,
                    owner=visit.rep,
                ),
            )
            visit.doctor = doctor
            visit.save(update_fields=["doctor"])
        elif visit.visit_type == VisitType.PHARMACEUTICAL and not visit.pharmacy_id:
            pharmacy, _ = Pharmacy.objects.get_or_create(
                normalized_name=normalize_name(visit.target_name),
                wilaya=visit.wilaya,
                defaults=dict(
                    name=visit.target_name,
                    structure_type=visit.structure_type,
                    potential=visit.potential,
                    address=visit.address,
                    commune=visit.commune,
                    telephone=visit.telephone,
                    email=visit.email,
                    owner=visit.rep,
                ),
            )
            visit.pharmacy = pharmacy
            visit.save(update_fields=["pharmacy"])

    def _attach_products(self, visit, product_ids):
        for pid in product_ids:
            VisitProduct.objects.get_or_create(visit=visit, product_id=pid)

    def _attach_orders(self, visit, order_items):
        for item in order_items:
            Prescription.objects.create(
                visit=visit,
                doctor=visit.doctor,
                pharmacy=visit.pharmacy,
                rep=visit.rep,
                product_id=item.get("product"),
                quantity=int(item.get("quantity") or 0),
                status=item.get("status") or PrescriptionStatus.PENDING,
                note=item.get("note") or "",
            )


class LocalityViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Locality.objects.all()
    serializer_class = LocalitySerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        qs = super().get_queryset()
        wilaya = self.request.query_params.get("wilaya")
        if wilaya:
            qs = qs.filter(nom_wilaya__iexact=wilaya)
        return qs.order_by("nom_wilaya", "nom_commune")


class WilayaListView(APIView):
    """Distinct wilaya names — cheaper than pulling the whole locality table
    just to `.toSet()` it on the client (see inconsistencies.md §1.6)."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        names = (
            Locality.objects.values_list("nom_wilaya", flat=True)
            .distinct()
            .order_by("nom_wilaya")
        )
        return Response(sorted(n for n in names if n))


class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer

    def get_permissions(self):
        if self.request.method in permissions.SAFE_METHODS:
            return [permissions.IsAuthenticated()]
        return [IsAdmin()]


class ObjectiveViewSet(viewsets.ModelViewSet):
    serializer_class = ObjectiveSerializer

    def get_permissions(self):
        if self.request.method in permissions.SAFE_METHODS:
            return [permissions.IsAuthenticated()]
        return [IsAdmin()]

    def get_queryset(self):
        qs = Objective.objects.select_related("rep")
        user = self.request.user
        if user.is_staff_role:
            rep = self.request.query_params.get("rep")
            return qs.filter(rep_id=rep) if rep else qs
        return qs.filter(rep=user)


class DoctorViewSet(viewsets.ModelViewSet):
    serializer_class = DoctorSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OptionalPagination

    def get_queryset(self):
        return (
            visible_doctors(self.request.user)
            .annotate(
                visit_count=Count("visits", distinct=True),
                last_visit_date=Max("visits__date"),
            )
            .order_by("name")
        )

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    @action(detail=True, methods=["get"])
    def history(self, request, pk=None):
        doctor = self.get_object()
        visits = (
            doctor.visits.select_related("rep")
            .prefetch_related("presented_products__product", "prescriptions__product")
            .order_by("-date", "-created_at")
        )
        prescriptions = doctor.prescriptions.select_related("product", "rep")

        material = visits.aggregate(
            vials=Sum("qty_vials"),
            meters=Sum("qty_meters"),
            readers=Sum("qty_reader"),
            brochure_m=Sum("qty_brochure_m"),
            brochure_patient=Sum("qty_brochure_patient"),
            affiche=Sum("qty_affiche"),
        )
        products_presented = sorted(
            {
                vp.product.name
                for v in visits
                for vp in v.presented_products.all()
            }
        )
        summary = {
            "doctor": DoctorSerializer(doctor).data,
            "visit_count": visits.count(),
            "last_visit_date": visits.first().date if visits.exists() else None,
            "first_visit_date": visits.last().date if visits.exists() else None,
            "products_presented": products_presented,
            "material_given": {k: (v or 0) for k, v in material.items()},
            "orders": PrescriptionSerializer(prescriptions, many=True).data,
            "orders_count": prescriptions.count(),
            "remarks": [
                {"date": v.date, "text": v.comment, "rep": v.rep.username}
                for v in visits
                if v.comment
            ],
            "objections": [
                {"date": v.date, "text": v.objections, "rep": v.rep.username}
                for v in visits
                if v.objections
            ],
            "next_action": next(
                (
                    {
                        "date": v.next_action_date,
                        "text": v.next_action,
                        "logged_on": v.date,
                    }
                    for v in visits
                    if v.next_action
                ),
                None,
            ),
            "visits": VisitRecordSerializer(visits, many=True).data,
        }
        return Response(summary)


class PharmacyViewSet(viewsets.ModelViewSet):
    serializer_class = PharmacySerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OptionalPagination

    def get_queryset(self):
        return (
            visible_pharmacies(self.request.user)
            .annotate(
                visit_count=Count("visits", distinct=True),
                last_visit_date=Max("visits__date"),
            )
            .order_by("name")
        )

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    @action(detail=True, methods=["get"])
    def history(self, request, pk=None):
        pharmacy = self.get_object()
        visits = pharmacy.visits.select_related("rep").order_by("-date")
        prescriptions = pharmacy.prescriptions.select_related("product", "rep")
        return Response(
            {
                "pharmacy": PharmacySerializer(pharmacy).data,
                "visit_count": visits.count(),
                "last_visit_date": visits.first().date if visits.exists() else None,
                "orders": PrescriptionSerializer(prescriptions, many=True).data,
                "orders_count": prescriptions.count(),
                "last_order_date": prescriptions.aggregate(m=Max("created_at"))["m"],
                "visits": VisitRecordSerializer(visits, many=True).data,
            }
        )


# ── analytics ────────────────────────────────────────────────────────────────
def _window_counts(visits):
    today = _today()
    return {
        "today": visits.filter(date=today).count(),
        "week": visits.filter(date__gte=_week_start(today)).count(),
        "month": visits.filter(date__gte=_month_start(today)).count(),
        "total": visits.count(),
    }


def _objective_attainment(reps, start):
    """Actual vs. targeted visits for the weekly objectives starting `start`."""
    objs = Objective.objects.filter(
        rep__in=reps, period_type="weekly", period_start=start
    )
    target = objs.aggregate(t=Sum("visits_target"))["t"] or 0
    if not target:
        return None
    actual = VisitRecord.objects.filter(
        rep__in=reps, date__gte=start, date__lte=start + datetime.timedelta(days=6)
    ).count()
    return {
        "target": target,
        "actual": actual,
        "pct": round(actual / target * 100, 1),
    }


class ManagerDashboardView(APIView):
    permission_classes = [IsManagerOrAdmin]

    def get(self, request):
        today = _today()
        month0 = _month_start(today)
        visits = visible_visits(request.user)
        month_visits = visits.filter(date__gte=month0)
        reps = managed_reps(request.user)

        total_doctors = Doctor.objects.count()
        total_pharmacies = Pharmacy.objects.count()
        covered_doctors = (
            visits.filter(doctor__isnull=False)
            .values("doctor_id")
            .distinct()
            .count()
        )
        covered_pharmacies = (
            visits.filter(pharmacy__isnull=False)
            .values("pharmacy_id")
            .distinct()
            .count()
        )
        new_doctors_month = Doctor.objects.filter(
            created_at__date__gte=month0
        ).count()

        material = month_visits.aggregate(
            vials=Sum("qty_vials"),
            meters=Sum("qty_meters"),
            readers=Sum("qty_reader"),
            brochure_m=Sum("qty_brochure_m"),
            brochure_patient=Sum("qty_brochure_patient"),
            affiche=Sum("qty_affiche"),
        )
        promo_total = sum(v or 0 for v in material.values())
        orders_month = Prescription.objects.filter(created_at__date__gte=month0)

        return Response(
            {
                "generated_at": timezone.now(),
                "visits": _window_counts(visits),
                "avg_visit_duration": round(
                    month_visits.aggregate(a=Avg("duration_minutes"))["a"] or 0, 1
                ),
                "objective_attainment": _objective_attainment(
                    reps, _week_start(today)
                ),
                "doctor_coverage": {
                    "covered": covered_doctors,
                    "total": total_doctors,
                    "pct": round(covered_doctors / total_doctors * 100, 1)
                    if total_doctors
                    else 0.0,
                },
                "pharmacy_coverage": {
                    "covered": covered_pharmacies,
                    "total": total_pharmacies,
                    "pct": round(covered_pharmacies / total_pharmacies * 100, 1)
                    if total_pharmacies
                    else 0.0,
                },
                "new_doctors_month": new_doctors_month,
                "promo_material": {
                    "total": promo_total,
                    "breakdown": {k: (v or 0) for k, v in material.items()},
                },
                "orders": {
                    "month": orders_month.count(),
                    "by_status": {
                        row["status"]: row["c"]
                        for row in orders_month.values("status").annotate(
                            c=Count("id")
                        )
                    },
                },
                "by_visit_type": {
                    row["visit_type"]: row["c"]
                    for row in month_visits.values("visit_type").annotate(
                        c=Count("id")
                    )
                },
                "by_potential": {
                    row["potential"]: row["c"]
                    for row in month_visits.values("potential").annotate(
                        c=Count("id")
                    )
                },
                "active_reps": reps.filter(is_active=True).count(),
            }
        )


def _rep_stats(rep, viewer):
    today = _today()
    week0 = _week_start(today)
    month0 = _month_start(today)
    visits = VisitRecord.objects.filter(rep=rep)
    month_visits = visits.filter(date__gte=month0)

    scoped_doctor_total = Doctor.objects.count()
    covered = (
        visits.filter(doctor__isnull=False).values("doctor_id").distinct().count()
    )
    weekly_obj = Objective.objects.filter(
        rep=rep, period_type="weekly", period_start=week0
    ).first()
    week_visits = visits.filter(date__gte=week0).count()
    orders_month = Prescription.objects.filter(
        rep=rep, created_at__date__gte=month0
    ).count()

    objective_pct = None
    if weekly_obj and weekly_obj.visits_target:
        objective_pct = round(week_visits / weekly_obj.visits_target * 100, 1)

    coverage_pct = (
        round(covered / scoped_doctor_total * 100, 1)
        if scoped_doctor_total
        else 0.0
    )
    return {
        "rep": rep.id,
        "username": rep.username,
        "role": rep.role,
        "territory": rep.territory.name if rep.territory_id else rep.assigned_regions,
        "visits_today": visits.filter(date=today).count(),
        "visits_week": week_visits,
        "visits_month": month_visits.count(),
        "objective": {
            "target": weekly_obj.visits_target if weekly_obj else None,
            "actual": week_visits,
            "pct": objective_pct,
        },
        "coverage_pct": coverage_pct,
        "orders_month": orders_month,
        "new_doctors_month": Doctor.objects.filter(
            owner=rep, created_at__date__gte=month0
        ).count(),
        "avg_duration": round(
            month_visits.aggregate(a=Avg("duration_minutes"))["a"] or 0, 1
        ),
    }


class DelegateStatsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        rep = request.user
        rep_id = request.query_params.get("rep")
        if rep_id and request.user.is_staff_role:
            rep = User.objects.get(pk=rep_id)
        elif rep_id and str(request.user.id) != str(rep_id):
            return Response({"detail": "Forbidden"}, status=403)
        return Response(_rep_stats(rep, request.user))


class LeaderboardView(APIView):
    permission_classes = [IsManagerOrAdmin]

    WEIGHTS = {
        "visits": 0.35,
        "objective": 0.30,
        "coverage": 0.20,
        "orders": 0.15,
    }

    def get(self, request):
        reps = managed_reps(request.user).filter(is_active=True)
        rows = [_rep_stats(r, request.user) for r in reps]
        if not rows:
            return Response({"weights": self.WEIGHTS, "ranking": []})

        max_visits = max((r["visits_month"] for r in rows), default=0) or 1
        max_orders = max((r["orders_month"] for r in rows), default=0) or 1
        for r in rows:
            obj_pct = (r["objective"]["pct"] or 0) / 100
            r["score"] = round(
                self.WEIGHTS["visits"] * (r["visits_month"] / max_visits)
                + self.WEIGHTS["objective"] * min(obj_pct, 1.5)
                + self.WEIGHTS["coverage"] * (r["coverage_pct"] / 100)
                + self.WEIGHTS["orders"] * (r["orders_month"] / max_orders),
                4,
            )
        rows.sort(key=lambda r: r["score"], reverse=True)
        for i, r in enumerate(rows, 1):
            r["rank"] = i
        return Response({"weights": self.WEIGHTS, "ranking": rows})


class AlertsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        today = _today()
        p = request.query_params
        doctor_months = int(p.get("doctor_months", 3))
        pharmacy_days = int(p.get("pharmacy_days", 60))
        kol_days = int(p.get("kol_days", 90))

        doctor_cutoff = today - datetime.timedelta(days=doctor_months * 30)
        kol_cutoff = today - datetime.timedelta(days=kol_days)
        pharmacy_cutoff = timezone.now() - datetime.timedelta(days=pharmacy_days)

        doctors = visible_doctors(request.user).annotate(
            last_visit=Max("visits__date")
        )
        pharmacies = visible_pharmacies(request.user).annotate(
            last_order=Max("prescriptions__created_at")
        )

        alerts = []
        for d in doctors:
            if d.potential == TargetPotential.KOL:
                if d.last_visit is None or d.last_visit < kol_cutoff:
                    alerts.append(
                        _alert(
                            "kol_stale",
                            "high",
                            f"KOL non revu : {d.name}",
                            f"Dernière visite : {d.last_visit or '—'}",
                            "doctor",
                            d.id,
                            d.last_visit,
                        )
                    )
            elif d.last_visit is None or d.last_visit < doctor_cutoff:
                alerts.append(
                    _alert(
                        "doctor_stale",
                        "medium",
                        f"Médecin non visité : {d.name}",
                        f"Dernière visite : {d.last_visit or '—'} "
                        f"(seuil {doctor_months} mois)",
                        "doctor",
                        d.id,
                        d.last_visit,
                    )
                )
        for ph in pharmacies:
            if ph.last_order is None or ph.last_order < pharmacy_cutoff:
                alerts.append(
                    _alert(
                        "pharmacy_no_order",
                        "medium",
                        f"Pharmacie sans commande : {ph.name}",
                        f"Dernière commande : "
                        f"{ph.last_order.date() if ph.last_order else '—'} "
                        f"(seuil {pharmacy_days} j)",
                        "pharmacy",
                        ph.id,
                        ph.last_order.date() if ph.last_order else None,
                    )
                )

        if request.user.is_staff_role:
            week0 = _week_start(today)
            for rep in managed_reps(request.user).filter(is_active=True):
                obj = Objective.objects.filter(
                    rep=rep, period_type="weekly", period_start=week0
                ).first()
                if not obj or not obj.visits_target:
                    continue
                done = VisitRecord.objects.filter(rep=rep, date__gte=week0).count()
                if done < obj.visits_target:
                    alerts.append(
                        _alert(
                            "objective_missed",
                            "high",
                            f"Objectif hebdo : {rep.username}",
                            f"{done}/{obj.visits_target} visites cette semaine",
                            "rep",
                            rep.id,
                            None,
                        )
                    )

        severity_rank = {"high": 0, "medium": 1, "low": 2}
        alerts.sort(key=lambda a: (severity_rank[a["severity"]], a["title"]))
        return Response({"count": len(alerts), "alerts": alerts})


def _alert(kind, severity, title, detail, entity_type, entity_id, ref_date):
    return {
        "type": kind,
        "severity": severity,
        "title": title,
        "detail": detail,
        "entity_type": entity_type,
        "entity_id": entity_id,
        "ref_date": ref_date,
    }


class MapAggregateView(APIView):
    """Visits rolled up per wilaya (and per commune) so the client can draw a
    graduated overlay instead of one pin per row (see inconsistencies.md §3.5)."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        visits = visible_visits(request.user)
        by_wilaya = (
            visits.values("wilaya")
            .annotate(
                count=Count("id"),
                reps=Count("rep", distinct=True),
                last_visit=Max("date"),
                kol=Count("id", filter=Q(potential=TargetPotential.KOL)),
                doctors=Count("doctor", distinct=True),
                pharmacies=Count("pharmacy", distinct=True),
            )
            .order_by("-count")
        )
        by_commune = (
            visits.values("wilaya", "commune")
            .annotate(count=Count("id"), last_visit=Max("date"))
            .order_by("-count")
        )
        return Response(
            {"by_wilaya": list(by_wilaya), "by_commune": list(by_commune)}
        )


# ── legacy KPI endpoint (kept for backwards compat) ──────────────────────────
class AdminKPIView(APIView):
    permission_classes = [IsManagerOrAdmin]

    def get(self, request):
        visits = VisitRecord.objects.all()
        by_type = {
            e["visit_type"]: e["c"]
            for e in visits.values("visit_type").annotate(c=Count("id"))
        }
        by_potential = {
            e["potential"]: e["c"]
            for e in visits.values("potential").annotate(c=Count("id"))
        }
        totals = visits.aggregate(
            total_vials=Sum("qty_vials"),
            total_readers=Sum("qty_reader"),
            total_visits=Count("id"),
        )
        return Response(
            {
                "total_visits": totals["total_visits"] or 0,
                "total_vials": totals["total_vials"] or 0,
                "total_readers": totals["total_readers"] or 0,
                "by_visit_type": by_type,
                "by_potential": by_potential,
                "active_reps": User.objects.filter(
                    role__in=[UserRole.MED_REP, UserRole.PHARMA_REP],
                    is_active=True,
                ).count(),
            }
        )


# ── exports ──────────────────────────────────────────────────────────────────
class BaseExportView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_isolated_data(self, request):
        return visible_visits(request.user)

    HEADERS = [
        "ID",
        "Date",
        "Rep",
        "Type",
        "Target",
        "Potential",
        "Structure",
        "Wilaya",
        "Vials",
    ]

    def row(self, record):
        return [
            record.id,
            record.date,
            record.rep.username,
            record.visit_type,
            record.target_name,
            record.potential,
            record.structure_type,
            record.wilaya,
            record.qty_vials,
        ]


class ExportCSVView(BaseExportView):
    def get(self, request):
        records = self.get_isolated_data(request)
        response = HttpResponse(content_type="text/csv")
        response["Content-Disposition"] = (
            'attachment; filename="visimed_export.csv"'
        )
        writer = csv.writer(response)
        writer.writerow(self.HEADERS)
        for record in records:
            writer.writerow(self.row(record))
        return response


class ExportExcelView(BaseExportView):
    def get(self, request):
        records = self.get_isolated_data(request)
        wb = Workbook()
        ws = wb.active
        ws.title = "Visits Report"
        ws.append(self.HEADERS)
        for record in records:
            ws.append([str(v) for v in self.row(record)])

        response = HttpResponse(
            content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        response["Content-Disposition"] = (
            'attachment; filename="visimed_export.xlsx"'
        )
        wb.save(response)
        return response


class ExportPDFView(BaseExportView):
    def get(self, request):
        records = self.get_isolated_data(request)
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter)
        story = []
        styles = getSampleStyleSheet()
        story.append(Paragraph("<b>VisiMed Activity Report</b>", styles["Title"]))

        data = [
            ["Date", "Representative", "Target Entity", "Type", "Potential", "Wilaya"]
        ]
        for record in records:
            data.append(
                [
                    str(record.date),
                    record.rep.username,
                    record.target_name[:20],
                    record.visit_type,
                    record.potential,
                    record.wilaya,
                ]
            )

        table = Table(data, colWidths=[65, 95, 130, 70, 55, 75])
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1A237E")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("BOTTOMPADDING", (0, 0), (-1, 0), 6),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                    ("FONTSIZE", (0, 0), (-1, -1), 9),
                ]
            )
        )
        story.append(table)
        doc.build(story)

        buffer.seek(0)
        response = HttpResponse(buffer, content_type="application/pdf")
        response["Content-Disposition"] = (
            'attachment; filename="visimed_export.pdf"'
        )
        return response
