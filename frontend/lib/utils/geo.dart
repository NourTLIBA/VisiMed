import 'package:latlong2/latlong.dart';

/// Static wilaya centroids for map rendering — no geocoding API needed.
/// Full 58-wilaya table so visits outside the old 10-entry list no longer
/// pile onto the centre of the Sahara (see inconsistencies.md §3.5).
const Map<String, LatLng> wilayaCentroids = {
  'Adrar': LatLng(27.8743, -0.2939),
  'Chlef': LatLng(36.1653, 1.3345),
  'Laghouat': LatLng(33.8000, 2.8650),
  'Oum El Bouaghi': LatLng(35.8775, 7.1136),
  'Batna': LatLng(35.5550, 6.1741),
  'Béjaïa': LatLng(36.7515, 5.0567),
  'Bejaïa': LatLng(36.7515, 5.0567),
  'Biskra': LatLng(34.8500, 5.7280),
  'Béchar': LatLng(31.6167, -2.2167),
  'Blida': LatLng(36.4700, 2.8300),
  'Bouira': LatLng(36.3700, 3.9000),
  'Tamanrasset': LatLng(22.7850, 5.5228),
  'Tébessa': LatLng(35.4042, 8.1242),
  'Tlemcen': LatLng(34.8783, -1.3150),
  'Tiaret': LatLng(35.3711, 1.3170),
  'Tizi Ouzou': LatLng(36.7118, 4.0455),
  'Alger': LatLng(36.7538, 3.0588),
  'Djelfa': LatLng(34.6700, 3.2500),
  'Jijel': LatLng(36.8200, 5.7667),
  'Sétif': LatLng(36.1911, 5.4137),
  'Saïda': LatLng(34.8300, 0.1500),
  'Skikda': LatLng(36.8790, 6.9070),
  'Sidi Bel Abbès': LatLng(35.1878, -0.6308),
  'Annaba': LatLng(36.9000, 7.7667),
  'Guelma': LatLng(36.4625, 7.4262),
  'Constantine': LatLng(36.3650, 6.6147),
  'Médéa': LatLng(36.2642, 2.7539),
  'Mostaganem': LatLng(35.9311, 0.0892),
  "M'Sila": LatLng(35.7058, 4.5419),
  'Mascara': LatLng(35.3968, 0.1400),
  'Ouargla': LatLng(31.9490, 5.3255),
  'Oran': LatLng(35.6969, -0.6331),
  'El Bayadh': LatLng(33.6800, 1.0200),
  'Illizi': LatLng(26.4833, 8.4667),
  'Bordj Bou Arréridj': LatLng(36.0730, 4.7600),
  'Boumerdès': LatLng(36.7660, 3.4770),
  'El Tarf': LatLng(36.7672, 8.3136),
  'Tindouf': LatLng(27.6711, -8.1478),
  'Tissemsilt': LatLng(35.6072, 1.8106),
  'El Oued': LatLng(33.3562, 6.8631),
  'Khenchela': LatLng(35.4267, 7.1433),
  'Souk Ahras': LatLng(36.2864, 7.9511),
  'Tipaza': LatLng(36.5894, 2.4483),
  'Mila': LatLng(36.4503, 6.2647),
  'Aïn Defla': LatLng(36.2642, 1.9678),
  'Naâma': LatLng(33.2667, -0.3167),
  'Aïn Témouchent': LatLng(35.2989, -1.1400),
  'Ghardaïa': LatLng(32.4900, 3.6700),
  'Relizane': LatLng(35.7372, 0.5558),
  'Timimoun': LatLng(29.2639, 0.2306),
  'Bordj Badji Mokhtar': LatLng(21.3287, 0.9550),
  'Ouled Djellal': LatLng(34.4167, 5.0667),
  'Béni Abbès': LatLng(30.1300, -2.1700),
  'In Salah': LatLng(27.1936, 2.4783),
  'In Guezzam': LatLng(19.5686, 5.7719),
  'Touggourt': LatLng(33.1000, 6.0667),
  'Djanet': LatLng(24.5540, 9.4843),
  "El M'Ghair": LatLng(33.9500, 5.9167),
  'El Meniaa': LatLng(30.5833, 2.8833),
};

const LatLng kAlgeriaCenter = LatLng(28.0339, 1.6596);

/// Deterministic per-visit position: wilaya centroid plus a small,
/// stable offset derived from the commune's code points (no `String.hashCode`,
/// which is not stable across Dart builds — see inconsistencies.md §6.5).
LatLng resolveVisitPosition(String wilaya, String commune) {
  final base = wilayaCentroids[wilaya] ?? kAlgeriaCenter;
  final seed = commune.codeUnits.fold<int>(0, (a, c) => (a + c) % 400);
  final offset = (seed - 200) / 12000; // ±~0.016°
  return LatLng(base.latitude + offset, base.longitude - offset);
}

LatLng wilayaCenter(String wilaya) =>
    wilayaCentroids[wilaya] ?? kAlgeriaCenter;
