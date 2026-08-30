enum UserRole { admin, manager, medRep, pharmaRep }

enum VisitType { medical, pharmaceutical }

// ignore: constant_identifier_names
enum TargetPotential { KOL, A, B, C }

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'manager':
      return UserRole.manager;
    case 'pharma_rep':
      return UserRole.pharmaRep;
    default:
      return UserRole.medRep;
  }
}

VisitType visitTypeFromString(String value) =>
    value == 'pharmaceutical' ? VisitType.pharmaceutical : VisitType.medical;

String visitTypeToApi(VisitType type) =>
    type == VisitType.pharmaceutical ? 'pharmaceutical' : 'medical';

TargetPotential potentialFromString(String value) {
  switch (value) {
    case 'KOL':
      return TargetPotential.KOL;
    case 'A':
      return TargetPotential.A;
    case 'B':
      return TargetPotential.B;
    default:
      return TargetPotential.C;
  }
}

String potentialToApi(TargetPotential p) =>
    p == TargetPotential.KOL ? 'KOL' : p.name;

class AppUser {
  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.assignedRegions = '',
    this.telephone = '',
  });

  final int id;
  final String username;
  final String email;
  final UserRole role;
  final String assignedRegions;
  final String telephone;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String? ?? '',
        role: userRoleFromString(json['role'] as String? ?? 'med_rep'),
        assignedRegions: json['assigned_regions'] as String? ?? '',
        telephone: json['telephone'] as String? ?? '',
      );

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager;
  bool get isStaff => role == UserRole.admin || role == UserRole.manager;
  bool get isMedRep => role == UserRole.medRep;
  bool get isPharmaRep => role == UserRole.pharmaRep;

  VisitType get defaultVisitType =>
      isPharmaRep ? VisitType.pharmaceutical : VisitType.medical;
}

class Locality {
  Locality({
    required this.codeCommune,
    required this.nomCommune,
    required this.nomWilaya,
  });

  final String codeCommune;
  final String nomCommune;
  final String nomWilaya;

  factory Locality.fromJson(Map<String, dynamic> json) => Locality(
        codeCommune: json['code_commune'] as String,
        nomCommune: json['nom_commune'] as String,
        nomWilaya: json['nom_wilaya'] as String,
      );
}

class VisitRecord {
  VisitRecord({
    required this.id,
    required this.date,
    required this.visitType,
    required this.targetName,
    this.gender,
    this.specialty = 'N/A',
    required this.structureType,
    required this.potential,
    this.gcoStatus = 'Pas intéressé(e)',
    required this.address,
    required this.wilaya,
    required this.commune,
    required this.telephone,
    required this.email,
    this.patientLoad = '0-15',
    this.durationMinutes = 0,
    this.qtyReader = 0,
    this.qtyVials = 0,
    this.qtyMeters = 0,
    this.qtyBrochureM = 0,
    this.qtyBrochurePatient = 0,
    this.qtyAffiche = 0,
    this.photoUrl,
    this.comment,
    this.repUsername,
    this.objections = '',
    this.nextAction = '',
    this.nextActionDate,
    this.doctorId,
    this.doctorName,
    this.presentedProducts = const [],
  });

  final String id;
  final DateTime date;
  final VisitType visitType;
  final String targetName;
  final String? gender;
  final String specialty;
  final String structureType;
  final TargetPotential potential;
  final String gcoStatus;
  final String address;
  final String wilaya;
  final String commune;
  final String telephone;
  final String email;
  final String patientLoad;
  final int durationMinutes;
  final int qtyReader;
  final int qtyVials;
  final int qtyMeters;
  final int qtyBrochureM;
  final int qtyBrochurePatient;
  final int qtyAffiche;
  final String? photoUrl;
  final String? comment;
  final String? repUsername;
  final String objections;
  final String nextAction;
  final DateTime? nextActionDate;
  final int? doctorId;
  final String? doctorName;
  final List<String> presentedProducts;

