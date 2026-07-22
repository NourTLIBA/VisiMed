import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/language_selector.dart';
import 'admin_screen.dart';
import 'calendar_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: widget.state.user,
      builder: (context, user, _) {
        if (user == null) return const SizedBox.shrink();

        final tabs = <Widget>[
          VisitsScreen(state: widget.state),
          CalendarScreen(state: widget.state),
          MapScreen(state: widget.state),
          if (user.isAdmin) AdminScreen(state: widget.state),
        ];

        final destinations = <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: AppLocalizations.of(context)!.visits,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: AppLocalizations.of(context)!.calendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: AppLocalizations.of(context)!.map,
          ),
          if (user.isAdmin)
            NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: const Icon(Icons.admin_panel_settings),
              label: AppLocalizations.of(context)!.roleAdmin,
            ),
        ];

        if (_index >= tabs.length) _index = 0;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.primaryDark,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: Container(
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.gold,
                      AppTheme.gold,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Art Deco logo frame
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppTheme.gold.withAlpha(120), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_hospital,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'VISIMED',
                      style: TextStyle(
                        color: AppTheme.ricePaper,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    Text(
                      'Field CRM',
                      style: TextStyle(
                        color: AppTheme.gold.withAlpha(200),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder<Locale>(
                valueListenable: widget.state.currentLocale,
                builder: (context, _, __) {
                  return LanguageSelector(state: widget.state);
                },
              ),
              // Art Deco role badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gold.withAlpha(100), width: 1),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white.withAlpha(12),
                ),
                child: Text(
                  user.username.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTheme.ricePaper,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 20),
                tooltip: 'Export data',
                onPressed: () => _showExportSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20),
                tooltip: 'Sign out',
                onPressed: () {
                  widget.state.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(state: widget.state),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: tabs[_index],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.gold, width: 1.5),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.white,
              indicatorColor: AppTheme.gold.withAlpha(35),
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: destinations,
            ),
          ),
          floatingActionButton: _index == 0 && !user.isAdmin
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.gold, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VisitFormScreen(state: widget.state),
                        ),
                      );
                    },
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.gold,
                    elevation: 0,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'LOG VISIT',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Future<void> _showExportSheet(BuildContext context) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Export report as',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              _exportTile(ctx, Icons.table_chart_outlined,
                  'CSV', 'Spreadsheet-compatible', 'csv'),
              _exportTile(ctx, Icons.grid_on_outlined,
                  'Excel (XLSX)', 'Formatted workbook', 'xlsx'),
              _exportTile(ctx, Icons.picture_as_pdf_outlined,
                  'PDF', 'Print-ready report', 'pdf'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (format == null || !context.mounted) return;

    try {
      final file = await widget.state.api.downloadReport(format);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to ${file.path}'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.error}: $e'),
          backgroundColor: AppTheme.KOLAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _exportTile(
      BuildContext ctx, IconData icon, String title, String sub, String val) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sub,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () => Navigator.pop(ctx, val),
    );
  }
}
