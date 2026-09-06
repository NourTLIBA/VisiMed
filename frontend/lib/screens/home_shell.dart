import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/language_selector.dart';
import 'admin_screen.dart';
import 'alerts_screen.dart';
import 'calendar_screen.dart';
import 'doctors_screen.dart';
import 'login_screen.dart';
import 'manager_dashboard_screen.dart';
import 'map_screen.dart';
import 'team_screen.dart';
import 'visit_form_screen.dart';
import 'visits_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});

  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  String _roleLabel(AppUser u, AppLocalizations l) {
    if (u.isAdmin) return l.roleAdmin;
    if (u.isManager) return l.roleManager;
    if (u.isPharmaRep) return l.rolePharmaRep;
    return l.roleMedRep;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: widget.state.user,
      builder: (context, user, _) {
        if (user == null) return const SizedBox.shrink();

        final l = AppLocalizations.of(context)!;
        final tabs = <Widget>[];
        final destinations = <NavigationDestination>[];

        void tab(Widget screen, IconData icon, IconData selected, String label) {
          tabs.add(screen);
          destinations.add(NavigationDestination(
            icon: Icon(icon),
            selectedIcon: Icon(selected),
            label: label,
          ));
        }

        final mapScreen = MapScreen(state: widget.state);
        final doctorsScreen = DoctorsScreen(state: widget.state);

        if (user.isStaff) {
          tab(ManagerDashboardScreen(state: widget.state),
              Icons.dashboard_outlined, Icons.dashboard, l.dashboard);
          if (user.isAdmin) {
            tab(AdminScreen(state: widget.state),
                Icons.tune_outlined, Icons.tune, l.roleAdmin);
          } else {
            tab(LeaderboardScreen(state: widget.state),
                Icons.emoji_events_outlined, Icons.emoji_events, l.team);
          }
          tab(doctorsScreen, Icons.folder_shared_outlined, Icons.folder_shared,
              l.doctors);
          tab(mapScreen, Icons.map_outlined, Icons.map, l.map);
          tab(AlertsScreen(state: widget.state),
              Icons.notifications_none_rounded,
              Icons.notifications_rounded, l.alerts);
        } else {
          tab(VisitsScreen(state: widget.state), Icons.article_outlined,
              Icons.article, l.visits);
          tab(CalendarScreen(state: widget.state), Icons.calendar_today_outlined,
              Icons.calendar_today, l.calendar);
          tab(doctorsScreen, Icons.folder_shared_outlined, Icons.folder_shared,
              l.doctors);
          tab(mapScreen, Icons.map_outlined, Icons.map, l.map);
          tab(DelegatePerfScreen(state: widget.state), Icons.insights_outlined,
              Icons.insights, l.performance);
        }

        if (_index >= tabs.length) _index = 0;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_hospital, size: 18, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('VisiMed',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink)),
                    Text(
                      '${_roleLabel(user, l)} · ${user.username}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.inkFaint),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder<Locale>(
                valueListenable: widget.state.currentLocale,
                builder: (context, _, __) =>
                    LanguageSelector(state: widget.state, color: AppTheme.inkMuted),
              ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined, size: 21),
                tooltip: 'Exporter',
                onPressed: () => _showExportSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20),
                tooltip: 'Déconnexion',
                onPressed: () {
                  widget.state.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => LoginScreen(state: widget.state)),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: tabs[_index],
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.hairline)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: destinations,
            ),
          ),
          floatingActionButton: _index == 0 && !user.isStaff
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => VisitFormScreen(state: widget.state)),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l.newVisit),
                )
              : null,
        );
      },
    );
  }

  Future<void> _showExportSheet(BuildContext context) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 0, 6),
                  child: Text('Exporter le rapport',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              _exportTile(ctx, Icons.grid_on_outlined, 'CSV',
                  'Compatible tableur', 'csv'),
              _exportTile(ctx, Icons.table_view_outlined, 'Excel (XLSX)',
                  'Classeur formaté', 'xlsx'),
              _exportTile(ctx, Icons.picture_as_pdf_outlined, 'PDF',
                  'Prêt à imprimer', 'pdf'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (format == null || !context.mounted) return;

    try {
      final fileNameOrPath = await widget.state.api.downloadReport(format);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enregistré : $fileNameOrPath')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${AppLocalizations.of(context)!.error} : $e'),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  Widget _exportTile(
      BuildContext ctx, IconData icon, String title, String sub, String val) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sub,
          style: const TextStyle(fontSize: 12, color: AppTheme.inkFaint)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.inkFaint),
      onTap: () => Navigator.pop(ctx, val),
    );
  }
}
