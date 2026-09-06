import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/app_localizations.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'visit_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.state});

  final AppState state;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<VisitRecord>>(
      valueListenable: widget.state.visits,
      builder: (context, visits, _) {
        return Column(
          children: [
            TableCalendar<VisitRecord>(
              locale: Localizations.localeOf(context).languageCode,
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focused,
              selectedDayPredicate: (day) => isSameDay(_selected, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selected = selected;
                  _focused = focused;
                });
              },
              onPageChanged: (focused) => _focused = focused,
              eventLoader: widget.state.visitsOnDay,
              calendarStyle: CalendarStyle(
                markerDecoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(28),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w700),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: AppTheme.inkFaint),
                outsideTextStyle: const TextStyle(color: AppTheme.inkFaint),
                defaultTextStyle: const TextStyle(color: AppTheme.ink),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                headerPadding: EdgeInsets.symmetric(vertical: 12),
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left_rounded, color: AppTheme.inkMuted),
                rightChevronIcon:
                    Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((v) {
                      return Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.visitTypeColor(v.visitType),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  );
                },
                defaultBuilder: (context, day, focused) {
                  final dayVisits = widget.state.visitsOnDay(day);
                  final hasKOL = dayVisits.any(
                    (v) => v.potential == TargetPotential.KOL,
                  );
                  if (!hasKOL) return null;
                  return Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.danger, width: 1.4),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.danger,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _selected == null
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.selectADay,
                        style: const TextStyle(color: AppTheme.inkFaint),
                      ),
                    )
                  : _DayVisitList(
                      state: widget.state,
                      day: _selected!,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DayVisitList extends StatelessWidget {
  const _DayVisitList({required this.state, required this.day});

  final AppState state;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final items = state.visitsOnDay(day);
    if (items.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VisitFormScreen(state: state, initialDate: day),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Log visit for this day'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = items[index];
        final isMed = v.visitType == VisitType.medical;
        final tc = AppTheme.visitTypeColor(v.visitType);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.rTile),
            boxShadow: AppTheme.softShadow,
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.rTile)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tc.withAlpha(28),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMed
                    ? Icons.medical_services_outlined
                    : Icons.local_pharmacy_outlined,
                color: tc,
                size: 20,
              ),
            ),
            title: Text(
              v.targetName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.ink),
            ),
            subtitle: Text(
              '${v.potential.name} · ${v.structureType}',
              style: const TextStyle(color: AppTheme.inkMuted, fontSize: 12.5),
            ),
            trailing:
                const Icon(Icons.chevron_right_rounded, color: AppTheme.inkFaint),
          ),
        );
      },
    );
  }
}
