import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../state/filters.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';
import '../widgets/filter_bar.dart';
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

  bool _matchesFilter(Doctor d, VisitFilter f) {
    if (f.wilaya != null &&
        d.wilaya.toLowerCase() != f.wilaya!.toLowerCase()) {
      return false;
    }
    if (f.potentials.isNotEmpty && !f.potentials.contains(d.potential)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([widget.state.doctors, widget.state.visitFilter]),
      builder: (context, _) {
        final doctors = widget.state.doctors.value;
        final f = widget.state.visitFilter.value;
        final q = _query.toLowerCase();
        final list = doctors.where((d) {
          final matchQ = q.isEmpty ||
              d.name.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q);
          return matchQ && _matchesFilter(d, f);
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Rechercher un médecin…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),
            FilterBar(state: widget.state),
            const Divider(height: 1),
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
