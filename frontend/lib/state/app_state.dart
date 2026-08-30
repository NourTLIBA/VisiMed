import 'dart:async';

import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Zero-overhead app state — ValueNotifier only, no third-party state libs.
class AppState {
  AppState({ApiService? api}) {
    this.api = api ?? ApiService(onUnauthorized: logout);
  }

  late final ApiService api;

  final ValueNotifier<AppUser?> user = ValueNotifier(null);
  final ValueNotifier<List<VisitRecord>> visits = ValueNotifier([]);
  final ValueNotifier<List<Locality>> localities = ValueNotifier([]);
  final ValueNotifier<List<String>> wilayas = ValueNotifier([]);
  final ValueNotifier<AdminKpis?> kpis = ValueNotifier(null);
  final ValueNotifier<List<AppUser>> representatives = ValueNotifier([]);
  final ValueNotifier<List<Doctor>> doctors = ValueNotifier([]);
  final ValueNotifier<List<Pharmacy>> pharmacies = ValueNotifier([]);
  final ValueNotifier<List<Product>> products = ValueNotifier([]);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  final ValueNotifier<Locale> currentLocale = ValueNotifier(const Locale('fr'));

  // Map filter chips — local slicing, no server round-trip.
  final ValueNotifier<TargetPotential?> potentialFilter = ValueNotifier(null);
  final ValueNotifier<VisitType?> typeFilter = ValueNotifier(null);

  Future<void> login(String username, String password) async {
    loading.value = true;
    error.value = null;
    try {
      // Phase 1: authenticate — if this throws, login genuinely failed
      final data = await api.login(username, password);
      user.value = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      // Auth failed — clear user and rethrow so the login screen shows the error
      user.value = null;
      error.value = e.toString();
      loading.value = false;
      rethrow;
    }

    // Phase 2: load data — errors here don't block login
    try {
      await refreshAll();
    } catch (_) {
      // Data loading failed but user is authenticated — silently continue
    } finally {
      loading.value = false;
    }
  }

  /// Loads demo data instantly — no network calls required.
  void loginDemo(AppUser demoUser) {
    user.value = demoUser;
    visits.value = List.of(kDemoVisits);
    wilayas.value = List.of(kDemoWilayas);
    localities.value = List.of(kDemoLocalities);
    doctors.value = List.of(kDemoDoctors);
    products.value = List.of(kDemoProducts);
    if (demoUser.isStaff) {
      kpis.value = kDemoKpis;
      representatives.value = List.of(kDemoRepresentatives);
    }
    error.value = null;
  }

  void logout() {
    api.token = null;
    user.value = null;
    visits.value = [];
    localities.value = [];
    wilayas.value = [];
    kpis.value = null;
    representatives.value = [];
    doctors.value = [];
    pharmacies.value = [];
    products.value = [];
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
      products.value = await api.fetchProducts();
      doctors.value = await api.fetchDoctors();
      pharmacies.value = await api.fetchPharmacies();
      if (user.value?.isStaff ?? false) {
        kpis.value = await api.fetchAdminKpis();
        representatives.value = await api.fetchRepresentatives();
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> reloadDoctors() async {
    try {
      doctors.value = await api.fetchDoctors();
    } catch (_) {/* keep stale list */}
  }

  Future<void> addVisit(VisitRecord visit) async {
    final created = await api.createVisit(visit);
    visits.value = [created, ...visits.value];
    // Refresh the target lists so a newly-created doctor/pharmacy shows up.
    unawaited(reloadDoctors());
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
