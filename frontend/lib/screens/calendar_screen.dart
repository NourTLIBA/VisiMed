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
                  color: AppTheme.gold,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.jade,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: AppTheme.vermillion),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                  letterSpacing: 1.5,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.gold),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.gold),
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
                          border: Border.all(color: AppTheme.gold.withAlpha(150), width: 0.5),
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
                      border: Border.all(color: AppTheme.gold, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.ricePaper,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.gold.withAlpha(150),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Expanded(
              child: _selected == null
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.selectADay,
                        style: TextStyle(
                          color: AppTheme.primaryDark.withAlpha(120),
                          fontStyle: FontStyle.italic,
                        ),
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gold.withAlpha(100), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.visitTypeColor(v.visitType).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.visitTypeColor(v.visitType).withAlpha(50)),
              ),
              child: Icon(
                isMed ? Icons.medical_services : Icons.local_pharmacy,
                color: AppTheme.visitTypeColor(v.visitType),
              ),
            ),
            title: Text(
              v.targetName,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
            ),
            subtitle: Text(
              '${v.potential.name} · ${v.structureType}',
              style: TextStyle(color: AppTheme.primaryDark.withAlpha(160)),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.gold),
          ),
        );
      },
    );
  }
}
