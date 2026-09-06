from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AdminKPIView,
    AlertsView,
    AuthTokenView,
    HealthView,
    LogoutView,
    DelegateAnalyticsView,
    DelegateStatsView,
    DoctorViewSet,
    ExportCSVView,
    ExportExcelView,
    ExportPDFView,
    LeaderboardView,
    LocalityViewSet,
    ManagerDashboardView,
    MapAggregateView,
    ObjectiveViewSet,
    PharmacyViewSet,
    ProductViewSet,
    RepresentativeCRUDViewSet,
    VisitRecordViewSet,
    WilayaListView,
)

router = DefaultRouter()
router.register(r"representatives", RepresentativeCRUDViewSet, basename="representative")
router.register(r"visits", VisitRecordViewSet, basename="visit")
router.register(r"localities", LocalityViewSet, basename="locality")
router.register(r"doctors", DoctorViewSet, basename="doctor")
router.register(r"pharmacies", PharmacyViewSet, basename="pharmacy")
router.register(r"products", ProductViewSet, basename="product")
router.register(r"objectives", ObjectiveViewSet, basename="objective")

urlpatterns = [
    path("health/", HealthView.as_view(), name="health"),
    path("auth/login/", AuthTokenView.as_view(), name="auth-login"),
    path("auth/logout/", LogoutView.as_view(), name="auth-logout"),
    path("exports/csv/", ExportCSVView.as_view(), name="export-csv"),
    path("exports/xlsx/", ExportExcelView.as_view(), name="export-xlsx"),
    path("exports/pdf/", ExportPDFView.as_view(), name="export-pdf"),
    path("admin/kpis/", AdminKPIView.as_view(), name="admin-kpis"),
    path("wilayas/", WilayaListView.as_view(), name="wilaya-list"),
    path("dashboard/manager/", ManagerDashboardView.as_view(), name="dashboard-manager"),
    path("dashboard/delegate/", DelegateStatsView.as_view(), name="dashboard-delegate"),
    path(
        "dashboard/delegate/analytics/",
        DelegateAnalyticsView.as_view(),
        name="dashboard-delegate-analytics",
    ),
    path("dashboard/leaderboard/", LeaderboardView.as_view(), name="dashboard-leaderboard"),
    path("alerts/", AlertsView.as_view(), name="alerts"),
    path("analytics/map/", MapAggregateView.as_view(), name="analytics-map"),
    path("", include(router.urls)),
]
