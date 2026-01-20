import 'package:cloud_firestore/cloud_firestore.dart';

/// Community model for the main community entity
class Community {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final String createdByRole; // "alumni" or "student"
  final DateTime createdAt;
  final bool isActive;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdByRole,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory Community.fromMap(Map<String, dynamic> map, String docId) {
    return Community(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByRole: map['createdByRole'] ?? 'alumni',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}

/// Community member model for subcollection
class CommunityMember {
  final String odId;
  final String role; // "student" or "alumni"
  final DateTime joinedAt;
  final String? name;
  final String? email;

  CommunityMember({
    required this.odId,
    required this.role,
    required this.joinedAt,
    this.name,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    };
  }

  factory CommunityMember.fromMap(Map<String, dynamic> map, String docId) {
    return CommunityMember(
      odId: docId,
      role: map['role'] ?? 'student',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      name: map['name'],
      email: map['email'],
    );
  }
}

/// Chat message model for community messages
class CommunityMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // "student" or "alumni"
  final String text;
  final DateTime createdAt;

  CommunityMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CommunityMessage.fromMap(Map<String, dynamic> map, String docId) {
    return CommunityMessage(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      senderRole: map['senderRole'] ?? 'student',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Poll model for community polls (alumni only can create)
class Poll {
  final String id;
  final String question;
  final List<String> options;
  final String createdBy;
  final DateTime createdAt;
  final Map<String, int>? voteCounts; // option -> count

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.createdBy,
    required this.createdAt,
    this.voteCounts,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Poll.fromMap(Map<String, dynamic> map, String docId) {
    return Poll(
      id: docId,
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      voteCounts: map['voteCounts'] != null
          ? Map<String, int>.from(map['voteCounts'])
          : null,
    );
  }
}

/// Vote model for poll votes
class Vote {
  final String odId;
  final String option;
  final DateTime votedAt;

  Vote({
    required this.odId,
    required this.option,
    required this.votedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'option': option,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }

  factory Vote.fromMap(Map<String, dynamic> map, String docId) {
    return Vote(
      odId: docId,
      option: map['option'] ?? '',
      votedAt: (map['votedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// User communities reference for fast tab queries
class UserCommunities {
  final String odId;
  final List<String> joinedCommunities;
  final List<String> createdCommunities;

  UserCommunities({
    required this.odId,
    required this.joinedCommunities,
    required this.createdCommunities,
  });

  Map<String, dynamic> toMap() {
    return {
      'joinedCommunities': joinedCommunities,
      'createdCommunities': createdCommunities,
    };
  }

  factory UserCommunities.fromMap(Map<String, dynamic> map, String docId) {
    return UserCommunities(
      odId: docId,
      joinedCommunities: List<String>.from(map['joinedCommunities'] ?? []),
      createdCommunities: List<String>.from(map['createdCommunities'] ?? []),
    );
  }
}