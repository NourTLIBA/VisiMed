import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/deco.dart';

/// Doctor file with visit history (see inconsistencies.md §2.1):
/// last visit, products presented, material given, orders obtained,
/// remarks, objections, next planned action + full visit timeline.
class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({
    super.key,
    required this.state,
    required this.doctorId,
  });
  final AppState state;
  final int doctorId;

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  late Future<DoctorHistory> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.state.api.fetchDoctorHistory(widget.doctorId);
  }

  String _d(DateTime? d) =>
      d == null ? '—' : d.toLocal().toString().split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: const Text('FICHE MÉDECIN',
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
      ),
      body: FutureBuilder<DoctorHistory>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snap.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${snap.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
            ));
          }
          final h = snap.data!;
          final doc = h.doctor;
          final pc = Deco.potentialColor(doc.potential.name);
          final mat = h.materialGiven;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // ── Identity ──────────────────────────────────────────────
              DecoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: pc.withAlpha(24),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: pc, width: 1.4),
                          ),
                          child: Text(doc.potential.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: pc)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryDark)),
                              const SizedBox(height: 2),
                              Text(
                                [doc.specialty, doc.structureType]
                                    .where((s) => s.isNotEmpty)
                                    .join(' · '),
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (doc.gcoStatus.isNotEmpty)
                          DecoChip(doc.gcoStatus, color: AppTheme.primary),
                        if (doc.wilaya.isNotEmpty)
                          DecoChip(
                              '${doc.wilaya}${doc.commune.isNotEmpty ? ' / ${doc.commune}' : ''}',
                              color: AppTheme.jade),
                      ],
                    ),
                    if (doc.telephone.isNotEmpty || doc.email.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (doc.telephone.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () =>
                                  launchUrl(Uri.parse('tel:${doc.telephone}')),
                              icon: const Icon(Icons.phone_outlined, size: 16),
                              label: Text(doc.telephone,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          const SizedBox(width: 8),
                          if (doc.email.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () => launchUrl(
                                  Uri.parse('mailto:${doc.email}')),
                              icon: const Icon(Icons.mail_outline, size: 16),
                              label: const Text('Email',
                                  style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Summary tiles ─────────────────────────────────────────
              const DecoSectionTitle('Synthèse du suivi',
                  icon: Icons.history_outlined),
              Row(
                children: [
                  Expanded(
                      child: DecoStat(
                          label: 'Dernière visite',
                          value: _d(h.lastVisitDate),
                          icon: Icons.event_available_outlined,
                          color: AppTheme.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: DecoStat(
                          label: 'Visites totales',
                          value: '${h.visitCount}',
                          sub: 'depuis ${_d(h.firstVisitDate)}',
                          icon: Icons.repeat_outlined,
                          color: AppTheme.jade)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: DecoStat(
                          label: 'Commandes',
                          value: '${h.ordersCount}',
                          icon: Icons.receipt_long_outlined,
                          color: AppTheme.gold)),
                ],
              ),

              // ── Next action ──────────────────────────────────────────
              const DecoSectionTitle('Prochaine action prévue',
                  icon: Icons.flag_circle_outlined),
              DecoCard(
                child: h.nextActionText == null || h.nextActionText!.isEmpty
                    ? Text('Aucune action planifiée.',
                        style: TextStyle(color: Colors.grey.shade500))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chevron_right,
                              color: AppTheme.gold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.nextActionText!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryDark)),
                                if (h.nextActionDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: DecoChip(
                                        'Échéance ${_d(h.nextActionDate)}',
                                        color: AppTheme.vermillion),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),

              // ── Products presented ───────────────────────────────────
              const DecoSectionTitle('Produits présentés',
                  icon: Icons.medication_outlined),
              DecoCard(
                child: h.productsPresented.isEmpty
                    ? Text('Aucun produit enregistré.',
                        style: TextStyle(color: Colors.grey.shade500))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: h.productsPresented
                            .map((p) => DecoChip(p, color: AppTheme.jade))
                            .toList(),
                      ),
              ),

              // ── Material given ───────────────────────────────────────
              const DecoSectionTitle('Matériel remis (cumul)',
                  icon: Icons.card_giftcard_outlined),
              DecoCard(
                child: Column(
                  children: [
                    _matRow('Flacons', mat['vials']),
                    _matRow('Lecteurs', mat['readers']),
                    _matRow('Lecteurs (mètres)', mat['meters']),
                    _matRow('Brochures médecin', mat['brochure_m']),
                    _matRow('Brochures patient', mat['brochure_patient']),
                    _matRow('Affiches', mat['affiche']),
                  ],
                ),
              ),

              // ── Orders obtained ──────────────────────────────────────
              const DecoSectionTitle('Commandes obtenues',
                  icon: Icons.shopping_bag_outlined),
              if (h.orders.isEmpty)
                DecoCard(
                    child: Text('Aucune commande.',
                        style: TextStyle(color: Colors.grey.shade500)))
              else
                ...h.orders.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DecoCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                o.productName.isEmpty
                                    ? 'Commande'
                                    : o.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryDark),
                              ),
                            ),
                            DecoChip('x${o.quantity}',
                                color: AppTheme.primary),
                            const SizedBox(width: 6),
                            DecoChip(o.status,
                                color: Deco.orderStatusColor(o.status)),
                          ],
                        ),
                      ),
                    )),

              // ── Remarks ──────────────────────────────────────────────
              const DecoSectionTitle('Remarques', icon: Icons.notes_outlined),
              _notes(h.remarks, empty: 'Aucune remarque.'),

              // ── Objections ───────────────────────────────────────────
              const DecoSectionTitle('Objections',
                  icon: Icons.report_problem_outlined),
              _notes(h.objections,
                  empty: 'Aucune objection.', color: AppTheme.vermillion),

              // ── Timeline ─────────────────────────────────────────────
              const DecoSectionTitle('Historique des visites',
                  icon: Icons.timeline_outlined),
              ...h.visits.map(_visitTile),
            ],
          );
        },
      ),
    );
  }

  Widget _matRow(String label, int? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700))),
            Text('${v ?? 0}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
          ],
        ),
      );

  Widget _notes(List<HistoryNote> notes,
      {required String empty, Color color = AppTheme.primary}) {
    if (notes.isEmpty) {
      return DecoCard(
          child: Text(empty, style: TextStyle(color: Colors.grey.shade500)));
    }
    return Column(
      children: notes
          .map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DecoCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 6, color: color),
                          const SizedBox(width: 8),
                          Text(_d(n.date),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600)),
                          const Spacer(),
                          if (n.rep.isNotEmpty)
                            Text(n.rep,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n.text,
                          style: const TextStyle(
                              color: AppTheme.primaryDark, fontSize: 13)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _visitTile(VisitRecord v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_outlined,
                    size: 16, color: AppTheme.jade),
                const SizedBox(width: 8),
                Text(_d(v.date),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark)),
                const Spacer(),
                DecoChip('${v.durationMinutes}′', color: AppTheme.primary),
              ],
            ),
            if (v.comment != null && v.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(v.comment!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
            if (v.presentedProducts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: v.presentedProducts
                    .map((p) => DecoChip(p, color: AppTheme.jade))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
