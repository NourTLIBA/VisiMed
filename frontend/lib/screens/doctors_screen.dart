import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';
import 'doctor_detail_screen.dart';

/// Directory of tracked doctors — the entry point to each doctor's file
/// (see inconsistencies.md §2.1 / §6.1).
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
        var list = doctors.where((d) {
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
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Rechercher un médecin…',
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.jade, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppTheme.gold.withAlpha(120)),
                      ),
                    ),
                  ),
                  if (wilayas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _wchip('Toutes', _wilaya == null,
                              () => setState(() => _wilaya = null)),
                          ...wilayas.map((w) => _wchip(w, _wilaya == w,
                              () => setState(() => _wilaya = w))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('Aucun médecin',
                          style: TextStyle(color: Colors.grey.shade500)))
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: widget.state.reloadDoctors,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                        itemCount: list.length,
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

  Widget _wchip(String label, bool sel, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: sel ? AppTheme.primary : AppTheme.primary.withAlpha(14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withAlpha(sel ? 255 : 60)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : AppTheme.primary)),
        ),
      );
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.state, required this.doctor});
  final AppState state;
  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final pc = Deco.potentialColor(doctor.potential.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              DoctorDetailScreen(state: state, doctorId: doctor.id),
        )),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pc.withAlpha(22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: pc.withAlpha(120)),
              ),
              child: Text(
                doctor.potential.name,
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: pc, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark)),
                  const SizedBox(height: 2),
                  Text(
                    [doctor.specialty, doctor.wilaya]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${doctor.visitCount}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary)),
                Text('visites',
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.gold),
          ],
        ),
      ),
    );
  }
}
