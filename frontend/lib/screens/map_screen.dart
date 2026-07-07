import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/geo.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterChips(state: state),
        Expanded(
          child: ValueListenableBuilder<List<VisitRecord>>(
            valueListenable: state.visits,
            builder: (context, _, __) {
              return ListenableBuilder(
                listenable: Listenable.merge([
                  state.potentialFilter,
                  state.typeFilter,
                ]),
                builder: (context, _) {
                  final markers = state.filteredVisits.map((v) {
                    final pos = resolveVisitPosition(v.wilaya, v.commune);
                    return Marker(
                      point: pos,
                      width: 40,
                      height: 40,
                      child: Icon(
                        v.visitType == VisitType.medical
                            ? Icons.medical_services
                            : Icons.local_pharmacy,
                        color: AppTheme.visitTypeColor(v.visitType),
                      ),
                    );
                  }).toList();

                  return FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(28.0339, 1.6596),
                      initialZoom: 5.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'dz.visimed',
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.state});

  final AppState state;

  // Potentials shown in the map filter — KOL excluded per product decision
  static const _potentials = [
    TargetPotential.A,
    TargetPotential.B,
    TargetPotential.C,
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([state.typeFilter, state.potentialFilter]),
      builder: (context, _) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // ── visit type chips ──────────────────────────────────
                _chip(
                  label: 'All types',
                  selected: state.typeFilter.value == null,
                  color: AppTheme.primary,
                  onTap: () => state.typeFilter.value = null,
                ),
                const SizedBox(width: 6),
                _chip(
                  label: 'Medical',
                  selected: state.typeFilter.value == VisitType.medical,
                  color: AppTheme.medical,
                  onTap: () => state.typeFilter.value = VisitType.medical,
                ),
                const SizedBox(width: 6),
                _chip(
                  label: 'Pharma',
                  selected:
                      state.typeFilter.value == VisitType.pharmaceutical,
                  color: AppTheme.pharmaceutical,
                  onTap: () =>
                      state.typeFilter.value = VisitType.pharmaceutical,
                ),

                // ── divider ───────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 20,
                  color: const Color(0xFFDDE2F0),
                ),

                // ── potential chips (A / B / C only) ─────────────────
                ..._potentials.map((p) {
                  final active = state.potentialFilter.value == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _chip(
                      label: p.name,
                      selected: active,
                      color: AppTheme.potentialAccent(p),
                      onTap: () => state.potentialFilter.value =
                          active ? null : p,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withAlpha(50),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
