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

class SessionBooking {
  final String id;
  final String studentId;
  final String studentName;
  final String mentorId;
  final String mentorName;
  final String purpose;
  final String duration;
  final String date;
  final String time;
  final String? notes;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime createdAt;

  SessionBooking({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.mentorId,
    required this.mentorName,
    required this.purpose,
    required this.duration,
    required this.date,
    required this.time,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'purpose': purpose,
      'duration': duration,
      'date': date,
      'time': time,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SessionBooking.fromMap(Map<String, dynamic> map, String id) {
    return SessionBooking(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      mentorId: map['mentorId'] ?? '',
      mentorName: map['mentorName'] ?? '',
      purpose: map['purpose'] ?? '',
      duration: map['duration'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      notes: map['notes'],
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}