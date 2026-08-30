import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';

/// Manager dashboard — real-time performance indicators
/// (see inconsistencies.md §3.1). Covers: visits today/week/month, objective
/// attainment, doctor & pharmacy coverage, new doctors, average duration,
/// promotional material distributed and orders generated.
class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  late Future<ManagerDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.state.api.fetchManagerDashboard();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.state.api.fetchManagerDashboard());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _refresh,
      child: FutureBuilder<ManagerDashboard>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snap.hasError) {
            return ListView(children: [
              const SizedBox(height: 80),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Indicateurs indisponibles.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),
            ]);
          }
          final d = snap.data!;
          final objPct = d.objectiveAttainment.pct;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const DecoSectionTitle('Activité', icon: Icons.bolt_outlined),
              Row(
                children: [
                  Expanded(
                      child: DecoStat(
                          label: "Visites aujourd'hui",
                          value: '${d.visitsToday}',
                          icon: Icons.today_outlined,
                          color: AppTheme.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: DecoStat(
                          label: 'Cette semaine',
                          value: '${d.visitsWeek}',
                          icon: Icons.date_range_outlined,
                          color: AppTheme.jade)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: DecoStat(
                          label: 'Ce mois',
                          value: '${d.visitsMonth}',
                          icon: Icons.calendar_month_outlined,
                          color: AppTheme.gold)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: DecoStat(
                          label: 'Durée moyenne',
                          value: '${d.avgVisitDuration.toStringAsFixed(0)}′',
                          sub: 'par visite (mois)',
                          icon: Icons.timer_outlined,
                          color: AppTheme.pharmaceutical)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: DecoStat(
                          label: 'Nouveaux médecins',
                          value: '${d.newDoctorsMonth}',
                          sub: 'ce mois',
                          icon: Icons.person_add_alt_outlined,
                          color: AppTheme.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: DecoStat(
                          label: 'Délégués actifs',
                          value: '${d.activeReps}',
                          icon: Icons.groups_outlined,
                          color: AppTheme.jade)),
                ],
              ),

              const DecoSectionTitle('Objectifs & couverture',
                  icon: Icons.track_changes_outlined),
              DecoCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    DecoGauge(
                      value: objPct == null ? 0 : objPct / 100,
                      label: 'Réalisation\nobjectifs',
                      centerText: objPct == null
                          ? '—'
                          : '${objPct.toStringAsFixed(0)}%',
                      color: AppTheme.gold,
                      size: 104,
                    ),
                    DecoGauge(
                      value: d.doctorCoverage.pct / 100,
                      label: 'Couverture\nmédecins',
                      color: AppTheme.jade,
                      size: 104,
                    ),
                    DecoGauge(
                      value: d.pharmacyCoverage.pct / 100,
                      label: 'Couverture\npharmacies',
                      color: AppTheme.primary,
                      size: 104,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DecoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv('Médecins visités',
                        '${d.doctorCoverage.covered} / ${d.doctorCoverage.total}'),
                    _kv('Pharmacies visitées',
                        '${d.pharmacyCoverage.covered} / ${d.pharmacyCoverage.total}'),
                    if (objPct != null)
                      _kv('Objectif visites (semaine)',
                          '${d.objectiveAttainment.actual} / ${d.objectiveAttainment.target}')
                    else
                      _kv('Objectifs', 'Non définis'),
                  ],
                ),
              ),

              const DecoSectionTitle('Commandes générées',
                  icon: Icons.receipt_long_outlined),
              DecoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${d.ordersMonth}',
                            style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('commandes ce mois',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: d.ordersByStatus.entries
                          .map((e) => DecoChip(
                                '${_statusLabel(e.key)} · ${e.value}',
                                color: Deco.orderStatusColor(e.key),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const DecoSectionTitle('Matériel promotionnel distribué',
                  icon: Icons.card_giftcard_outlined),
              DecoCard(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${d.promoMaterialTotal} unités ce mois',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDark)),
                    ),
                    const SizedBox(height: 6),
                    ...(() {
                      final tot = d.promoBreakdown.values
                          .fold<int>(0, (a, b) => a + b);
                      return d.promoBreakdown.entries.map((e) => DecoBarRow(
                            label: _materialLabel(e.key),
                            value: e.value,
                            total: tot == 0 ? 1 : tot,
                            color: AppTheme.gold,
                          ));
                    })(),
                  ],
                ),
              ),

              const DecoSectionTitle('Répartition (ce mois)',
                  icon: Icons.pie_chart_outline),
              DecoCard(
                child: Column(
                  children: [
                    ...d.byVisitType.entries.map((e) => DecoBarRow(
                          label: e.key == 'medical' ? 'Médicale' : 'Pharmaceutique',
                          value: e.value,
                          total: d.visitsMonth == 0 ? 1 : d.visitsMonth,
                          color: e.key == 'medical'
                              ? AppTheme.medical
                              : AppTheme.pharmaceutical,
                        )),
                    const Divider(height: 20),
                    ...d.byPotential.entries.map((e) => DecoBarRow(
                          label: 'Potentiel ${e.key}',
                          value: e.value,
                          total: d.visitsMonth == 0 ? 1 : d.visitsMonth,
                          color: Deco.potentialColor(e.key),
                        )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
                child: Text(k,
                    style: TextStyle(
                        color: Colors.grey.shade700, fontSize: 13))),
            Text(v,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
          ],
        ),
      );

  String _statusLabel(String s) => const {
        'pending': 'En attente',
        'confirmed': 'Confirmée',
        'delivered': 'Livrée',
        'cancelled': 'Annulée',
      }[s] ??
      s;

  String _materialLabel(String s) => const {
        'vials': 'Flacons',
        'meters': 'Lecteurs (mètres)',
        'readers': 'Lecteurs',
        'brochure_m': 'Brochures médecin',
        'brochure_patient': 'Brochures patient',
        'affiche': 'Affiches',
      }[s] ??
      s;
}