  factory VisitRecord.fromJson(Map<String, dynamic> json) => VisitRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        visitType: visitTypeFromString(json['visit_type'] as String),
        targetName: json['target_name'] as String,
        gender: json['gender'] as String?,
        specialty: json['specialty'] as String? ?? 'N/A',
        structureType: json['structure_type'] as String,
        potential: potentialFromString(json['potential'] as String),
        gcoStatus: json['gco_status'] as String? ?? 'Pas intéressé(e)',
        address: json['address'] as String,
        wilaya: json['wilaya'] as String,
        commune: json['commune'] as String,
        telephone: json['telephone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        patientLoad: json['patient_load'] as String? ?? '0-15',
        durationMinutes: json['duration_minutes'] as int? ?? 0,
        qtyReader: json['qty_reader'] as int? ?? 0,
        qtyVials: json['qty_vials'] as int? ?? 0,
        qtyMeters: json['qty_meters'] as int? ?? 0,
        qtyBrochureM: json['qty_brochure_m'] as int? ?? 0,
        qtyBrochurePatient: json['qty_brochure_patient'] as int? ?? 0,
        qtyAffiche: json['qty_affiche'] as int? ?? 0,
        photoUrl: json['photo_url'] as String?,
        comment: json['comment'] as String?,
        repUsername: json['rep_username'] as String?,
        objections: json['objections'] as String? ?? '',
        nextAction: json['next_action'] as String? ?? '',
        nextActionDate: (json['next_action_date'] as String?) != null
            ? DateTime.tryParse(json['next_action_date'] as String)
            : null,
        doctorId: json['doctor'] as int?,
        doctorName: json['doctor_name'] as String?,
        presentedProducts: (json['presented_products'] as List?)
                ?.map((e) => (e as Map<String, dynamic>)['product_name']
                    ?.toString() ??
                    '')
                .where((s) => s.isNotEmpty)
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'visit_type': visitTypeToApi(visitType),
        'target_name': targetName,
        if (gender != null) 'gender': gender,
        'specialty': specialty,
        'structure_type': structureType,
        'potential': potentialToApi(potential),
        'gco_status': gcoStatus,
        'address': address,
        'wilaya': wilaya,
        'commune': commune,
        'telephone': telephone,
        'email': email,
        'patient_load': patientLoad,
        'duration_minutes': durationMinutes,
        'qty_reader': qtyReader,
        'qty_vials': qtyVials,
        'qty_meters': qtyMeters,
        'qty_brochure_m': qtyBrochureM,
        'qty_brochure_patient': qtyBrochurePatient,
        'qty_affiche': qtyAffiche,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
        if (objections.isNotEmpty) 'objections': objections,
        if (nextAction.isNotEmpty) 'next_action': nextAction,
        if (nextActionDate != null)
          'next_action_date':
              '${nextActionDate!.year}-${nextActionDate!.month.toString().padLeft(2, '0')}-${nextActionDate!.day.toString().padLeft(2, '0')}',
      };
}

class AdminKpis {
  AdminKpis({
    required this.totalVisits,
    required this.totalVials,
    required this.totalReaders,
    required this.activeReps,
    required this.byVisitType,
    required this.byPotential,
  });

  final int totalVisits;
  final int totalVials;
  final int totalReaders;
  final int activeReps;
  final Map<String, int> byVisitType;
  final Map<String, int> byPotential;

  factory AdminKpis.fromJson(Map<String, dynamic> json) => AdminKpis(
        totalVisits: json['total_visits'] as int? ?? 0,
        totalVials: json['total_vials'] as int? ?? 0,
        totalReaders: json['total_readers'] as int? ?? 0,
        activeReps: json['active_reps'] as int? ?? 0,
        byVisitType: Map<String, int>.from(json['by_visit_type'] as Map? ?? {}),
        byPotential:
            Map<String, int>.from(json['by_potential'] as Map? ?? {}),
      );
}

// ── Doctor / Pharmacy / Product ────────────────────────────────────────────

int _asInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
double _asDouble(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);

class Doctor {
  Doctor({
    required this.id,
    required this.name,
    this.gender = '',
    this.specialty = '',
    this.structureType = '',
    this.potential = TargetPotential.C,
    this.gcoStatus = '',
    this.address = '',
    this.wilaya = '',
    this.commune = '',
    this.telephone = '',
    this.email = '',
    this.visitCount = 0,
    this.lastVisitDate,
  });

