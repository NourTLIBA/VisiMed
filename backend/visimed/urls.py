from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AdminKPIView,
    AuthTokenView,
    ExportCSVView,
    ExportExcelView,
    ExportPDFView,
    LocalityViewSet,
    RepresentativeCRUDViewSet,
    VisitRecordViewSet,
)

router = DefaultRouter()
router.register(r"representatives", RepresentativeCRUDViewSet, basename="representative")
router.register(r"visits", VisitRecordViewSet, basename="visit")
router.register(r"localities", LocalityViewSet, basename="locality")

urlpatterns = [
    path("auth/login/", AuthTokenView.as_view(), name="auth-login"),
    path("exports/csv/", ExportCSVView.as_view(), name="export-csv"),
    path("exports/xlsx/", ExportExcelView.as_view(), name="export-xlsx"),
    path("exports/pdf/", ExportPDFView.as_view(), name="export-pdf"),
    path("admin/kpis/", AdminKPIView.as_view(), name="admin-kpis"),
    path("", include(router.urls)),
]
