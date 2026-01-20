import 'package:cloud_firestore/cloud_firestore.dart';

class JobPost {
  final String id;
  final String title;
  final String company;
  final String description;
  final List<String> requirements;
  final String postedByUserId;
  final String postedByName;
  final String location;
  final String type; // Full-time, Internship, etc.
  final DateTime postedDate;
  final String? applicationUrl;

  JobPost({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.requirements,
    required this.postedByUserId,
    required this.postedByName,
    required this.location,
    required this.type,
    required this.postedDate,
    this.applicationUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'description': description,
      'requirements': requirements,
      'postedByUserId': postedByUserId,
      'postedByName': postedByName,
      'location': location,
      'type': type,
      'postedDate': Timestamp.fromDate(postedDate),
      'applicationUrl': applicationUrl,
    };
  }

  factory JobPost.fromMap(Map<String, dynamic> map, String id) {
    return JobPost(
      id: id,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      description: map['description'] ?? '',
      requirements: List<String>.from(map['requirements'] ?? []),
      postedByUserId: map['postedByUserId'] ?? '',
      postedByName: map['postedByName'] ?? '',
      location: map['location'] ?? '',
      type: map['type'] ?? '',
      postedDate: (map['postedDate'] as Timestamp).toDate(),
      applicationUrl: map['applicationUrl'],
    );
  }
}

class MentorshipRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String alumniId;
  final String alumniName;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime date;

  MentorshipRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.alumniId,
    required this.alumniName,
    required this.message,
    required this.status,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'alumniId': alumniId,
      'alumniName': alumniName,
      'message': message,
      'status': status,
      'date': Timestamp.fromDate(date),
    };
  }

  factory MentorshipRequest.fromMap(Map<String, dynamic> map, String id) {
    return MentorshipRequest(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      alumniId: map['alumniId'] ?? '',
      alumniName: map['alumniName'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}

/// Event model for storing event data in Firestore
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String time;
  final String type; // 'In-Person', 'Online', 'Hybrid'
  final String location;
  final int maxAttendees;
  final List<String> registeredUserIds;
  final List<String> tags;
  final List<String> speakers;
  final String createdByUserId;
  final String createdByName;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.time,
    required this.type,
    required this.location,
    required this.maxAttendees,
    required this.registeredUserIds,
    required this.tags,
    required this.speakers,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdAt,
  });

  int get attendeesCount => registeredUserIds.length;
  bool get isFull => attendeesCount >= maxAttendees;
  bool get isPast => eventDate.isBefore(DateTime.now());
  bool get isUpcoming => eventDate.isAfter(DateTime.now());

  bool isUserRegistered(String userId) => registeredUserIds.contains(userId);

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'time': time,
      'type': type,
      'location': location,
      'maxAttendees': maxAttendees,
      'registeredUserIds': registeredUserIds,
      'tags': tags,
      'speakers': speakers,
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventDate: (map['eventDate'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      type: map['type'] ?? 'In-Person',
      location: map['location'] ?? '',
      maxAttendees: map['maxAttendees'] ?? 0,
      registeredUserIds: List<String>.from(map['registeredUserIds'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      speakers: List<String>.from(map['speakers'] ?? []),
      createdByUserId: map['createdByUserId'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

/// SessionBooking model for storing session booking data in Firestore
class SessionBooking {
  final String id;
  final String studentId;
  final String studentName;
  final String alumniId;
  final String alumniName;
  final String purpose;
  final String duration;
  final String date;
  final String time;
  final String notes;
  final String status; // 'pending', 'accepted', 'rejected', 'completed'
  final DateTime createdAt;
  final String? meetingLink;

  SessionBooking({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.alumniId,
    required this.alumniName,
    required this.purpose,
    required this.duration,
    required this.date,
    required this.time,
    required this.notes,
    required this.status,
    required this.createdAt,
    this.meetingLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'alumniId': alumniId,
      'alumniName': alumniName,
      'purpose': purpose,
      'duration': duration,
      'date': date,
      'time': time,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'meetingLink': meetingLink,
    };
  }

  factory SessionBooking.fromMap(Map<String, dynamic> map, String id) {
    return SessionBooking(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      alumniId: map['alumniId'] ?? '',
      alumniName: map['alumniName'] ?? '',
      purpose: map['purpose'] ?? '',
      duration: map['duration'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      meetingLink: map['meetingLink'],
    );
  }
}