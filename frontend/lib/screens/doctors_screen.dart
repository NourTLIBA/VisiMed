import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';
import 'doctor_detail_screen.dart';

/// Directory of tracked doctors — the entry point to each doctor's file.
class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  String _query = '';
  String? _wilaya;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Doctor>>(
      valueListenable: widget.state.doctors,
      builder: (context, doctors, _) {
        final wilayas = {for (final d in doctors) d.wilaya}
          ..removeWhere((w) => w.isEmpty);
        final list = doctors.where((d) {
          final q = _query.toLowerCase();
          final matchQ = q.isEmpty ||
              d.name.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q);
          final matchW = _wilaya == null || d.wilaya == _wilaya;
          return matchQ && matchW;
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Rechercher un médecin…',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                    ),
                  ),
                  if (wilayas.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterPill(
                              label: 'Toutes',
                              selected: _wilaya == null,
                              onTap: () => setState(() => _wilaya = null)),
                          ...wilayas.map((w) => _FilterPill(
                              label: w,
                              selected: _wilaya == w,
                              onTap: () => setState(() => _wilaya = w))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const DecoEmpty(
                      icon: Icons.folder_shared_outlined,
                      title: 'Aucun médecin',
                      message: 'Aucun résultat pour cette recherche.')
                  : RefreshIndicator(
                      onRefresh: widget.state.reloadDoctors,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _DoctorTile(state: widget.state, doctor: list[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppTheme.primary : AppTheme.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(AppTheme.rPill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.state, required this.doctor});
  final AppState state;
  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final pc = Deco.potentialColor(doctor.potential.name);
    return DecoCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DoctorDetailScreen(state: state, doctorId: doctor.id),
      )),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              DecoAvatar(doctor.name, color: AppTheme.primary, size: 46),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: pc,
                  borderRadius: BorderRadius.circular(AppTheme.rPill),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  doctor.potential.name,
                  style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: AppTheme.ink)),
                const SizedBox(height: 3),
                Text(
                  [doctor.specialty, doctor.wilaya]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${doctor.visitCount}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.primary)),
              const Text('visites',
                  style: TextStyle(fontSize: 10.5, color: AppTheme.inkFaint)),
            ],
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.inkFaint),
        ],
      ),
    );
  }
}
