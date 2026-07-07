import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
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
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Visits',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          if (user.isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ];

        if (_index >= tabs.length) _index = 0;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Inline logo in AppBar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_hospital,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('VisiMed'),
              ],
            ),
            actions: [
              // Role badge
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.username,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Export data',
                onPressed: () => _showExportSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign out',
                onPressed: () {
                  widget.state.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(state: widget.state),
                    ),
                    (route) => false, // remove every route
                  );
                },
              ),
            ],
          ),
          body: tabs[_index],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0xFFE8ECF5), width: 1)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: destinations,
            ),
          ),
          floatingActionButton: _index == 0 && !user.isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            VisitFormScreen(state: widget.state),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Log Visit'),
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
          content: Text('Export failed: $e'),
          backgroundColor: AppTheme.kolAccent,
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
