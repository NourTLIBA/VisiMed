import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../state/filters.dart';
import '../theme/app_theme.dart';

/// Horizontal strip of quick-preset chips + a "Filtres" sheet. Reads and writes
/// `state.visitFilter`; every screen that shows visit data can drop this in.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VisitFilter>(
      valueListenable: state.visitFilter,
      builder: (context, f, _) {
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _Pill(
                label: 'Filtres${f.activeCount > 0 ? ' · ${f.activeCount}' : ''}',
                icon: Icons.tune_rounded,
                selected: f.activeCount > 0,
                onTap: () => _openSheet(context),
              ),
              const _Sep(),
              for (final p in FilterPreset.values)
                _Pill(
                  label: p.label,
                  selected: p.isActive(f),
                  onTap: () {
                    final next = p.isActive(f)
                        ? (p == FilterPreset.myKol
                            ? f.copyWith(potentials: const {})
                            : f.copyWith(clearRange: true))
                        : p.applyTo(f);
                    state.visitFilter.value = next;
                  },
                ),
              if (!f.isEmpty) ...[
                const _Sep(),
                _Pill(
                  label: 'Effacer',
                  icon: Icons.close_rounded,
                  selected: false,
                  onTap: () => state.visitFilter.value = const VisitFilter(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(state: state),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
              width: 1, height: 20, child: ColoredBox(color: AppTheme.hairline)),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppTheme.primary : AppTheme.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(AppTheme.rPill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: icon != null ? 12 : 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(label,
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.state});
  final AppState state;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late VisitFilter _f = widget.state.visitFilter.value;

  void _set(VisitFilter next) {
    setState(() => _f = next);
    widget.state.visitFilter.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final wilayas = widget.state.wilayas.value;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.hairline,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Filtres',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (!_f.isEmpty)
                  TextButton(
                    onPressed: () => _set(const VisitFilter()),
                    child: const Text('Réinitialiser'),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            _label('Période'),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 3),
                  lastDate: now,
                  initialDateRange: _f.range,
                );
                if (picked != null) _set(_f.copyWith(range: picked));
              },
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: Text(_f.range == null
                  ? 'Toutes les dates'
                  : '${_fmt(_f.range!.start)} → ${_fmt(_f.range!.end)}'),
            ),

            const SizedBox(height: 16),
            _label('Type de visite'),
            Row(
              children: [
                _seg('Tous', _f.type == null,
                    () => _set(_f.copyWith(clearType: true))),
                const SizedBox(width: 8),
                _seg('Médical', _f.type == VisitType.medical,
                    () => _set(_f.copyWith(type: VisitType.medical))),
                const SizedBox(width: 8),
                _seg('Pharma', _f.type == VisitType.pharmaceutical,
                    () => _set(_f.copyWith(type: VisitType.pharmaceutical))),
              ],
            ),

            const SizedBox(height: 16),
            _label('Potentiel'),
            Wrap(
              spacing: 8,
              children: [
                for (final p in TargetPotential.values)
                  _toggle(
                    p.name,
                    _f.potentials.contains(p),
                    AppTheme.potentialAccent(p),
                    () {
                      final set = Set<TargetPotential>.from(_f.potentials);
                      set.contains(p) ? set.remove(p) : set.add(p);
                      _set(_f.copyWith(potentials: set));
                    },
                  ),
              ],
            ),

            if (wilayas.isNotEmpty) ...[
              const SizedBox(height: 16),
              _label('Wilaya'),
              DropdownButtonFormField<String?>(
                value: _f.wilaya,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('Toutes les wilayas'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes les wilayas')),
                  ...wilayas.map((w) => DropdownMenuItem(value: w, child: Text(w))),
                ],
                onChanged: (v) => _set(v == null
                    ? _f.copyWith(clearWilaya: true)
                    : _f.copyWith(wilaya: v)),
              ),
            ],

            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voir les résultats'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkMuted)),
      );

  Widget _seg(String label, bool sel, VoidCallback onTap) => Expanded(
        child: Material(
          color: sel ? AppTheme.primary : AppTheme.primary.withAlpha(16),
          borderRadius: BorderRadius.circular(AppTheme.rPill),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppTheme.primary)),
            ),
          ),
        ),
      );

  Widget _toggle(String label, bool sel, Color color, VoidCallback onTap) =>
      Material(
        color: sel ? color : color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.rPill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : color)),
          ),
        ),
      );

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
