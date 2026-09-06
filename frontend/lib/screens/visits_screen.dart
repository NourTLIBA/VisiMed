import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';
import '../widgets/filter_bar.dart';
import 'visit_detail_screen.dart';

class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: Listenable.merge([state.visits, state.visitFilter]),
      builder: (context, _) {
        final all = state.visits.value;
        final list = state.filteredVisits;

        Widget content;
        if (all.isEmpty) {
          content = DecoEmpty(
            icon: Icons.event_note_outlined,
            title: l.noVisitsYet,
            message: l.tapBelowToLog,
          );
        } else if (list.isEmpty) {
          content = ListView(children: const [
            SizedBox(height: 40),
            DecoEmpty(
              icon: Icons.filter_alt_off_outlined,
              title: 'Aucun résultat',
              message: 'Aucune visite ne correspond à ces filtres.',
            ),
          ]);
        } else {
          content = RefreshIndicator(
            onRefresh: state.refreshAll,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _VisitCard(state: state, visit: list[i]),
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 8),
            FilterBar(state: state),
            const Divider(height: 1),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.state, required this.visit});
  final AppState state;
  final VisitRecord visit;

  @override
  Widget build(BuildContext context) {
    final v = visit;
    final typeColor = AppTheme.visitTypeColor(v.visitType);
    final potColor = AppTheme.potentialAccent(v.potential);
    final isMed = v.visitType == VisitType.medical;

    return DecoCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => VisitDetailScreen(state: state, visit: v)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: typeColor.withAlpha(28),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMed
                  ? Icons.medical_services_outlined
                  : Icons.local_pharmacy_outlined,
              color: typeColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.targetName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (v.wilaya.isNotEmpty) v.wilaya,
                    if (v.commune.isNotEmpty) v.commune,
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppTheme.inkFaint),
                    const SizedBox(width: 4),
                    Text(
                      MaterialLocalizations.of(context)
                          .formatShortDate(v.date.toLocal()),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.inkFaint),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_outlined,
                        size: 12, color: AppTheme.inkFaint),
                    const SizedBox(width: 4),
                    Text('${v.durationMinutes} min',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.inkFaint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DecoChip(v.potential.name, color: potColor),
        ],
      ),
    );
  }
}
