import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

/// Zero-overhead app state — ValueNotifier only, no third-party state libs.
class AppState {
  AppState({ApiService? api}) : api = api ?? ApiService();

  final ApiService api;

  final ValueNotifier<AppUser?> user = ValueNotifier(null);
  final ValueNotifier<List<VisitRecord>> visits = ValueNotifier([]);
  final ValueNotifier<List<Locality>> localities = ValueNotifier([]);
  final ValueNotifier<List<String>> wilayas = ValueNotifier([]);
  final ValueNotifier<AdminKpis?> kpis = ValueNotifier(null);
  final ValueNotifier<List<AppUser>> representatives = ValueNotifier([]);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  // Map filter chips — local slicing, no server round-trip.
  final ValueNotifier<TargetPotential?> potentialFilter = ValueNotifier(null);
  final ValueNotifier<VisitType?> typeFilter = ValueNotifier(null);

  Future<void> login(String username, String password) async {
    loading.value = true;
    error.value = null;
    try {
      final data = await api.login(username, password);
      user.value = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      await refreshAll();
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      loading.value = false;
    }
  }

  void logout() {
    api.token = null;
    user.value = null;
    visits.value = [];
    localities.value = [];
    wilayas.value = [];
    kpis.value = null;
    representatives.value = [];
    potentialFilter.value = null;
    typeFilter.value = null;
    error.value = null;
  }

  Future<void> refreshAll() async {
    loading.value = true;
    error.value = null;
    try {
      visits.value = await api.fetchVisits();
      wilayas.value = await api.fetchWilayas();
      localities.value = await api.fetchLocalities();
      if (user.value?.isAdmin ?? false) {
        kpis.value = await api.fetchAdminKpis();
        representatives.value = await api.fetchRepresentatives();
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> addVisit(VisitRecord visit) async {
    final created = await api.createVisit(visit);
    visits.value = [created, ...visits.value];
    if (user.value?.isAdmin ?? false) {
      kpis.value = await api.fetchAdminKpis();
    }
  }

  Future<void> loadCommunesForWilaya(String wilaya) async {
    localities.value = await api.fetchLocalities(wilaya: wilaya);
  }

  List<VisitRecord> get filteredVisits {
    return visits.value.where((v) {
      if (potentialFilter.value != null && v.potential != potentialFilter.value) {
        return false;
      }
      if (typeFilter.value != null && v.visitType != typeFilter.value) {
        return false;
      }
      return true;
    }).toList();
  }

  List<VisitRecord> visitsOnDay(DateTime day) {
    return visits.value.where((v) {
      return v.date.year == day.year &&
          v.date.month == day.month &&
          v.date.day == day.day;
    }).toList();
  }
}
