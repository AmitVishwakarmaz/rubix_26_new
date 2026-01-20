/// Verification status for user profiles
enum VerificationStatus {
  pending,
  verified,
  rejected,
}

/// User model matching Firestore schema with extended profile fields
class AppUser {
  final String userId;
  final String name;
  final String email;
  final String role; // "student", "alumni", or "admin"
  final VerificationStatus verificationStatus;
  final bool profileCompleted;
  
  // Student-specific fields
  final String? university;
  final String? degree;
  final String? major;
  final int? graduationYear;
  final List<String>? skills;
  final List<String>? careerInterests;
  final String? resumeUrl;
  
  // Alumni-specific fields
  final String? currentCompany;
  final String? jobRole;
  final String? industry;
  final String? linkedinUrl;
  final List<String>? mentorshipInterests;
  
  // Gamification & Stats
  final int xp;
  final int totalSessions;

  final String? profileImageUrl;

  AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.verificationStatus = VerificationStatus.pending,
    this.profileCompleted = false,
    this.xp = 0,
    this.totalSessions = 0,
    this.profileImageUrl,
    // Student fields
    this.university,
    this.degree,
    this.major,
    this.graduationYear,
    this.skills,
    this.careerInterests,
    this.resumeUrl,
    // Alumni fields
    this.currentCompany,
    this.jobRole,
    this.industry,
    this.linkedinUrl,
    this.mentorshipInterests,
  });

  /// Create from Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    return AppUser(
      userId: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      verificationStatus: _parseVerificationStatus(map['verificationStatus']),
      profileCompleted: map['profileCompleted'] ?? false,
      xp: map['xp'] ?? 0,
      totalSessions: map['totalSessions'] ?? 0,
      profileImageUrl: map['profileImageUrl'],
      // Student fields
      university: map['university'],
      degree: map['degree'],
      major: map['major'],
      graduationYear: map['graduationYear'],
      skills: (map['skills'] as List<dynamic>?)?.cast<String>(),
      careerInterests: (map['careerInterests'] as List<dynamic>?)?.cast<String>(),
      resumeUrl: map['resumeUrl'],
      // Alumni fields
      currentCompany: map['currentCompany'],
      jobRole: map['jobRole'],
      industry: map['industry'],
      linkedinUrl: map['linkedinUrl'],
      mentorshipInterests: (map['mentorshipInterests'] as List<dynamic>?)?.cast<String>(),
    );
  }

  static VerificationStatus _parseVerificationStatus(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'verificationStatus': verificationStatus.name,
      'profileCompleted': profileCompleted,
      'xp': xp,
      'totalSessions': totalSessions,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      // Student fields
      if (university != null) 'university': university,
      if (degree != null) 'degree': degree,
      if (major != null) 'major': major,
      if (graduationYear != null) 'graduationYear': graduationYear,
      if (skills != null) 'skills': skills,
      if (careerInterests != null) 'careerInterests': careerInterests,
      if (resumeUrl != null) 'resumeUrl': resumeUrl,
      // Alumni fields
      if (currentCompany != null) 'currentCompany': currentCompany,
      if (jobRole != null) 'jobRole': jobRole,
      if (industry != null) 'industry': industry,
      if (linkedinUrl != null) 'linkedinUrl': linkedinUrl,
      if (mentorshipInterests != null) 'mentorshipInterests': mentorshipInterests,
    };
  }

  bool get isStudent => role == 'student';
  bool get isAlumni => role == 'alumni';
  bool get isAdmin => role == 'admin';
  bool get isVerified => verificationStatus == VerificationStatus.verified;
  bool get isPending => verificationStatus == VerificationStatus.pending;
  bool get isRejected => verificationStatus == VerificationStatus.rejected;
  
  // Gamification Ranks
  String get rank {
    if (xp < 100) return 'Novice';
    if (xp < 300) return 'Pupil';
    if (xp < 600) return 'Specialist';
    if (xp < 1000) return 'Expert';
    return 'Grandmaster';
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? name,
    String? email,
    String? role,
    VerificationStatus? verificationStatus,
    bool? profileCompleted,
    int? xp,
    int? totalSessions,
    String? profileImageUrl,
    String? university,
    String? degree,
    String? major,
    int? graduationYear,
    List<String>? skills,
    List<String>? careerInterests,
    String? resumeUrl,
    String? currentCompany,
    String? jobRole,
    String? industry,
    String? linkedinUrl,
    List<String>? mentorshipInterests,
  }) {
    return AppUser(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      xp: xp ?? this.xp,
      totalSessions: totalSessions ?? this.totalSessions,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      major: major ?? this.major,
      graduationYear: graduationYear ?? this.graduationYear,
      skills: skills ?? this.skills,
      careerInterests: careerInterests ?? this.careerInterests,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      currentCompany: currentCompany ?? this.currentCompany,
      jobRole: jobRole ?? this.jobRole,
      industry: industry ?? this.industry,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      mentorshipInterests: mentorshipInterests ?? this.mentorshipInterests,
    );
  }
}