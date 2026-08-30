import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';
import 'doctor_detail_screen.dart';

/// Visit detail — replaces the `onTap: () {}` placeholder in the visit list
/// (see inconsistencies.md §6.1).
class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({super.key, required this.state, required this.visit});
  final AppState state;
  final VisitRecord visit;

  String _d(DateTime? d) =>
      d == null ? '—' : d.toLocal().toString().split(' ').first;

  @override
  Widget build(BuildContext context) {
    final v = visit;
    final typeColor = AppTheme.visitTypeColor(v.visitType);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: const Text('VISITE',
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          DecoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                        v.visitType == VisitType.medical
                            ? Icons.medical_services_outlined
                            : Icons.local_pharmacy_outlined,
                        color: typeColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(v.targetName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  DecoChip(v.potential.name,
                      color: Deco.potentialColor(v.potential.name)),
                  DecoChip(v.visitType.name, color: typeColor),
                  DecoChip('${v.durationMinutes} min', color: AppTheme.primary),
                ]),
              ],
            ),
          ),
          if (v.doctorId != null) ...[
            const SizedBox(height: 10),
            DecoCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    DoctorDetailScreen(state: state, doctorId: v.doctorId!),
              )),
              child: Row(
                children: [
                  const Icon(Icons.folder_shared_outlined,
                      color: AppTheme.gold),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Ouvrir la fiche médecin',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark))),
                  const Icon(Icons.chevron_right, color: AppTheme.gold),
                ],
              ),
            ),
          ],
          const DecoSectionTitle('Détails', icon: Icons.info_outline),
          DecoCard(
            child: Column(
              children: [
                _kv('Date', _d(v.date)),
                _kv('Délégué', v.repUsername ?? '—'),
                _kv('Spécialité', v.specialty),
                _kv('Structure', v.structureType),
                _kv('Wilaya / Commune', '${v.wilaya} / ${v.commune}'),
                _kv('Adresse', v.address),
                _kv('Téléphone', v.telephone),
                _kv('GCO', v.gcoStatus),
                _kv('Flux patients', v.patientLoad),
              ],
            ),
          ),
          const DecoSectionTitle('Matériel remis',
              icon: Icons.card_giftcard_outlined),
          DecoCard(
            child: Column(
              children: [
                _kv('Flacons', '${v.qtyVials}'),
                _kv('Lecteurs', '${v.qtyReader}'),
                _kv('Mètres', '${v.qtyMeters}'),
                _kv('Brochures médecin', '${v.qtyBrochureM}'),
                _kv('Brochures patient', '${v.qtyBrochurePatient}'),
                _kv('Affiches', '${v.qtyAffiche}'),
              ],
            ),
          ),
          if (v.presentedProducts.isNotEmpty) ...[
            const DecoSectionTitle('Produits présentés',
                icon: Icons.medication_outlined),
            DecoCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: v.presentedProducts
                    .map((p) => DecoChip(p, color: AppTheme.jade))
                    .toList(),
              ),
            ),
          ],
          if ((v.comment ?? '').isNotEmpty) ...[
            const DecoSectionTitle('Remarques', icon: Icons.notes_outlined),
            DecoCard(child: Text(v.comment!)),
          ],
          if (v.objections.isNotEmpty) ...[
            const DecoSectionTitle('Objections',
                icon: Icons.report_problem_outlined),
            DecoCard(child: Text(v.objections)),
          ],
          if (v.nextAction.isNotEmpty) ...[
            const DecoSectionTitle('Prochaine action',
                icon: Icons.flag_circle_outlined),
            DecoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.nextAction),
                  if (v.nextActionDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: DecoChip('Échéance ${_d(v.nextActionDate)}',
                          color: AppTheme.vermillion),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 130,
                child: Text(k,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12.5))),
            Expanded(
                child: Text(v.isEmpty ? '—' : v,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                        fontSize: 13))),
          ],
        ),
      );
}
