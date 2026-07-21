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
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((v) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
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
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.KOLAccent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('${day.day}'),
                  );
                },
              ),
            ),
            Expanded(
              child: _selected == null
                  ? Center(child: Text(AppLocalizations.of(context)!.selectADay))
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
    return ListView(
      children: items
          .map(
            (v) => ListTile(
              leading: Icon(
                v.visitType == VisitType.medical
                    ? Icons.medical_services
                    : Icons.local_pharmacy,
                color: AppTheme.visitTypeColor(v.visitType),
              ),
              title: Text(v.targetName),
              subtitle: Text('${v.potential.name} · ${v.structureType}'),
            ),
          )
          .toList(),
    );
  }
}
