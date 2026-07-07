import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

class ApiService {
  ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'VISIMED_API_URL',
              defaultValue: 'http://127.0.0.1:8000/api',
            );

  final String baseUrl;
  String? token;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
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

  Future<List<VisitRecord>> fetchVisits() async {
    final response = await http.get(
      Uri.parse('$baseUrl/visits/'),
      headers: headers,
    );
    _ensureOk(response);
    final data = jsonDecode(response.body);
    final results = data is List ? data : data['results'] as List;
    return results
        .map((e) => VisitRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VisitRecord> createVisit(VisitRecord visit) async {
    final response = await http.post(
      Uri.parse('$baseUrl/visits/'),
      headers: headers,
      body: jsonEncode(visit.toJson()),
    );
    _ensureOk(response, expected: 201);
    return VisitRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Locality>> fetchLocalities({String? wilaya}) async {
    final uri = wilaya == null
        ? Uri.parse('$baseUrl/localities/')
        : Uri.parse('$baseUrl/localities/?wilaya=${Uri.encodeComponent(wilaya)}');
    final response = await http.get(uri, headers: headers);
    _ensureOk(response);
    final data = jsonDecode(response.body);
    final results = data is List ? data : data['results'] as List? ?? [];
    return results
        .map((e) => Locality.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> fetchWilayas() async {
    final localities = await fetchLocalities();
    return localities.map((l) => l.nomWilaya).toSet().toList()..sort();
  }

  Future<AdminKpis> fetchAdminKpis() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/kpis/'),
      headers: headers,
    );
    _ensureOk(response);
    return AdminKpis.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<AppUser>> fetchRepresentatives() async {
    final response = await http.get(
      Uri.parse('$baseUrl/representatives/'),
      headers: headers,
    );
    _ensureOk(response);
    final data = jsonDecode(response.body);
    final results = data is List ? data : data['results'] as List;
    return results
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppUser> createRepresentative(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/representatives/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    _ensureOk(response, expected: 201);
    return AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteRepresentative(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/representatives/$id/'),
      headers: headers,
    );
    _ensureOk(response, expected: 204);
  }

  Future<File> downloadReport(String format) async {
    final ext = format == 'xlsx' ? 'xlsx' : format;
    final response = await http.get(
      Uri.parse('$baseUrl/exports/$format/'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/visimed_report_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(response.bodyBytes);
      return file;
    }
    throw Exception('Export pipeline failed to communicate with backend.');
  }

  void _ensureOk(http.Response response, {int expected = 200}) {
    if (response.statusCode != expected) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }
}
