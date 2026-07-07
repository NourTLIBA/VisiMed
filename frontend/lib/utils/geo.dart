import 'package:latlong2/latlong.dart';

/// Static wilaya centroids for map rendering — no geocoding API needed.
const Map<String, LatLng> wilayaCentroids = {
  'Adrar': LatLng(27.8767, -0.2833),
  'Alger': LatLng(36.7538, 3.0588),
  'Annaba': LatLng(36.9000, 7.7667),
  'Blida': LatLng(36.4700, 2.8300),
  'Constantine': LatLng(36.3650, 6.6147),
  'Oran': LatLng(35.6969, -0.6331),
  'Mostaganem': LatLng(35.9311, 0.0892),
  'Sétif': LatLng(36.1911, 5.4137),
  'Tizi Ouzou': LatLng(36.7167, 4.0500),
  'Aïn Defla': LatLng(36.2642, 1.9678),
};

LatLng resolveVisitPosition(String wilaya, String commune) {
  final base = wilayaCentroids[wilaya] ?? const LatLng(28.0339, 1.6596);
  final offset = (commune.hashCode % 100) / 5000;
  return LatLng(base.latitude + offset, base.longitude + offset);
}
