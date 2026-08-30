import 'package:flutter_test/flutter_test.dart';
import 'package:visimed/models/models.dart';

void main() {
  group('model parsing (new dashboard / history payloads)', () {
    test('ManagerDashboard.fromJson tolerates a full payload', () {
      final d = ManagerDashboard.fromJson({
        'visits': {'today': 2, 'week': 9, 'month': 40, 'total': 120},
        'avg_visit_duration': 27.5,
        'objective_attainment': {'target': 15, 'actual': 9, 'pct': 60.0},
        'doctor_coverage': {'covered': 30, 'total': 50, 'pct': 60.0},
        'pharmacy_coverage': {'covered': 8, 'total': 20, 'pct': 40.0},
        'new_doctors_month': 4,
        'promo_material': {
          'total': 88,
          'breakdown': {'vials': 40, 'meters': 20, 'affiche': 28},
        },
        'orders': {
          'month': 12,
          'by_status': {'pending': 5, 'confirmed': 7},
        },
        'by_visit_type': {'medical': 30, 'pharmaceutical': 10},
        'by_potential': {'KOL': 3, 'A': 12, 'B': 15, 'C': 10},
        'active_reps': 5,
      });
      expect(d.visitsWeek, 9);
      expect(d.objectiveAttainment.pct, 60.0);
      expect(d.doctorCoverage.total, 50);
      expect(d.ordersByStatus['confirmed'], 7);
      expect(d.promoMaterialTotal, 88);
    });

    test('ManagerDashboard.fromJson tolerates a missing objective', () {
      final d = ManagerDashboard.fromJson({
        'visits': {'today': 0, 'week': 0, 'month': 0, 'total': 0},
        'objective_attainment': null,
        'doctor_coverage': {'covered': 0, 'total': 0, 'pct': 0},
        'pharmacy_coverage': {'covered': 0, 'total': 0, 'pct': 0},
      });
      expect(d.objectiveAttainment.pct, isNull);
      expect(d.doctorCoverage.pct, 0);
    });

    test('DoctorHistory.fromJson parses notes, orders and next action', () {
      final h = DoctorHistory.fromJson({
        'doctor': {'id': 1, 'name': 'Dr. Test', 'potential': 'A'},
        'visit_count': 2,
        'last_visit_date': '2026-08-20',
        'products_presented': ['GlucoReader X1'],
        'material_given': {'vials': 5, 'meters': 3},
        'orders': [
          {'id': 1, 'product_name': 'X', 'quantity': 3, 'status': 'confirmed'}
        ],
        'orders_count': 1,
        'remarks': [
          {'date': '2026-08-20', 'text': 'Bon accueil', 'rep': 'medrep1'}
        ],
        'objections': [
          {'date': '2026-08-20', 'text': 'Prix élevé', 'rep': 'medrep1'}
        ],
        'next_action': {'date': '2026-09-05', 'text': 'Rappeler'},
        'visits': [],
      });
      expect(h.doctor.name, 'Dr. Test');
      expect(h.productsPresented.single, 'GlucoReader X1');
      expect(h.objections.single.text, 'Prix élevé');
      expect(h.nextActionText, 'Rappeler');
      expect(h.orders.single.status, 'confirmed');
    });

    test('LeaderboardRow.fromJson reads the nested objective pct', () {
      final r = LeaderboardRow.fromJson({
        'rank': 1,
        'username': 'medrep1',
        'visits_month': 20,
        'objective': {'target': 15, 'actual': 12, 'pct': 80.0},
        'coverage_pct': 55.0,
        'orders_month': 6,
        'score': 0.71,
      });
      expect(r.rank, 1);
      expect(r.objectivePct, 80.0);
      expect(r.coveragePct, 55.0);
    });

    test('VisitAlert.fromJson', () {
      final a = VisitAlert.fromJson({
        'type': 'kol_stale',
        'severity': 'high',
        'title': 'KOL non revu',
        'detail': '…',
        'entity_type': 'doctor',
        'entity_id': 7,
      });
      expect(a.severity, 'high');
      expect(a.entityId, 7);
    });
  });
}
