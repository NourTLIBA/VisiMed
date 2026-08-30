import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';
import '../utils/geo.dart';

/// Interactive map. Two modes:
///  · "Points" — one marker per visit (legacy).
///  · "Par wilaya" — graduated symbols per wilaya so well-covered vs
///    under-covered sectors read at a glance (see inconsistencies.md §3.5).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.state});
  final AppState state;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _byWilaya = true;
  Future<List<WilayaAggregate>>? _aggFuture;

  @override
  void initState() {
    super.initState();
    _aggFuture = widget.state.api.fetchMapAggregate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              _seg('Par wilaya', _byWilaya, () => setState(() => _byWilaya = true)),
              const SizedBox(width: 8),
              _seg('Points', !_byWilaya, () => setState(() => _byWilaya = false)),
            ],
          ),
        ),
        if (!_byWilaya) _FilterChips(state: widget.state),
        const Divider(height: 1),
        Expanded(
          child: _byWilaya ? _buildWilaya() : _buildPoints(),
        ),
      ],
    );
  }

  Widget _seg(String label, bool sel, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: sel ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.gold.withAlpha(sel ? 255 : 90)),
            ),
            child: Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: sel ? Colors.white : AppTheme.primary)),
          ),
        ),
      );

  // ── points mode ─────────────────────────────────────────────────────────
  Widget _buildPoints() {
    return ValueListenableBuilder<List<VisitRecord>>(
      valueListenable: widget.state.visits,
      builder: (context, _, __) {
        return ListenableBuilder(
          listenable: Listenable.merge(
              [widget.state.potentialFilter, widget.state.typeFilter]),
          builder: (context, _) {
            final markers = widget.state.filteredVisits.map((v) {
              final pos = resolveVisitPosition(v.wilaya, v.commune);
              return Marker(
                point: pos,
                width: 36,
                height: 36,
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
                  initialCenter: kAlgeriaCenter, initialZoom: 5.4),
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
    );
  }

  // ── wilaya mode ─────────────────────────────────────────────────────────
  Widget _buildWilaya() {
    return FutureBuilder<List<WilayaAggregate>>(
      future: _aggFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        final data = snap.data!;
        final maxCount =
            data.fold<int>(1, (m, w) => math.max(m, w.count));
        final markers = data.map((w) {
          final center = wilayaCenter(w.wilaya);
          final t = w.count / maxCount;
          final size = 28.0 + t * 34.0;
          // More visits → greener (well covered); fewer → red (needs activity).
          final good = Color.lerp(AppTheme.vermillion, AppTheme.jade, t)!;
          return Marker(
            point: center,
            width: size,
            height: size,
            child: GestureDetector(
              onTap: () => _sheet(w),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: good.withAlpha(150),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.gold, width: 1.5),
                ),
                child: Text('${w.count}',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: size * 0.32)),
              ),
            ),
          );
        }).toList();

        return Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                  initialCenter: kAlgeriaCenter, initialZoom: 5.2),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dz.visimed',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: DecoCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppTheme.jade),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cercle vert = secteur bien couvert · rouge = à renforcer. '
                        'Touchez une wilaya pour le détail.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _sheet(WilayaAggregate w) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            Text(w.wilaya.toUpperCase(),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.primaryDark)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DecoStat(
                    label: 'Visites',
                    value: '${w.count}',
                    color: AppTheme.primary,
                    width: 150),
                DecoStat(
                    label: 'Délégués',
                    value: '${w.reps}',
                    color: AppTheme.jade,
                    width: 150),
                DecoStat(
                    label: 'Médecins',
                    value: '${w.doctors}',
                    color: AppTheme.gold,
                    width: 150),
                DecoStat(
                    label: 'Pharmacies',
                    value: '${w.pharmacies}',
                    color: AppTheme.pharmaceutical,
                    width: 150),
                DecoStat(
                    label: 'KOL',
                    value: '${w.kol}',
                    color: AppTheme.vermillion,
                    width: 150),
                DecoStat(
                    label: 'Dernière visite',
                    value: w.lastVisit == null
                        ? '—'
                        : w.lastVisit!.toString().split(' ').first,
                    color: AppTheme.primary,
                    width: 150),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.state});
  final AppState state;

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
                _chip(
                  label: 'Tous',
                  selected: state.typeFilter.value == null,
                  color: AppTheme.primary,
                  onTap: () => state.typeFilter.value = null,
                ),
                const SizedBox(width: 6),
                _chip(
                  label: 'Médical',
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
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 20,
                  color: const Color(0xFFDDE2F0),
                ),
                ..._potentials.map((p) {
                  final active = state.potentialFilter.value == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _chip(
                      label: p.name,
                      selected: active,
                      color: AppTheme.potentialAccent(p),
                      onTap: () =>
                          state.potentialFilter.value = active ? null : p,
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
