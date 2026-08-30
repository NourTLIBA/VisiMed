import datetime

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from visimed.models import (
    Doctor,
    Objective,
    Pharmacy,
    Prescription,
    Product,
    UserRole,
    VisitRecord,
    VisitType,
)

User = get_user_model()


class BaseAPITest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.med_rep = User.objects.create_user(
            username="medrep_test",
            password="password123",
            role=UserRole.MED_REP,
            assigned_regions="Alger",
            email="medrep@test.dz",
            telephone="+213555111222",
        )
        self.other_rep = User.objects.create_user(
            username="medrep_other",
            password="password123",
            role=UserRole.MED_REP,
            assigned_regions="Oran",
        )
        self.manager = User.objects.create_user(
            username="manager_test",
            password="password123",
            role=UserRole.MANAGER,
            email="manager@test.dz",
        )
        self.admin = User.objects.create_superuser(
            username="admin_test",
            password="adminpassword",
            role=UserRole.ADMIN,
            email="admin@test.dz",
        )

    def auth(self, username, password):
        res = self.client.post(
            "/api/auth/login/",
            {"username": username, "password": password},
            format="json",
        )
        self.assertEqual(res.status_code, 200, res.data)
        self.client.credentials(HTTP_AUTHORIZATION="Token " + res.data["token"])
        return res.data

    def _visit_payload(self, **overrides):
        payload = {
            "date": "2026-08-20",
            "visit_type": "medical",
            "target_name": "Dr. Benali",
            "gender": "M",
            "specialty": "Diabétologie",
            "structure_type": "Cabinet Privé",
            "potential": "KOL",
            "gco_status": "Compte GCO créé",
            "address": "10 Rue Hassiba, Alger",
            "wilaya": "Alger",
            "commune": "Alger Centre",
            "telephone": "+213 21 00 11 22",
            "email": "dr.benali@visimed.dz",
            "patient_load": "16-30",
            "duration_minutes": 20,
            "qty_vials": 5,
            "qty_meters": 10,
            "comment": "Bon accueil.",
            "objections": "Prix jugé élevé.",
            "next_action": "Rappeler avec devis",
            "next_action_date": "2026-09-05",
        }
        payload.update(overrides)
        return payload


class AuthTests(BaseAPITest):
    def test_login_flow(self):
        data = self.auth("medrep_test", "password123")
        self.assertIn("token", data)
        self.assertEqual(data["user"]["username"], "medrep_test")
        self.assertEqual(data["user"]["role"], "med_rep")


class VisitTests(BaseAPITest):
    def test_create_visit_server_generates_id_and_links_doctor(self):
        self.auth("medrep_test", "password123")
        res = self.client.post(
            "/api/visits/", self._visit_payload(id="client-supplied"), format="json"
        )
        self.assertEqual(res.status_code, 201, res.data)
        # Client-supplied id is ignored (inconsistencies.md §1.2).
        self.assertNotEqual(res.data["id"], "client-supplied")
        visit = VisitRecord.objects.get(id=res.data["id"])
        self.assertEqual(visit.rep, self.med_rep)
        self.assertEqual(visit.qty_meters, 10)
        self.assertEqual(visit.objections, "Prix jugé élevé.")
        # Doctor auto-created and linked.
        self.assertIsNotNone(visit.doctor)
        self.assertEqual(visit.doctor.name, "Dr. Benali")
        self.assertEqual(Doctor.objects.count(), 1)

    def test_repeat_visit_reuses_same_doctor(self):
        self.auth("medrep_test", "password123")
        self.client.post("/api/visits/", self._visit_payload(), format="json")
        self.client.post(
            "/api/visits/",
            self._visit_payload(date="2026-08-25", target_name="dr benali"),
            format="json",
        )
        self.assertEqual(Doctor.objects.count(), 1)
        self.assertEqual(Doctor.objects.first().visits.count(), 2)

    def test_med_rep_cannot_log_pharma_visit(self):
        self.auth("medrep_test", "password123")
        res = self.client.post(
            "/api/visits/",
            self._visit_payload(visit_type="pharmaceutical"),
            format="json",
        )
        self.assertEqual(res.status_code, 400)

    def test_region_isolation(self):
        # medrep_test logs an Alger visit; other rep (Oran) shouldn't see it.
        self.auth("medrep_test", "password123")
        self.client.post("/api/visits/", self._visit_payload(), format="json")
        self.auth("medrep_other", "password123")
        res = self.client.get("/api/visits/?all=1")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data), 0)

    def test_manager_sees_all_visits(self):
        self.auth("medrep_test", "password123")
        self.client.post("/api/visits/", self._visit_payload(), format="json")
        self.auth("manager_test", "password123")
        res = self.client.get("/api/visits/?all=1")
        self.assertEqual(len(res.data), 1)


