enum UserRole { admin, medRep, pharmaRep }

enum VisitType { medical, pharmaceutical }

// ignore: constant_identifier_names
enum TargetPotential { KOL, A, B, C }

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
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