  final int id;
  final String name;
  final String gender;
  final String specialty;
  final String structureType;
  final TargetPotential potential;
  final String gcoStatus;
  final String address;
  final String wilaya;
  final String commune;
  final String telephone;
  final String email;
  final int visitCount;
  final DateTime? lastVisitDate;

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: _asInt(json['id']),
        name: json['name'] as String? ?? '—',
        gender: json['gender'] as String? ?? '',
        specialty: json['specialty'] as String? ?? '',
        structureType: json['structure_type'] as String? ?? '',
        potential: potentialFromString(json['potential'] as String? ?? 'C'),
        gcoStatus: json['gco_status'] as String? ?? '',
        address: json['address'] as String? ?? '',
        wilaya: json['wilaya'] as String? ?? '',
        commune: json['commune'] as String? ?? '',
        telephone: json['telephone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        visitCount: _asInt(json['visit_count']),
        lastVisitDate: json['last_visit_date'] != null
            ? DateTime.tryParse(json['last_visit_date'].toString())
            : null,
      );
}

class Pharmacy {
  Pharmacy({
    required this.id,
    required this.name,
    this.structureType = '',
    this.potential = TargetPotential.C,
    this.wilaya = '',
    this.commune = '',
    this.telephone = '',
    this.email = '',
    this.address = '',
    this.visitCount = 0,
    this.lastVisitDate,
  });

  final int id;
  final String name;
  final String structureType;
  final TargetPotential potential;
  final String wilaya;
  final String commune;
  final String telephone;
  final String email;
  final String address;
  final int visitCount;
  final DateTime? lastVisitDate;

  factory Pharmacy.fromJson(Map<String, dynamic> json) => Pharmacy(
        id: _asInt(json['id']),
        name: json['name'] as String? ?? '—',
        structureType: json['structure_type'] as String? ?? '',
        potential: potentialFromString(json['potential'] as String? ?? 'C'),
        wilaya: json['wilaya'] as String? ?? '',
        commune: json['commune'] as String? ?? '',
        telephone: json['telephone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
        visitCount: _asInt(json['visit_count']),
        lastVisitDate: json['last_visit_date'] != null
            ? DateTime.tryParse(json['last_visit_date'].toString())
            : null,
      );
}

class Product {
  Product({required this.id, required this.name, this.category = ''});

  final int id;
  final String name;
  final String category;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: _asInt(json['id']),
        name: json['name'] as String? ?? '—',
        category: json['category'] as String? ?? '',
      );
}

class Prescription {
  Prescription({
    required this.id,
    this.productName = '',
    this.quantity = 0,
    this.status = 'pending',
    this.repUsername = '',
    this.createdAt,
  });

  final int id;
  final String productName;
  final int quantity;
  final String status;
  final String repUsername;
  final DateTime? createdAt;

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: _asInt(json['id']),
        productName: json['product_name'] as String? ?? '',
        quantity: _asInt(json['quantity']),
        status: json['status'] as String? ?? 'pending',
        repUsername: json['rep_username'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}

// ── Doctor history ────────────────────────────────────────────────────────

class HistoryNote {
  HistoryNote({required this.date, required this.text, this.rep = ''});
  final DateTime? date;
  final String text;
  final String rep;

  factory HistoryNote.fromJson(Map<String, dynamic> json) => HistoryNote(
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString())
            : null,
        text: json['text'] as String? ?? '',
        rep: json['rep'] as String? ?? '',
      );
}

class DoctorHistory {
  DoctorHistory({
    required this.doctor,
    required this.visitCount,
    this.lastVisitDate,
    this.firstVisitDate,
    this.productsPresented = const [],
    this.materialGiven = const {},
    this.orders = const [],
    this.ordersCount = 0,
    this.remarks = const [],
    this.objections = const [],
    this.nextActionText,
    this.nextActionDate,
    this.visits = const [],
  });

  final Doctor doctor;
  final int visitCount;
  final DateTime? lastVisitDate;
  final DateTime? firstVisitDate;
  final List<String> productsPresented;
  final Map<String, int> materialGiven;
  final List<Prescription> orders;
  final int ordersCount;
  final List<HistoryNote> remarks;
  final List<HistoryNote> objections;
  final String? nextActionText;
  final DateTime? nextActionDate;
  final List<VisitRecord> visits;

