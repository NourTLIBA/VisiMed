import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';
import 'doctor_detail_screen.dart';

/// Automatic alerts (see inconsistencies.md §3.6):
///  · médecin non visité depuis plusieurs mois
///  · pharmacie sans commande depuis une période définie
///  · KOL non revu depuis longtemps
///  · objectif hebdomadaire non atteint
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<VisitAlert>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.state.api.fetchAlerts();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.state.api.fetchAlerts());
    await _future;
  }

  IconData _icon(String type) {
    switch (type) {
      case 'kol_stale':
        return Icons.workspace_premium_outlined;
      case 'doctor_stale':
        return Icons.person_off_outlined;
      case 'pharmacy_no_order':
        return Icons.local_pharmacy_outlined;
      case 'objective_missed':
        return Icons.flag_outlined;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _refresh,
      child: FutureBuilder<List<VisitAlert>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snap.hasError) {
            return ListView(children: [
              const SizedBox(height: 90),
              Center(child: Text('${snap.error}')),
            ]);
          }
          final alerts = snap.data!;
          if (alerts.isEmpty) {
            return ListView(children: [
              const SizedBox(height: 120),
              Icon(Icons.verified_outlined,
                  size: 64, color: AppTheme.jade.withAlpha(120)),
              const SizedBox(height: 12),
              const Center(
                child: Text('Aucune alerte — tout est à jour.',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark)),
              ),
            ]);
          }
          final grouped = <String, int>{};
          for (final a in alerts) {
            grouped[a.severity] = (grouped[a.severity] ?? 0) + 1;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              DecoSectionTitle('${alerts.length} alerte(s)',
                  icon: Icons.notifications_active_outlined,
                  trailing: Wrap(
                    spacing: 6,
                    children: grouped.entries
                        .map((e) => DecoChip('${e.value}',
                            color: Deco.severityColor(e.key), filled: true))
                        .toList(),
                  )),
              ...alerts.map((a) {
                final c = Deco.severityColor(a.severity);
                final tappable =
                    a.entityType == 'doctor' && a.entityId != null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DecoCard(
                    onTap: tappable
                        ? () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => DoctorDetailScreen(
                                  state: widget.state, doctorId: a.entityId!),
                            ))
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: c.withAlpha(22),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: c.withAlpha(120)),
                          ),
                          child: Icon(_icon(a.type), color: c, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryDark)),
                              const SizedBox(height: 3),
                              Text(a.detail,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        if (tappable)
                          const Icon(Icons.chevron_right,
                              color: AppTheme.gold),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
