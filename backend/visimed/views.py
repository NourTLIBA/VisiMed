import csv
import io

from django.db.models import Count, Q, Sum
from django.http import HttpResponse
from openpyxl import Workbook
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import Paragraph, SimpleDocTemplate, Table, TableStyle
from rest_framework import permissions, status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Locality, User, UserRole, VisitRecord
from .permissions import IsAdmin
from .serializers import (
    LocalitySerializer,
    UserProfileSerializer,
    UserSerializer,
    VisitRecordSerializer,
)


class AuthTokenView(ObtainAuthToken):
    """Login — returns token + user profile."""

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        token = Token.objects.get(key=response.data["token"])
        return Response(
            {
                "token": response.data["token"],
                "user": UserProfileSerializer(token.user).data,
            }
        )


class RepresentativeCRUDViewSet(viewsets.ModelViewSet):
    queryset = User.objects.exclude(role=UserRole.ADMIN)
    serializer_class = UserSerializer
    permission_classes = [IsAdmin]


class VisitRecordViewSet(viewsets.ModelViewSet):
    serializer_class = VisitRecordSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = VisitRecord.objects.select_related("rep")
        if user.role == UserRole.ADMIN:
            return qs.all()
        region_filter = self._region_filter(user)
        return qs.filter(Q(rep=user) | region_filter)

    def _region_filter(self, user):
        regions = [
            r.strip() for r in user.assigned_regions.split(",") if r.strip()
        ]
        if not regions:
            return Q(pk__in=[])
        q = Q()
        for region in regions:
            q |= Q(wilaya__icontains=region)
        return q

    def perform_create(self, serializer):
        serializer.save(rep=self.request.user)


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


class AdminKPIView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        visits = VisitRecord.objects.all()
        by_type = {}
        for entry in visits.values("visit_type").annotate(c=Count("id")):
            by_type[entry["visit_type"]] = entry["c"]

        by_potential = {}
        for entry in visits.values("potential").annotate(c=Count("id")):
            by_potential[entry["potential"]] = entry["c"]
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
                "active_reps": User.objects.exclude(role=UserRole.ADMIN)
                .filter(is_active=True)
                .count(),
            }
        )


class BaseExportView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_isolated_data(self, request):
        user = request.user
        if user.role == UserRole.ADMIN:
            return VisitRecord.objects.all().select_related("rep")
        return VisitRecord.objects.filter(rep=user).select_related("rep")

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
