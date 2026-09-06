import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';
import '../widgets/filter_bar.dart';

/// "Statistiques" — filter-aware analytics over a rep's own visit history.
/// Used as the delegate's Perf tab (`embedded: true`) and pushed by a manager
/// from the leaderboard with a `repId`.
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.state,
    this.repId,
    this.embedded = false,
    this.title = 'Statistiques',
  });

  final AppState state;
  final int? repId;
  final bool embedded;
  final String title;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Future<DelegateAnalytics>? _future;
  String _key = '';

  @override
  void initState() {
    super.initState();
    widget.state.visitFilter.addListener(_onFilter);
    final q = widget.state.visitFilter.value.toQuery();
    _key = q.toString();
    _future =
        widget.state.api.fetchDelegateAnalytics(repId: widget.repId, query: q);
  }

  @override
  void dispose() {
    widget.state.visitFilter.removeListener(_onFilter);
    super.dispose();
  }

  void _onFilter() {
    final k = widget.state.visitFilter.value.toQuery().toString();
    if (k != _key) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    final q = widget.state.visitFilter.value.toQuery();
    _key = q.toString();
    setState(() {
      _future = widget.state.api
          .fetchDelegateAnalytics(repId: widget.repId, query: q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        FilterBar(state: widget.state),
        const SizedBox(height: 4),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: FutureBuilder<DelegateAnalytics>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ListView(children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Statistiques indisponibles.\n${snap.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.inkMuted)),
                      ),
                    ),
                  ]);
                }
                final a = snap.data!;
                if (a.isEmpty) {
                  return ListView(children: const [
                    SizedBox(height: 60),
                    DecoEmpty(
                      icon: Icons.insights_outlined,
                      title: 'Aucune visite',
                      message: 'Aucune donnée pour la période et les filtres choisis.',
                    ),
                  ]);
                }
                return _AnalyticsBody(a: a);
              },
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: body,
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.a});
  final DelegateAnalytics a;

  String _d(DateTime? x) => x == null
      ? '—'
      : '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';

  @override
  Widget build(BuildContext context) {
    final total = a.visits;
    final matLabels = {
      'vials': 'Flacons',
      'meters': 'Lecteurs (mètres)',
      'reader': 'Lecteurs',
      'brochure_m': 'Brochures médecin',
      'brochure_patient': 'Brochures patient',
      'affiche': 'Affiches',
    };
    final matEntries =
        a.materials.entries.where((e) => e.value > 0).toList()
          ..sort((x, y) => y.value.compareTo(x.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Text('Du ${_d(a.rangeFrom)} au ${_d(a.rangeTo)}',
            style: const TextStyle(fontSize: 12.5, color: AppTheme.inkFaint)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: DecoStat(
                    label: 'Visites',
                    value: '$total',
                    icon: Icons.article_outlined,
                    color: AppTheme.primary)),
            const SizedBox(width: 10),
            Expanded(
                child: DecoStat(
                    label: 'Médecins vus',
                    value: '${a.doctors}',
                    icon: Icons.folder_shared_outlined,
                    color: AppTheme.jade)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: DecoStat(
                    label: 'Commandes',
                    value: '${a.orders}',
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.accent)),
            const SizedBox(width: 10),
            Expanded(
                child: DecoStat(
                    label: 'Durée moyenne',
                    value: '${a.avgDuration.toStringAsFixed(0)}′',
                    sub: 'par visite',
                    icon: Icons.schedule_outlined,
                    color: AppTheme.gold)),
          ],
        ),

        const DecoSectionTitle('Activité hebdomadaire',
            icon: Icons.show_chart_rounded),
        DecoCard(child: _WeeklyBars(points: a.byWeek)),

        const DecoSectionTitle('Répartition', icon: Icons.pie_chart_outline),
        DecoCard(
          child: Column(
            children: [
              DecoBarRow(
                  label: 'Médicale',
                  value: a.byType['medical'] ?? 0,
                  total: total == 0 ? 1 : total,
                  color: AppTheme.medical),
              DecoBarRow(
                  label: 'Pharmaceutique',
                  value: a.byType['pharmaceutical'] ?? 0,
                  total: total == 0 ? 1 : total,
                  color: AppTheme.pharmaceutical),
              const Divider(height: 20),
              for (final k in const ['KOL', 'A', 'B', 'C'])
                DecoBarRow(
                  label: 'Potentiel $k',
                  value: a.byPotential[k] ?? 0,
                  total: total == 0 ? 1 : total,
                  color: Deco.potentialColor(k),
                ),
            ],
          ),
        ),

        if (matEntries.isNotEmpty) ...[
          const DecoSectionTitle('Matériel distribué',
              icon: Icons.card_giftcard_outlined),
          DecoCard(
            child: Column(
              children: [
                for (final e in matEntries)
                  DecoBarRow(
                    label: matLabels[e.key] ?? e.key,
                    value: e.value,
                    total: a.materialsTotal == 0 ? 1 : a.materialsTotal,
                    color: AppTheme.gold,
                  ),
              ],
            ),
          ),
        ],

        if (a.topWilayas.isNotEmpty) ...[
          const DecoSectionTitle('Top wilayas', icon: Icons.map_outlined),
          DecoCard(
            child: Column(
              children: [
                for (final w in a.topWilayas)
                  DecoBarRow(
                    label: w.wilaya,
                    value: w.count,
                    total: a.topWilayas.first.count,
                    color: AppTheme.primary,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Lightweight column chart — no chart dependency.
class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.points});
  final List<AnalyticsWeekPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(
            child: Text('—', style: TextStyle(color: AppTheme.inkFaint))),
      );
    }
    // Show at most the last 16 weeks so bars stay legible.
    final pts = points.length > 16
        ? points.sublist(points.length - 16)
        : points;
    final maxV = pts.fold<int>(1, (m, p) => p.count > m ? p.count : m);
    final labelEvery = (pts.length / 5).ceil().clamp(1, 99);

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < pts.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          pts[i].count == 0 ? '' : '${pts[i].count}',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.inkFaint),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: (pts[i].count / maxV) * 92 + (pts[i].count > 0 ? 4 : 1),
                          decoration: BoxDecoration(
                            color: pts[i].count == 0
                                ? AppTheme.surfaceAlt
                                : AppTheme.primary,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < pts.length; i++)
              Expanded(
                child: Text(
                  i % labelEvery == 0
                      ? '${pts[i].week.day}/${pts[i].week.month}'
                      : '',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 9.5, color: AppTheme.inkFaint),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