class DoctorHistoryTests(BaseAPITest):
    def test_history_endpoint_shape(self):
        self.auth("medrep_test", "password123")
        product = Product.objects.create(name="GlucoReader X1")
        self.client.post(
            "/api/visits/",
            self._visit_payload(
                product_ids=[product.id],
                order_items=[{"product": product.id, "quantity": 3}],
            ),
            format="json",
        )
        doctor = Doctor.objects.get()
        res = self.client.get(f"/api/doctors/{doctor.id}/history/")
        self.assertEqual(res.status_code, 200)
        body = res.data
        self.assertEqual(body["visit_count"], 1)
        self.assertEqual(body["products_presented"], ["GlucoReader X1"])
        self.assertEqual(body["material_given"]["meters"], 10)
        self.assertEqual(body["orders_count"], 1)
        self.assertEqual(body["objections"][0]["text"], "Prix jugé élevé.")
        self.assertEqual(body["next_action"]["text"], "Rappeler avec devis")


class DashboardTests(BaseAPITest):
    def test_manager_dashboard_requires_manager(self):
        self.auth("medrep_test", "password123")
        self.assertEqual(
            self.client.get("/api/dashboard/manager/").status_code, 403
        )
        self.auth("manager_test", "password123")
        res = self.client.get("/api/dashboard/manager/")
        self.assertEqual(res.status_code, 200)
        self.assertIn("doctor_coverage", res.data)
        self.assertIn("today", res.data["visits"])

    def test_leaderboard_ranks_reps(self):
        self.auth("medrep_test", "password123")
        for i in range(3):
            self.client.post(
                "/api/visits/",
                self._visit_payload(date=f"2026-08-{10 + i}", target_name=f"Dr X{i}"),
                format="json",
            )
        self.auth("manager_test", "password123")
        res = self.client.get("/api/dashboard/leaderboard/")
        self.assertEqual(res.status_code, 200)
        ranking = res.data["ranking"]
        self.assertTrue(ranking)
        self.assertEqual(ranking[0]["rank"], 1)

    def test_delegate_stats_self(self):
        self.auth("medrep_test", "password123")
        res = self.client.get("/api/dashboard/delegate/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["username"], "medrep_test")


class AlertTests(BaseAPITest):
    def test_stale_kol_alert(self):
        old = timezone.localdate() - datetime.timedelta(days=200)
        VisitRecord.objects.create(
            date=old,
            rep=self.med_rep,
            visit_type=VisitType.MEDICAL,
            target_name="Dr. Vieux KOL",
            specialty="Cardio",
            structure_type="CHU",
            potential="KOL",
            address="x",
            wilaya="Alger",
            commune="Alger Centre",
            telephone="0",
        )
        from visimed.management.commands.backfill_targets import Command

        Command().handle()
        self.auth("manager_test", "password123")
        res = self.client.get("/api/alerts/?kol_days=90")
        self.assertEqual(res.status_code, 200)
        kinds = {a["type"] for a in res.data["alerts"]}
        self.assertIn("kol_stale", kinds)

    def test_objective_missed_alert(self):
        Objective.objects.create(
            rep=self.med_rep,
            period_type="weekly",
            period_start=timezone.localdate()
            - datetime.timedelta(days=timezone.localdate().weekday()),
            visits_target=10,
        )
        self.auth("manager_test", "password123")
        res = self.client.get("/api/alerts/")
        kinds = {a["type"] for a in res.data["alerts"]}
        self.assertIn("objective_missed", kinds)


class PermissionTests(BaseAPITest):
    def test_only_admin_creates_products(self):
        self.auth("manager_test", "password123")
        res = self.client.post("/api/products/", {"name": "X"}, format="json")
        self.assertEqual(res.status_code, 403)
        self.auth("admin_test", "adminpassword")
        res = self.client.post("/api/products/", {"name": "X"}, format="json")
        self.assertEqual(res.status_code, 201)

    def test_password_reset_rejects_weak_password(self):
        self.auth("admin_test", "adminpassword")
        res = self.client.post(
            f"/api/representatives/{self.med_rep.id}/reset_password/",
            {"password": "123"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)

    def test_manager_cannot_delete_rep(self):
        self.auth("manager_test", "password123")
        res = self.client.delete(f"/api/representatives/{self.med_rep.id}/")
        self.assertEqual(res.status_code, 403)
