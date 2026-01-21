import 'package:cloud_firestore/cloud_firestore.dart';

/// Alumni's referral availability - marks if they can give referrals
class ReferralAvailability {
  final String id;
  final String alumniId;
  final String alumniName;
  final String? alumniProfileImage;
  
  final String company;
  final String role;
  final String? department;
  final List<String> skills;
  final String? requirements;
  final bool isAvailable;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  ReferralAvailability({
    required this.id,
    required this.alumniId,
    required this.alumniName,
    this.alumniProfileImage,
    required this.company,
    required this.role,
    this.department,
    this.skills = const [],
    this.requirements,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReferralAvailability.fromMap(Map<String, dynamic> map, String docId) {
    return ReferralAvailability(
      id: docId,
      alumniId: map['alumniId'] ?? '',
      alumniName: map['alumniName'] ?? '',
      alumniProfileImage: map['alumniProfileImage'],
      company: map['company'] ?? '',
      role: map['role'] ?? '',
      department: map['department'],
      skills: List<String>.from(map['skills'] ?? []),
      requirements: map['requirements'],
      isAvailable: map['isAvailable'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alumniId': alumniId,
      'alumniName': alumniName,
      if (alumniProfileImage != null) 'alumniProfileImage': alumniProfileImage,
      'company': company,
      'role': role,
      if (department != null) 'department': department,
      'skills': skills,
      if (requirements != null) 'requirements': requirements,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ReferralAvailability copyWith({
    String? company,
    String? role,
    String? department,
    List<String>? skills,
    String? requirements,
    bool? isAvailable,
  }) {
    return ReferralAvailability(
      id: id,
      alumniId: alumniId,
      alumniName: alumniName,
      alumniProfileImage: alumniProfileImage,
      company: company ?? this.company,
      role: role ?? this.role,
      department: department ?? this.department,
      skills: skills ?? this.skills,
      requirements: requirements ?? this.requirements,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Status of a referral request
enum ReferralStatus {
  pending,
  accepted,
  rejected,
  resumeRequested,
}

/// Student's referral request to an alumni
class ReferralRequest {
  final String id;
  final String referralId;
  final String alumniId;
  final String alumniName;
  final String company;
  final String role;
  
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final String? studentProfileImage;
  
  final ReferralStatus status;
  final String? message;
  final String? resumeUrl;
  final String? alumniNote;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReferralRequest({
    required this.id,
    required this.referralId,
    required this.alumniId,
    required this.alumniName,
    required this.company,
    required this.role,
    required this.studentId,
    required this.studentName,
    this.studentEmail,
    this.studentProfileImage,
    this.status = ReferralStatus.pending,
    this.message,
    this.resumeUrl,
    this.alumniNote,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReferralRequest.fromMap(Map<String, dynamic> map, String docId) {
    return ReferralRequest(
      id: docId,
      referralId: map['referralId'] ?? '',
      alumniId: map['alumniId'] ?? '',
      alumniName: map['alumniName'] ?? '',
      company: map['company'] ?? '',
      role: map['role'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentEmail: map['studentEmail'],
      studentProfileImage: map['studentProfileImage'],
      status: _parseStatus(map['status']),
      message: map['message'],
      resumeUrl: map['resumeUrl'],
      alumniNote: map['alumniNote'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static ReferralStatus _parseStatus(String? status) {
    switch (status) {
      case 'accepted':
        return ReferralStatus.accepted;
      case 'rejected':
        return ReferralStatus.rejected;
      case 'resumeRequested':
        return ReferralStatus.resumeRequested;
      default:
        return ReferralStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'referralId': referralId,
      'alumniId': alumniId,
      'alumniName': alumniName,
      'company': company,
      'role': role,
      'studentId': studentId,
      'studentName': studentName,
      if (studentEmail != null) 'studentEmail': studentEmail,
      if (studentProfileImage != null) 'studentProfileImage': studentProfileImage,
      'status': status.name,
      if (message != null) 'message': message,
      if (resumeUrl != null) 'resumeUrl': resumeUrl,
      if (alumniNote != null) 'alumniNote': alumniNote,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  bool get isPending => status == ReferralStatus.pending;
  bool get isAccepted => status == ReferralStatus.accepted;
  bool get isRejected => status == ReferralStatus.rejected;
  bool get isResumeRequested => status == ReferralStatus.resumeRequested;
}
