import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';

/// Automatic delegate ranking (see inconsistencies.md §3.4). Composite score
/// over: visits, objective attainment, sector coverage, orders generated.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.state});
  final AppState state;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.state.api.fetchLeaderboard();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.state.api.fetchLeaderboard());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _refresh,
      child: FutureBuilder<List<LeaderboardRow>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snap.hasError) {
            return _err(snap.error);
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return _err('Aucun délégué actif.');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const DecoSectionTitle('Classement des délégués',
                  icon: Icons.emoji_events_outlined),
              ...rows.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DecoCard(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _DelegateSheet(
                            state: widget.state, username: r.username),
                      ),
                      child: Row(
                        children: [
                          _RankBadge(r.rank),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppTheme.primaryDark)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    DecoChip('${r.visitsMonth} visites',
                                        color: AppTheme.primary),
                                    DecoChip(
                                        r.objectivePct == null
                                            ? 'obj —'
                                            : 'obj ${r.objectivePct!.toStringAsFixed(0)}%',
                                        color: AppTheme.gold),
                                    DecoChip(
                                        'couv ${r.coveragePct.toStringAsFixed(0)}%',
                                        color: AppTheme.jade),
                                    DecoChip('${r.ordersMonth} cmd',
                                        color: AppTheme.pharmaceutical),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(r.score.toStringAsFixed(2),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: AppTheme.primary)),
                              Text('score',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _err(Object? e) => ListView(children: [
        const SizedBox(height: 90),
        Center(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600)),
        )),
      ]);
}

class _RankBadge extends StatelessWidget {
  const _RankBadge(this.rank);
  final int rank;
  @override
  Widget build(BuildContext context) {
    final medal = rank <= 3;
    final c = rank == 1
        ? AppTheme.gold
        : rank == 2
            ? const Color(0xFFB8B8B8)
            : rank == 3
                ? const Color(0xFFCd7F32)
                : AppTheme.primary;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: medal ? c.withAlpha(30) : Colors.grey.shade100,
        border: Border.all(color: c, width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$rank',
          style: TextStyle(
              fontWeight: FontWeight.w900, color: c, fontSize: 16)),
    );
  }
}

/// Per-delegate synthetic view — visits of the day, objectives met, coverage.
class DelegatePerfScreen extends StatefulWidget {
  const DelegatePerfScreen({super.key, required this.state});
  final AppState state;

  @override
  State<DelegatePerfScreen> createState() => _DelegatePerfScreenState();
}

class _DelegatePerfScreenState extends State<DelegatePerfScreen> {
  late Future<DelegateStats> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.state.api.fetchDelegateStats();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.state.api.fetchDelegateStats());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _refresh,
      child: FutureBuilder<DelegateStats>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snap.hasError) {
            return ListView(children: [
              const SizedBox(height: 90),
              Center(child: Text('${snap.error}')),
            ]);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              DecoSectionTitle('Ma performance — ${snap.data!.username}',
                  icon: Icons.insights_outlined),
              DelegateStatsBody(stats: snap.data!),
            ],
          );
        },
      ),
    );
  }
}

class _DelegateSheet extends StatefulWidget {
  const _DelegateSheet({required this.state, required this.username});
  final AppState state;
  final String username;

  @override
  State<_DelegateSheet> createState() => _DelegateSheetState();
}

class _DelegateSheetState extends State<_DelegateSheet> {
  DelegateStats? _stats;
  Object? _error;

  @override
  void initState() {
    super.initState();
    AppUser? rep;
    for (final r in widget.state.representatives.value) {
      if (r.username == widget.username) {
        rep = r;
        break;
      }
    }
    widget.state.api.fetchDelegateStats(repId: rep?.id).then((s) {
      if (mounted) setState(() => _stats = s);
    }).catchError((e) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppTheme.gold, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Text(widget.username,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppTheme.primaryDark)),
          const SizedBox(height: 14),
          if (_error != null)
            Text('$_error')
          else if (_stats == null)
            const Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: DelegateStatsBody(stats: _stats!),
              ),
            ),
        ],
      ),
    );
  }
}

class DelegateStatsBody extends StatelessWidget {
  const DelegateStatsBody({super.key, required this.stats});
  final DelegateStats stats;

  @override
  Widget build(BuildContext context) {
    final o = stats.objective;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: DecoStat(
                    label: "Visites aujourd'hui",
                    value: '${stats.visitsToday}',
                    icon: Icons.today_outlined,
                    color: AppTheme.primary)),
            const SizedBox(width: 10),
            Expanded(
                child: DecoStat(
                    label: 'Cette semaine',
                    value: '${stats.visitsWeek}',
                    icon: Icons.date_range_outlined,
                    color: AppTheme.jade)),
            const SizedBox(width: 10),
            Expanded(
                child: DecoStat(
                    label: 'Ce mois',
                    value: '${stats.visitsMonth}',
                    icon: Icons.calendar_month_outlined,
                    color: AppTheme.gold)),
          ],
        ),
        const SizedBox(height: 12),
        DecoCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DecoGauge(
                value: o.pct == null ? 0 : o.pct! / 100,
                label: 'Objectif\natteint',
                centerText:
                    o.pct == null ? '—' : '${o.pct!.toStringAsFixed(0)}%',
                color: AppTheme.gold,
                size: 100,
              ),
              DecoGauge(
                value: stats.coveragePct / 100,
                label: 'Couverture\nsecteur',
                color: AppTheme.jade,
                size: 100,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DecoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Objectif visites (semaine)',
                  o.target == null ? '—' : '${o.actual} / ${o.target}'),
              _row('Commandes générées (mois)', '${stats.ordersMonth}'),
              _row('Nouveaux médecins (mois)', '${stats.newDoctorsMonth}'),
              _row('Durée moyenne', '${stats.avgDuration.toStringAsFixed(0)} min'),
              if (stats.territory.isNotEmpty) _row('Secteur', stats.territory),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
                child: Text(k,
                    style: TextStyle(
                        color: Colors.grey.shade700, fontSize: 13))),
            Text(v,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
          ],
        ),
      );
}