  factory DoctorHistory.fromJson(Map<String, dynamic> json) {
    final na = json['next_action'] as Map<String, dynamic>?;
    return DoctorHistory(
      doctor: Doctor.fromJson(json['doctor'] as Map<String, dynamic>),
      visitCount: _asInt(json['visit_count']),
      lastVisitDate: json['last_visit_date'] != null
          ? DateTime.tryParse(json['last_visit_date'].toString())
          : null,
      firstVisitDate: json['first_visit_date'] != null
          ? DateTime.tryParse(json['first_visit_date'].toString())
          : null,
      productsPresented: (json['products_presented'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      materialGiven: Map<String, int>.from(
        (json['material_given'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), _asInt(v))),
      ),
      orders: (json['orders'] as List? ?? [])
          .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
          .toList(),
      ordersCount: _asInt(json['orders_count']),
      remarks: (json['remarks'] as List? ?? [])
          .map((e) => HistoryNote.fromJson(e as Map<String, dynamic>))
          .toList(),
      objections: (json['objections'] as List? ?? [])
          .map((e) => HistoryNote.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextActionText: na?['text'] as String?,
      nextActionDate: na?['date'] != null
          ? DateTime.tryParse(na!['date'].toString())
          : null,
      visits: (json['visits'] as List? ?? [])
          .map((e) => VisitRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Manager dashboard ────────────────────────────────────────────────────

class CoverageStat {
  CoverageStat({this.covered = 0, this.total = 0, this.pct = 0});
  final int covered;
  final int total;
  final double pct;
  factory CoverageStat.fromJson(Map<String, dynamic> json) => CoverageStat(
        covered: _asInt(json['covered']),
        total: _asInt(json['total']),
        pct: _asDouble(json['pct']),
      );
}

class ObjectiveStat {
  ObjectiveStat({this.target, this.actual = 0, this.pct});
  final int? target;
  final int actual;
  final double? pct;
  factory ObjectiveStat.fromJson(Map<String, dynamic>? json) => ObjectiveStat(
        target: json?['target'] as int?,
        actual: _asInt(json?['actual']),
        pct: json?['pct'] != null ? _asDouble(json!['pct']) : null,
      );
}

class ManagerDashboard {
  ManagerDashboard({
    required this.visitsToday,
    required this.visitsWeek,
    required this.visitsMonth,
    required this.visitsTotal,
    required this.avgVisitDuration,
    required this.objectiveAttainment,
    required this.doctorCoverage,
    required this.pharmacyCoverage,
    required this.newDoctorsMonth,
    required this.promoMaterialTotal,
    required this.promoBreakdown,
    required this.ordersMonth,
    required this.ordersByStatus,
    required this.byVisitType,
    required this.byPotential,
    required this.activeReps,
  });

  final int visitsToday;
  final int visitsWeek;
  final int visitsMonth;
  final int visitsTotal;
  final double avgVisitDuration;
  final ObjectiveStat objectiveAttainment;
  final CoverageStat doctorCoverage;
  final CoverageStat pharmacyCoverage;
  final int newDoctorsMonth;
  final int promoMaterialTotal;
  final Map<String, int> promoBreakdown;
  final int ordersMonth;
  final Map<String, int> ordersByStatus;
  final Map<String, int> byVisitType;
  final Map<String, int> byPotential;
  final int activeReps;

  factory ManagerDashboard.fromJson(Map<String, dynamic> json) {
    final v = json['visits'] as Map<String, dynamic>? ?? {};
    final promo = json['promo_material'] as Map<String, dynamic>? ?? {};
    final orders = json['orders'] as Map<String, dynamic>? ?? {};
    Map<String, int> mapInt(dynamic m) => Map<String, int>.from(
        (m as Map? ?? {}).map((k, val) => MapEntry(k.toString(), _asInt(val))));
    return ManagerDashboard(
      visitsToday: _asInt(v['today']),
      visitsWeek: _asInt(v['week']),
      visitsMonth: _asInt(v['month']),
      visitsTotal: _asInt(v['total']),
      avgVisitDuration: _asDouble(json['avg_visit_duration']),
      objectiveAttainment: ObjectiveStat.fromJson(
          json['objective_attainment'] as Map<String, dynamic>?),
      doctorCoverage: CoverageStat.fromJson(
          json['doctor_coverage'] as Map<String, dynamic>? ?? {}),
      pharmacyCoverage: CoverageStat.fromJson(
          json['pharmacy_coverage'] as Map<String, dynamic>? ?? {}),
      newDoctorsMonth: _asInt(json['new_doctors_month']),
      promoMaterialTotal: _asInt(promo['total']),
      promoBreakdown: mapInt(promo['breakdown']),
      ordersMonth: _asInt(orders['month']),
      ordersByStatus: mapInt(orders['by_status']),
      byVisitType: mapInt(json['by_visit_type']),
      byPotential: mapInt(json['by_potential']),
      activeReps: _asInt(json['active_reps']),
    );
  }
}

// ── Delegate stats + leaderboard ────────────────────────────────────────

class DelegateStats {
  DelegateStats({
    required this.username,
    required this.visitsToday,
    required this.visitsWeek,
    required this.visitsMonth,
    required this.objective,
    required this.coveragePct,
    required this.ordersMonth,
    required this.newDoctorsMonth,
    required this.avgDuration,
    this.territory = '',
  });

  final String username;
  final int visitsToday;
  final int visitsWeek;
  final int visitsMonth;
  final ObjectiveStat objective;
  final double coveragePct;
  final int ordersMonth;
  final int newDoctorsMonth;
  final double avgDuration;
  final String territory;

  factory DelegateStats.fromJson(Map<String, dynamic> json) => DelegateStats(
        username: json['username'] as String? ?? '',
        visitsToday: _asInt(json['visits_today']),
        visitsWeek: _asInt(json['visits_week']),
        visitsMonth: _asInt(json['visits_month']),
        objective:
            ObjectiveStat.fromJson(json['objective'] as Map<String, dynamic>?),
        coveragePct: _asDouble(json['coverage_pct']),
        ordersMonth: _asInt(json['orders_month']),
        newDoctorsMonth: _asInt(json['new_doctors_month']),
        avgDuration: _asDouble(json['avg_duration']),
        territory: json['territory']?.toString() ?? '',
      );
}

class LeaderboardRow {
  LeaderboardRow({
    required this.rank,
    required this.username,
    required this.visitsMonth,
    required this.objectivePct,
    required this.coveragePct,
    required this.ordersMonth,
    required this.score,
  });

  final int rank;
  final String username;
  final int visitsMonth;
  final double? objectivePct;
  final double coveragePct;
  final int ordersMonth;
  final double score;

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) => LeaderboardRow(
        rank: _asInt(json['rank']),
        username: json['username'] as String? ?? '',
        visitsMonth: _asInt(json['visits_month']),
        objectivePct: (json['objective'] as Map<String, dynamic>?)?['pct'] != null
            ? _asDouble((json['objective'] as Map<String, dynamic>)['pct'])
            : null,
        coveragePct: _asDouble(json['coverage_pct']),
        ordersMonth: _asInt(json['orders_month']),
        score: _asDouble(json['score']),
      );
}

// ── Alerts + map ────────────────────────────────────────────────────────

class VisitAlert {
  VisitAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.detail,
    this.entityType = '',
    this.entityId,
  });

  final String type;
  final String severity;
  final String title;
  final String detail;
  final String entityType;
  final int? entityId;

  factory VisitAlert.fromJson(Map<String, dynamic> json) => VisitAlert(
        type: json['type'] as String? ?? '',
        severity: json['severity'] as String? ?? 'low',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        entityType: json['entity_type'] as String? ?? '',
        entityId: json['entity_id'] as int?,
      );
}

class WilayaAggregate {
  WilayaAggregate({
    required this.wilaya,
    required this.count,
    this.reps = 0,
    this.kol = 0,
    this.doctors = 0,
    this.pharmacies = 0,
    this.lastVisit,
  });

  final String wilaya;
  final int count;
  final int reps;
  final int kol;
  final int doctors;
  final int pharmacies;
  final DateTime? lastVisit;

  factory WilayaAggregate.fromJson(Map<String, dynamic> json) => WilayaAggregate(
        wilaya: json['wilaya'] as String? ?? '—',
        count: _asInt(json['count']),
        reps: _asInt(json['reps']),
        kol: _asInt(json['kol']),
        doctors: _asInt(json['doctors']),
        pharmacies: _asInt(json['pharmacies']),
        lastVisit: json['last_visit'] != null
            ? DateTime.tryParse(json['last_visit'].toString())
            : null,
      );
}
