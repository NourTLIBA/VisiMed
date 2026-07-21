import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<VisitRecord>>(
      valueListenable: state.visits,
      builder: (context, visits, _) {
        if (visits.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_note_outlined,
                    size: 40,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.noVisitsYet,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.tapBelowToLog,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: state.refreshAll,
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: visits.length,
            itemBuilder: (context, i) {
              final v = visits[i];
              final typeColor = AppTheme.visitTypeColor(v.visitType);
              final potColor = AppTheme.potentialAccent(v.potential);

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {}, // placeholder for detail view
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // ── type avatar ──────────────────────────────
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: typeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            v.visitType == VisitType.medical
                                ? Icons.medical_services_outlined
                                : Icons.local_pharmacy_outlined,
                            color: typeColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // ── content ──────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.targetName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.primaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${v.wilaya} · ${v.commune}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 3),
                                  Text(
                                    v.date
                                        .toLocal()
                                        .toString()
                                        .split(' ')
                                        .first,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.timer_outlined,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${v.durationMinutes} min',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── potential badge ──────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: potColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: potColor.withAlpha(60),
                                    width: 1),
                              ),
                              child: Text(
                                v.potential.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: potColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: typeColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                v.visitType.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: typeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
