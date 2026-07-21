import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppTheme.primary,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.bar_chart_outlined, size: 20),
                  text: 'KPIs',
                ),
                Tab(
                  icon: const Icon(Icons.people_outline, size: 20),
                  text: AppLocalizations.of(context)!.activeReps,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _KpiPanel(state: state),
                _RepPanel(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI panel ────────────────────────────────────────────────────────────────

class _KpiPanel extends StatelessWidget {
  const _KpiPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminKpis?>(
      valueListenable: state.kpis,
      builder: (context, kpis, _) {
        if (kpis == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Horizontal compact metric scroll ───────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CompactMetric(
                    label: AppLocalizations.of(context)!.totalVisits,
                    value: '${kpis.totalVisits}',
                    icon: Icons.assignment_turned_in_outlined,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _CompactMetric(
                    label: AppLocalizations.of(context)!.activeReps,
                    value: '${kpis.activeReps}',
                    icon: Icons.people_outline,
                    color: AppTheme.pharmaceutical,
                  ),
                  const SizedBox(width: 8),
                  _CompactMetric(
                    label: AppLocalizations.of(context)!.qtyVials,
                    value: '${kpis.totalVials}',
                    icon: Icons.science_outlined,
                    color: AppTheme.medical,
                  ),
                  const SizedBox(width: 8),
                  _CompactMetric(
                    label: AppLocalizations.of(context)!.qtyReader,
                    value: '${kpis.totalReaders}',
                    icon: Icons.devices_outlined,
                    color: AppTheme.accent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── By visit type ──────────────────────────────────────────
            _SectionCard(
              title: AppLocalizations.of(context)!.byType,
              icon: Icons.category_outlined,
              children: [
                _StackedRatioBar(
                  values: kpis.byVisitType,
                  total: kpis.totalVisits,
                ),
                const Divider(height: 1),
                ...kpis.byVisitType.entries.map((e) {
                  final label = e.key.toLowerCase().contains('med') ? AppLocalizations.of(context)!.medical : AppLocalizations.of(context)!.pharmaceutical;
                  return _BreakdownRow(
                    label: label,
                    value: e.value,
                    total: kpis.totalVisits,
                    color: e.key.toLowerCase().contains('med')
                        ? AppTheme.medical
                        : AppTheme.pharmaceutical,
                  );
                }),
              ],
            ),

            const SizedBox(height: 12),

            // ── By potential ───────────────────────────────────────────
            _SectionCard(
              title: AppLocalizations.of(context)!.byPotential,
              icon: Icons.star_outline,
              children: kpis.byPotential.entries.map((e) {
                final displayLabel = e.key == 'KOL' ? 'KOL' : e.key.toUpperCase();
                return _BreakdownRow(
                  label: displayLabel,
                  value: e.value,
                  total: kpis.totalVisits,
                  color: e.key == 'KOL'
                      ? AppTheme.KOLAccent
                      : AppTheme.primary,
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _StackedRatioBar extends StatelessWidget {
  const _StackedRatioBar({
    required this.values,
    required this.total,
  });

  final Map<String, int> values;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    // Sum matching either DB value or display name case-insensitively
    int medicalCount = 0;
    int pharmaCount = 0;

    values.forEach((key, val) {
      if (key.toLowerCase().contains('med')) {
        medicalCount += val;
      } else {
        pharmaCount += val;
      }
    });

    final medPct = total > 0 ? medicalCount / total : 0.0;
    final pharmaPct = total > 0 ? pharmaCount / total : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 16,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  if (medicalCount > 0)
                    Expanded(
                      flex: (medPct * 100).round(),
                      child: Container(
                        color: AppTheme.medical,
                      ),
                    ),
                  if (pharmaCount > 0)
                    Expanded(
                      flex: (pharmaPct * 100).round(),
                      child: Container(
                        color: AppTheme.pharmaceutical,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (medicalCount > 0)
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.medical,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Medical: ${(medPct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              if (pharmaCount > 0)
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.pharmaceutical,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pharma: ${(pharmaPct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${(pct * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rep panel ─────────────────────────────────────────────────────────────────

class _RepPanel extends StatefulWidget {
  const _RepPanel({required this.state});

  final AppState state;

  @override
  State<_RepPanel> createState() => _RepPanelState();
}

class _RepPanelState extends State<_RepPanel> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AppUser>>(
      valueListenable: widget.state.representatives,
      builder: (context, reps, _) {
        return Column(
          children: [
            // ── toolbar ─────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${reps.length} representative${reps.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Add rep',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── list ────────────────────────────────────────────────
            Expanded(
              child: reps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No representatives yet',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: reps.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final r = reps[i];
                        final isM = r.role == UserRole.medRep;
                        final roleColor =
                            isM ? AppTheme.medical : AppTheme.pharmaceutical;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE8ECF5), width: 1),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: roleColor.withAlpha(25),
                              child: Text(
                                r.username.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(r.username,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${r.role.name} · ${r.assignedRegions}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (r.telephone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.phone_outlined, color: AppTheme.primary, size: 20),
                                    onPressed: () => launchUrl(Uri.parse('tel:${r.telephone}')),
                                  ),
                                if (r.email.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.email_outlined, color: AppTheme.primary, size: 20),
                                    onPressed: () => launchUrl(Uri.parse('mailto:${r.email}')),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit_location_alt_outlined, color: AppTheme.primary, size: 20),
                                  onPressed: () => _showEditRegionsDialog(context, r),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.lock_reset_outlined, color: AppTheme.primary, size: 20),
                                  onPressed: () => _showResetPasswordDialog(context, r),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: Colors.red.shade300, size: 20),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        title:
                                            const Text('Delete rep?'),
                                        content: Text(
                                            'Remove "${r.username}" permanently?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.KOLAccent,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await widget.state.api
                                          .deleteRepresentative(r.id);
                                      widget.state.representatives.value =
                                          widget.state.representatives.value
                                              .where((x) => x.id != r.id)
                                              .toList();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final regionsCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    var role = 'med_rep';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_add_outlined, color: AppTheme.primary),
              SizedBox(width: 10),
              Text('New Representative',
                  style: TextStyle(fontSize: 17)),
            ],
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon:
                      Icon(Icons.person_outline, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline,
                      color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: regionsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Regions (comma-separated)',
                  prefixIcon:
                      Icon(Icons.map_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Telephone',
                  prefixIcon:
                      Icon(Icons.phone_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined,
                      color: AppTheme.primary),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'med_rep', child: Text('Medical Rep')),
                  DropdownMenuItem(
                      value: 'pharma_rep', child: Text('Pharma Rep')),
                ],
                onChanged: (v) => setDlgState(() => role = v!),
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final created =
                    await widget.state.api.createRepresentative({
                  'username': userCtrl.text.trim(),
                  'password': passCtrl.text,
                  'role': role,
                  'assigned_regions': regionsCtrl.text.trim(),
                  'telephone': phoneCtrl.text.trim(),
                  'email': '${userCtrl.text.trim()}@visimed.dz',
                });
                widget.state.representatives.value = [
                  ...widget.state.representatives.value,
                  created,
                ];
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditRegionsDialog(BuildContext context, AppUser r) async {
    final regionsCtrl = TextEditingController(text: r.assignedRegions);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Regions'),
        content: TextField(
          controller: regionsCtrl,
          decoration: const InputDecoration(
            labelText: 'Regions (comma-separated)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final updated = await widget.state.api.updateRepresentative(
                r.id,
                {'assigned_regions': regionsCtrl.text.trim()},
              );
              final reps = widget.state.representatives.value.toList();
              final idx = reps.indexWhere((x) => x.id == r.id);
              if (idx != -1) {
                reps[idx] = updated;
                widget.state.representatives.value = reps;
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetPasswordDialog(BuildContext context, AppUser r) async {
    final passCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password for ${r.username}'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (passCtrl.text.isEmpty) return;
              await widget.state.api.resetRepresentativePassword(r.id, passCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password reset for ${r.username}')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
