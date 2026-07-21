from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient
from visimed.models import GCOStatus, TargetPotential, UserRole, VisitRecord, VisitType

User = get_user_model()


class VisiMedTestCase(TestCase):
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
        self.admin = User.objects.create_superuser(
            username="admin_test",
            password="adminpassword",
            role=UserRole.ADMIN,
            email="admin@test.dz",
        )

    def test_login_flow(self):
        """Test login endpoint and token generation"""
        res = self.client.post(
            "/api/auth/login/",
            {"username": "medrep_test", "password": "password123"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("token", res.data)
        self.assertEqual(res.data["user"]["username"], "medrep_test")

    def test_create_and_sync_visit(self):
        """Test visit creation with new fields (GCO status, qty meters, leave behind, doctor info, structure & location)"""
        # Login med_rep
        login_res = self.client.post(
            "/api/auth/login/",
            {"username": "medrep_test", "password": "password123"},
            format="json",
        )
        token = login_res.data["token"]
        self.client.credentials(HTTP_AUTHORIZATION="Token " + token)

        visit_payload = {
            "id": "test-v-001",
            "date": "2026-07-22",
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
            "qty_reader": 0,
            "qty_vials": 5,
            "qty_meters": 10,
            "qty_brochure_m": 2,
            "qty_brochure_patient": 15,
            "qty_affiche": 1,
            "comment": "Doctor trained and GCO account created.",
        }

        res = self.client.post("/api/visits/", visit_payload, format="json")
        self.assertEqual(res.status_code, 201)

        # Verify DB entry
        record = VisitRecord.objects.get(id="test-v-001")
        self.assertEqual(record.gco_status, "Compte GCO créé")
        self.assertEqual(record.qty_meters, 10)
        self.assertEqual(record.patient_load, "16-30")

        # Verify profile sync via list visits endpoint
        list_res = self.client.get("/api/visits/")
        self.assertEqual(list_res.status_code, 200)
        items = list_res.data["results"] if isinstance(list_res.data, dict) and "results" in list_res.data else list_res.data
        created_item = next(item for item in items if item["id"] == "test-v-001")
        self.assertEqual(created_item["gco_status"], "Compte GCO créé")
        self.assertEqual(created_item["qty_meters"], 10)
