import 'package:flutter/material.dart';

import '../models/models.dart';

/// A set of visit filters shared across the Visites list, Médecins list and the
/// Statistiques screen. Applied client-side against the already-loaded visit
/// list, and serialised to query params for the analytics endpoint.
@immutable
class VisitFilter {
  const VisitFilter({
    this.range,
    this.wilaya,
    this.type,
    this.potentials = const {},
    this.query = '',
  });

  final DateTimeRange? range;
  final String? wilaya;
  final VisitType? type;
  final Set<TargetPotential> potentials;
  final String query;

  bool get isEmpty =>
      range == null &&
      wilaya == null &&
      type == null &&
      potentials.isEmpty &&
      query.trim().isEmpty;

  /// Number of active facets — for the "Filtres (n)" badge.
  int get activeCount =>
      (range == null ? 0 : 1) +
      (wilaya == null ? 0 : 1) +
      (type == null ? 0 : 1) +
      (potentials.isEmpty ? 0 : 1) +
      (query.trim().isEmpty ? 0 : 1);

  VisitFilter copyWith({
    DateTimeRange? range,
    String? wilaya,
    VisitType? type,
    Set<TargetPotential>? potentials,
    String? query,
    bool clearRange = false,
    bool clearWilaya = false,
    bool clearType = false,
  }) {
    return VisitFilter(
      range: clearRange ? null : (range ?? this.range),
      wilaya: clearWilaya ? null : (wilaya ?? this.wilaya),
      type: clearType ? null : (type ?? this.type),
      potentials: potentials ?? this.potentials,
      query: query ?? this.query,
    );
  }

  bool matches(VisitRecord v) {
    if (type != null && v.visitType != type) return false;
    if (potentials.isNotEmpty && !potentials.contains(v.potential)) return false;
    if (wilaya != null &&
        v.wilaya.toLowerCase() != wilaya!.toLowerCase()) {
      return false;
    }
    if (range != null) {
      final d = DateTime(v.date.year, v.date.month, v.date.day);
      if (d.isBefore(range!.start) || d.isAfter(range!.end)) return false;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty && !v.targetName.toLowerCase().contains(q)) return false;
    return true;
  }

  Map<String, String> toQuery() {
    String d(DateTime x) =>
        '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    return {
      if (range != null) 'date_from': d(range!.start),
      if (range != null) 'date_to': d(range!.end),
      if (wilaya != null) 'wilaya': wilaya!,
      if (type != null) 'visit_type': type == VisitType.medical ? 'medical' : 'pharmaceutical',
      if (potentials.isNotEmpty)
        'potential': potentials
            .map((p) => p == TargetPotential.KOL ? 'KOL' : p.name)
            .join(','),
      if (query.trim().isNotEmpty) 'q': query.trim(),
    };
  }
}

/// One-tap ranges / shortcuts shown as chips on the filter bar.
enum FilterPreset { thisWeek, thisMonth, last90, myKol }

extension FilterPresetX on FilterPreset {
  String get label => switch (this) {
        FilterPreset.thisWeek => 'Cette semaine',
        FilterPreset.thisMonth => 'Ce mois',
        FilterPreset.last90 => '90 jours',
        FilterPreset.myKol => 'Mes KOL',
      };

  /// Apply this preset on top of an existing filter (toggles off if already on).
  VisitFilter applyTo(VisitFilter current) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case FilterPreset.thisWeek:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return current.copyWith(range: DateTimeRange(start: start, end: today));
      case FilterPreset.thisMonth:
        return current.copyWith(
            range: DateTimeRange(start: DateTime(now.year, now.month, 1), end: today));
      case FilterPreset.last90:
        return current.copyWith(
            range: DateTimeRange(
                start: today.subtract(const Duration(days: 90)), end: today));
      case FilterPreset.myKol:
        final on = current.potentials.length == 1 &&
            current.potentials.contains(TargetPotential.KOL);
        return current.copyWith(
            potentials: on ? const {} : const {TargetPotential.KOL});
    }
  }

  bool isActive(VisitFilter f) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case FilterPreset.myKol:
        return f.potentials.length == 1 &&
            f.potentials.contains(TargetPotential.KOL);
      case FilterPreset.thisWeek:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return f.range?.start == start && f.range?.end == today;
      case FilterPreset.thisMonth:
        return f.range?.start == DateTime(now.year, now.month, 1) &&
            f.range?.end == today;
      case FilterPreset.last90:
        return f.range?.start == today.subtract(const Duration(days: 90)) &&
            f.range?.end == today;
    }
  }
}
