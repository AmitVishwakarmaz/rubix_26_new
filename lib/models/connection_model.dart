import 'package:cloud_firestore/cloud_firestore.dart';

/// Connection request between student and alumni
class ConnectionRequest {
  final String id;
  final String studentId;
  final String alumniId;
  final String studentName;
  final String alumniName;
  final String status; // "pending", "accepted", "rejected"
  final String? message;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConnectionRequest({
    required this.id,
    required this.studentId,
    required this.alumniId,
    required this.studentName,
    required this.alumniName,
    required this.status,
    this.message,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'alumniId': alumniId,
      'studentName': studentName,
      'alumniName': alumniName,
      'status': status,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory ConnectionRequest.fromMap(Map<String, dynamic> map, String docId) {
    return ConnectionRequest(
      id: docId,
      studentId: map['studentId'] ?? '',
      alumniId: map['alumniId'] ?? '',
      studentName: map['studentName'] ?? '',
      alumniName: map['alumniName'] ?? '',
      status: map['status'] ?? 'pending',
      message: map['message'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}

/// Chat message between connected users
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool read;
  final String type; // "text" or "meeting"
  final Map<String, dynamic>? meetingData;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.read = false,
    this.type = 'text',
    this.meetingData,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      'type': type,
      'meetingData': meetingData,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] ?? false,
      type: map['type'] ?? 'text',
      meetingData: map['meetingData'] != null 
          ? Map<String, dynamic>.from(map['meetingData'])
          : null,
    );
  }

  bool get isMeeting => type == 'meeting';

  // Getters for meeting data
  String? get meetingRoomName => meetingData?['roomName'];
  String? get meetingToken => meetingData?['token'];
  String? get meetingTitle => meetingData?['meetingTitle'];
  DateTime? get meetingScheduledTime => 
      (meetingData?['scheduledTime'] as Timestamp?)?.toDate();
}

/// Chat room between two users
class ChatRoom {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String docId) {
    return ChatRoom(
      id: docId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }
}
