import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';
import 'visit_detail_screen.dart';

class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ValueListenableBuilder<List<VisitRecord>>(
      valueListenable: state.visits,
      builder: (context, visits, _) {
        if (visits.isEmpty) {
          return DecoEmpty(
            icon: Icons.event_note_outlined,
            title: l.noVisitsYet,
            message: l.tapBelowToLog,
          );
        }

        return RefreshIndicator(
          onRefresh: state.refreshAll,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
            itemCount: visits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _VisitCard(state: state, visit: visits[i]),
          ),
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
