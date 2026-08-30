import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'report_download.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
}

class ApiService {
  ApiService({String? baseUrl, this.onUnauthorized})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'VISIMED_API_URL',
              defaultValue: 'https://visimed-production.up.railway.app/api',
            );

  final String baseUrl;
  final void Function()? onUnauthorized;
  String? token;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
        if (token != null) 'Authorization': 'Token $token',
      };

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      _u('/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw Exception('Invalid credentials');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    token = data['token'] as String;
    return data;
  }

  // ── generic helpers ────────────────────────────────────────────────────────
  Future<dynamic> _get(String path) async {
    final response = await http.get(_u(path), headers: headers);
    _ensureOk(response);
    return jsonDecode(response.body);
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    return const [];
  }

  // ── visits ────────────────────────────────────────────────────────────────
  Future<List<VisitRecord>> fetchVisits() async {
    final data = await _get('/visits/?all=1');
    return _asList(data)
        .map((e) => VisitRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VisitRecord> createVisit(VisitRecord visit) async {
    final response = await http.post(
      _u('/visits/'),
      headers: headers,
      body: jsonEncode(visit.toJson()),
    );
    _ensureOk(response, expected: 201);
    return VisitRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // ── localities / wilayas ─────────────────────────────────────────────────
  Future<List<Locality>> fetchLocalities({String? wilaya}) async {
    final path = wilaya == null
        ? '/localities/'
        : '/localities/?wilaya=${Uri.encodeComponent(wilaya)}';
    final data = await _get(path);
    return _asList(data)
        .map((e) => Locality.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> fetchWilayas() async {
    final data = await _get('/wilayas/');
    return (data as List).map((e) => e.toString()).toList()..sort();
  }

  // ── doctors / pharmacies / products ──────────────────────────────────────
  Future<List<Doctor>> fetchDoctors() async {
    final data = await _get('/doctors/?all=1');
    return _asList(data)
        .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorHistory> fetchDoctorHistory(int id) async {
    final data = await _get('/doctors/$id/history/');
    return DoctorHistory.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Pharmacy>> fetchPharmacies() async {
    final data = await _get('/pharmacies/?all=1');
    return _asList(data)
        .map((e) => Pharmacy.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> fetchProducts() async {
    final data = await _get('/products/');
    return _asList(data)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── dashboards / analytics ──────────────────────────────────────────────
  Future<ManagerDashboard> fetchManagerDashboard() async {
    final data = await _get('/dashboard/manager/');
    return ManagerDashboard.fromJson(data as Map<String, dynamic>);
  }

  Future<DelegateStats> fetchDelegateStats({int? repId}) async {
    final data = await _get(
      repId == null ? '/dashboard/delegate/' : '/dashboard/delegate/?rep=$repId',
    );
    return DelegateStats.fromJson(data as Map<String, dynamic>);
  }

  Future<List<LeaderboardRow>> fetchLeaderboard() async {
    final data = await _get('/dashboard/leaderboard/') as Map<String, dynamic>;
    return (data['ranking'] as List)
        .map((e) => LeaderboardRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VisitAlert>> fetchAlerts() async {
    final data = await _get('/alerts/') as Map<String, dynamic>;
    return (data['alerts'] as List)
        .map((e) => VisitAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WilayaAggregate>> fetchMapAggregate() async {
    final data = await _get('/analytics/map/') as Map<String, dynamic>;
    return (data['by_wilaya'] as List)
        .map((e) => WilayaAggregate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── admin ───────────────────────────────────────────────────────────────
  Future<AdminKpis> fetchAdminKpis() async {
    final data = await _get('/admin/kpis/');
    return AdminKpis.fromJson(data as Map<String, dynamic>);
  }

  Future<List<AppUser>> fetchRepresentatives() async {
    final data = await _get('/representatives/');
    return _asList(data)
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppUser> createRepresentative(Map<String, dynamic> payload) async {
    final response = await http.post(
      _u('/representatives/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    _ensureOk(response, expected: 201);
    return AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<AppUser> updateRepresentative(
      int id, Map<String, dynamic> payload) async {
    final response = await http.patch(
      _u('/representatives/$id/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    _ensureOk(response);
    return AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> resetRepresentativePassword(int id, String newPassword) async {
    final response = await http.post(
      _u('/representatives/$id/reset_password/'),
      headers: headers,
      body: jsonEncode({'password': newPassword}),
    );
    _ensureOk(response);
  }

  Future<void> deleteRepresentative(int id) async {
    final response = await http.delete(
      _u('/representatives/$id/'),
      headers: headers,
    );
    _ensureOk(response, expected: 204);
  }

  // ── exports ─────────────────────────────────────────────────────────────
  Future<String> downloadReport(String format) async {
    final ext = format == 'xlsx' ? 'xlsx' : format;
    final response = await http.get(_u('/exports/$format/'), headers: headers);
    if (response.statusCode == 200) {
      return saveReport(response.bodyBytes, 'visimed_report.$ext');
    }
    _ensureOk(response);
    throw Exception('Export pipeline failed to communicate with backend.');
  }

  void _ensureOk(http.Response response, {int expected = 200}) {
    if (response.statusCode == 401) {
      // A 401 with no token in hand is not a session expiry (e.g. demo mode
      // hitting a protected endpoint) — don't force a logout.
      if (token != null && onUnauthorized != null) onUnauthorized!();
      throw UnauthorizedException('Session expired. Please log in again.');
    }
    if (response.statusCode != expected) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }
}
