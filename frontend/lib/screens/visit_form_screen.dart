import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class VisitFormScreen extends StatefulWidget {
  const VisitFormScreen({
    super.key,
    required this.state,
    this.initialDate,
  });

  final AppState state;
  final DateTime? initialDate;

  @override
  State<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends State<VisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late VisitType _visitType;
  late DateTime _date;
  late TargetPotential _potential;

  final _targetCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController(text: 'MG');
  final _durationCtrl = TextEditingController(text: '30');

  // Quantities for "Leave behind"
  final _vialsCtrl = TextEditingController(text: '0');
  final _metersCtrl = TextEditingController(text: '0');
  final _brochureMCtrl = TextEditingController(text: '0');
  final _brochurePatientCtrl = TextEditingController(text: '0');
  final _posterCtrl = TextEditingController(text: '0');
  final _readerCtrl = TextEditingController(text: '0');

  String? _gender;
  String _patientLoad = '0-15';
  String _structureType = 'Cabinet Privé';
  String _gcoStatus = 'Pas intéressé(e)';
  String? _wilaya;
  String? _commune;
  bool _saving = false;

  static const _gcoOptions = [
    'Pas intéressé(e)',
    'Intéressé(e)',
    'Formé(e)',
    'Compte GCO créé',
    'Compte non actif',
    'Compte actif',
  ];

  bool get _isMedical => widget.state.user.value?.isMedRep ?? false;
  bool get _isPharma => widget.state.user.value?.isPharmaRep ?? false;

  @override
  void initState() {
    super.initState();
    final user = widget.state.user.value!;
    _visitType = user.defaultVisitType;
    _date = widget.initialDate ?? DateTime.now();
    _potential = TargetPotential.B;
    if (_isPharma) _structureType = 'Officine';
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _commentCtrl.dispose();
    _specialtyCtrl.dispose();
    _durationCtrl.dispose();
    _vialsCtrl.dispose();
    _metersCtrl.dispose();
    _brochureMCtrl.dispose();
    _brochurePatientCtrl.dispose();
    _posterCtrl.dispose();
    _readerCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.gold.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.gold.withAlpha(100), width: 1),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Text(
            text.toUpperCase(),
            style: AppTheme.sectionHeader,
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E0D5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _fieldGap() => const SizedBox(height: 14);

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final Color headerColor = AppTheme.gold;
    final String roleLabel = _isMedical ? 'Medical' : _isPharma ? 'Pharma' : 'Admin';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 26, width: 26, errorBuilder: (_, __, ___) => const Icon(Icons.bookmark_border)),
            const SizedBox(width: 10),
            const Text('Log Visit'),
          ],
        ),
        leading: const BackButton(),
        actions: [
          if (roleLabel.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: headerColor.withAlpha(35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: headerColor.withAlpha(140), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isMedical
                        ? Icons.medical_services_outlined
                        : Icons.local_pharmacy_outlined,
                    color: headerColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    roleLabel,
                    style: TextStyle(
                      color: headerColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Visit Details ───────────────────────────────────────────
            _sectionLabel(AppLocalizations.of(context)!.visitDetails, Icons.assignment_outlined),
            _card(children: [
              if (!_isMedical && !_isPharma) ...[
                DropdownButtonFormField<VisitType>(
                  value: _visitType,
                  decoration: const InputDecoration(
                    labelText: 'Visit type',
                    prefixIcon: Icon(Icons.category_outlined, color: AppTheme.jade),
                  ),
                  items: VisitType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _visitType = v!),
                ),
                _fieldGap(),
              ],

              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E0D5), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.jade, size: 18),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Visit Date',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            _date.toLocal().toString().split(' ').first,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              _fieldGap(),

              TextFormField(
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  prefixIcon: Icon(Icons.timer_outlined, color: AppTheme.jade),
                  suffixText: 'min',
                ),
              ),
            ]),

            // ── Doctor info ─────────────────────────────────────────────
            _sectionLabel(
              _isPharma ? 'Pharmacy Info' : 'Doctor info',
              _isPharma ? Icons.local_pharmacy_outlined : Icons.person_outline,
            ),
            _card(children: [
              TextFormField(
                controller: _targetCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: _isPharma ? 'Pharmacy / Structure name' : 'Doctor name',
                  prefixIcon: Icon(
                    _isPharma ? Icons.store_outlined : Icons.badge_outlined,
                    color: AppTheme.jade,
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              if (_isMedical) ...[
                _fieldGap(),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc_outlined, color: AppTheme.jade),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _specialtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Specialty',
                          prefixIcon: Icon(Icons.science_outlined, color: AppTheme.jade),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              _fieldGap(),

              DropdownButtonFormField<TargetPotential>(
                value: _potential,
                decoration: const InputDecoration(
                  labelText: 'Target potential',
                  prefixIcon: Icon(Icons.star_outline, color: AppTheme.jade),
                ),
                items: TargetPotential.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              _potentialDot(p),
                              const SizedBox(width: 8),
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _potential = v!),
              ),
              _fieldGap(),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telephone',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.jade),
                ),
              ),
              _fieldGap(),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.jade),
                ),
              ),
              _fieldGap(),

              // GCO Status (Champ GCO avec icône ordinateur)
              DropdownButtonFormField<String>(
                value: _gcoStatus,
                decoration: const InputDecoration(
                  labelText: 'GCO (Gluco Control Online)',
                  prefixIcon: Icon(Icons.computer_outlined, color: AppTheme.jade),
                ),
                items: _gcoOptions
                    .map((opt) => DropdownMenuItem(
                          value: opt,
                          child: Text(opt, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _gcoStatus = v!),
              ),
            ]),

            // ── Structure & Location ────────────────────────────────────
            _sectionLabel('Structure et location', Icons.location_city_outlined),
            _card(children: [
              DropdownButtonFormField<String>(
                value: _structureType,
                decoration: const InputDecoration(
                  labelText: 'Structure type',
                  prefixIcon: Icon(Icons.business_outlined, color: AppTheme.jade),
                ),
                items: (_isPharma
                        ? ['Officine', 'Grossiste', 'CHU']
                        : ['Cabinet Privé', 'CHU', 'Clinique'])
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _structureType = v!),
              ),
              if (_isMedical) ...[
                _fieldGap(),
                DropdownButtonFormField<String>(
                  value: _patientLoad,
                  decoration: const InputDecoration(
                    labelText: 'Patient load / day',
                    prefixIcon: Icon(Icons.people_outline, color: AppTheme.jade),
                  ),
                  items: const [
                    DropdownMenuItem(value: '0-15', child: Text('Low  (0 – 15)')),
                    DropdownMenuItem(value: '16-30', child: Text('Medium  (16 – 30)')),
                    DropdownMenuItem(value: '30+', child: Text('High  (30+)')),
                  ],
                  onChanged: (v) => setState(() => _patientLoad = v!),
                ),
              ],
              _fieldGap(),

              ValueListenableBuilder<List<String>>(
                valueListenable: widget.state.wilayas,
                builder: (context, wilayas, _) {
                  return DropdownButtonFormField<String>(
                    value: _wilaya,
                    decoration: const InputDecoration(
                      labelText: 'Wilaya',
                      prefixIcon: Icon(Icons.map_outlined, color: AppTheme.jade),
                    ),
                    items: wilayas
                        .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                    onChanged: (v) async {
                      setState(() {
                        _wilaya = v;
                        _commune = null;
                      });
                      if (v != null) {
                        await widget.state.loadCommunesForWilaya(v);
                      }
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              _fieldGap(),

              ValueListenableBuilder<List<Locality>>(
                valueListenable: widget.state.localities,
                builder: (context, locs, _) {
                  final communes = locs
                      .where((l) => l.nomWilaya == _wilaya)
                      .map((l) => l.nomCommune)
                      .toSet()
                      .toList();
                  return DropdownButtonFormField<String>(
                    value: _commune,
                    decoration: const InputDecoration(
                      labelText: 'Commune',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.jade),
                    ),
                    items: communes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _commune = v),
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              _fieldGap(),

              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full address',
                  prefixIcon: Icon(Icons.home_outlined, color: AppTheme.jade),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ]),

            // ── Leave behind (Materiel Remis — Ultra Smooth Steppers) ────
            _sectionLabel('Leave behind', Icons.card_giftcard_outlined),
            _card(children: [
              _QuantityStepper(
                label: 'Qty vials',
                controller: _vialsCtrl,
                icon: Icons.science_outlined,
                onChanged: () => setState(() {}),
              ),
              _fieldGap(),
              _QuantityStepper(
                label: 'Meters',
                controller: _metersCtrl,
                icon: Icons.speed_outlined,
                onChanged: () => setState(() {}),
              ),
              _fieldGap(),
              _QuantityStepper(
                label: 'Brochure Médecin',
                controller: _brochureMCtrl,
                icon: Icons.menu_book_outlined,
                onChanged: () => setState(() {}),
              ),
              _fieldGap(),
              _QuantityStepper(
                label: 'Brochure Patient',
                controller: _brochurePatientCtrl,
                icon: Icons.auto_stories_outlined,
                onChanged: () => setState(() {}),
              ),
              _fieldGap(),
              _QuantityStepper(
                label: 'Poster',
                controller: _posterCtrl,
                icon: Icons.picture_in_picture_outlined,
                onChanged: () => setState(() {}),
              ),
              if (_isPharma) ...[
                _fieldGap(),
                _QuantityStepper(
                  label: 'Qty readers delivered',
                  controller: _readerCtrl,
                  icon: Icons.devices_outlined,
                  onChanged: () => setState(() {}),
                ),
              ],
            ]),

            // ── Notes ───────────────────────────────────────────────────
            _sectionLabel('Notes', Icons.notes_outlined),
            _card(children: [
              TextFormField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comment / observations',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.edit_note_outlined, color: AppTheme.jade),
                  ),
                ),
              ),
            ]),

            // ── Save button ─────────────────────────────────────────────
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_saving ? 'Saving…' : AppLocalizations.of(context)!.saveVisit),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  Widget _potentialDot(TargetPotential p) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppTheme.potentialAccent(p),
        shape: BoxShape.circle,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final visit = VisitRecord(
        id: const Uuid().v4(),
        date: _date,
        visitType: _visitType,
        targetName: _targetCtrl.text.trim(),
        gender: _isMedical ? _gender : null,
        specialty: _isMedical ? _specialtyCtrl.text : 'N/A',
        structureType: _structureType,
        potential: _potential,
        gcoStatus: _gcoStatus,
        address: _addressCtrl.text.trim(),
        wilaya: _wilaya!,
        commune: _commune!,
        telephone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        patientLoad: _isMedical ? _patientLoad : '0-15',
        durationMinutes: int.tryParse(_durationCtrl.text) ?? 0,
        qtyVials: int.tryParse(_vialsCtrl.text) ?? 0,
        qtyMeters: int.tryParse(_metersCtrl.text) ?? 0,
        qtyBrochureM: int.tryParse(_brochureMCtrl.text) ?? 0,
        qtyBrochurePatient: int.tryParse(_brochurePatientCtrl.text) ?? 0,
        qtyAffiche: int.tryParse(_posterCtrl.text) ?? 0,
        qtyReader: _isPharma ? int.tryParse(_readerCtrl.text) ?? 0 : 0,
        comment: _commentCtrl.text.trim(),
      );
      await widget.state.addVisit(visit);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.requiredFieldsMissing),
            backgroundColor: AppTheme.vermillion,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.label,
    required this.controller,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    int val = int.tryParse(controller.text) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E0D5), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.jade),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              if (val > 0) {
                controller.text = (val - 1).toString();
                onChanged();
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.gold.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove, size: 16, color: AppTheme.primary),
            ),
          ),
          SizedBox(
            width: 44,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          InkWell(
            onTap: () {
              controller.text = (val + 1).toString();
              onChanged();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.jade.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: AppTheme.jade),
            ),
          ),
        ],
      ),
    );
  }
}
