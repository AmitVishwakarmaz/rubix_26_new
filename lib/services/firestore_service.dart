import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/new_model.dart';
import '../models/resource_model.dart';

/// Service for Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get users collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Check if user document exists
  Future<bool> userExists(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    return doc.exists;
  }

  /// Get user by ID
  Future<AppUser?> getUser(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  /// Create new user document
  Future<void> createUser(AppUser user) async {
    await _usersCollection.doc(user.userId).set(user.toMap());
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String role) async {
    await _usersCollection.doc(userId).update({'role': role});
  }

  /// Get user role
  Future<String?> getUserRole(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data()!['role'] as String?;
  }

  /// Update user profile with all fields
  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    await _usersCollection.doc(userId).update(profileData);
  }

  /// Get all users with pending verification for a specific role
  Future<List<AppUser>> getPendingUsers(String role) async {
    final querySnapshot = await _usersCollection
        .where('role', isEqualTo: role)
        .where('verificationStatus', isEqualTo: 'pending')
        .where('profileCompleted', isEqualTo: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => AppUser.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Approve user verification
  Future<void> approveUser(String userId) async {
    await _usersCollection.doc(userId).update({
      'verificationStatus': 'verified',
    });
  }

  /// Reject user verification
  Future<void> rejectUser(String userId) async {
    await _usersCollection.doc(userId).update({
      'verificationStatus': 'rejected',
    });
  }

  /// Get user verification status
  Future<VerificationStatus> getVerificationStatus(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists || doc.data() == null) return VerificationStatus.pending;
    final status = doc.data()!['verificationStatus'] as String?;
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  /// Check if user profile is completed
  Future<bool> isProfileCompleted(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists || doc.data() == null) return false;
    return doc.data()!['profileCompleted'] ?? false;
  }

  /// Stream of pending users for real-time updates in admin dashboard
  Stream<List<AppUser>> streamPendingUsers(String role) {
    return _usersCollection
        .where('role', isEqualTo: role)
        .where('verificationStatus', isEqualTo: 'pending')
        .where('profileCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.data(), doc.id))
            .toList());
  }
  /// Stream user data
  Stream<AppUser?> streamUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!, doc.id);
    });
  }

  /// Get mentees for an alumni (accepted requests)
  Stream<List<MentorshipRequest>> getMyMentees(String alumniId) {
    return _firestore.collection('mentorship_requests')
        .where('alumniId', isEqualTo: alumniId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MentorshipRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get all mentorship requests for an alumni
  Stream<List<MentorshipRequest>> getMentorshipRequestsForAlumni(String alumniId) {
    return _firestore.collection('mentorship_requests')
        .where('alumniId', isEqualTo: alumniId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MentorshipRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Create a job post
  Future<void> createJobPost(JobPost job) async {
    await _firestore.collection('jobs').doc(job.id).set(job.toMap());
  }

  /// Update mentorship request status
  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore.collection('mentorship_requests').doc(requestId).update({'status': status});
  }

  /// Stream all alumni users for mentor matching
  Stream<List<AppUser>> streamAllUsers() {
    return _usersCollection
        .where('role', isEqualTo: 'alumni')
        .where('verificationStatus', isEqualTo: 'verified')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT-RELATED METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get events collection reference
  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  /// Create a new event
  Future<void> createEvent(Event event) async {
    await _eventsCollection.doc(event.id).set(event.toMap());
  }

  /// Stream all upcoming events (sorted by date ascending)
  Stream<List<Event>> streamUpcomingEvents() {
    return _eventsCollection
        .where('eventDate', isGreaterThan: Timestamp.now())
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream all past events (sorted by date descending)
  Stream<List<Event>> streamPastEvents() {
    return _eventsCollection
        .where('eventDate', isLessThan: Timestamp.now())
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream events created by a specific user (alumni)
  Stream<List<Event>> streamMyCreatedEvents(String userId) {
    return _eventsCollection
        .where('createdByUserId', isEqualTo: userId)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get the next upcoming event (latest one)
  Stream<Event?> streamNextEvent() {
    return _eventsCollection
        .where('eventDate', isGreaterThan: Timestamp.now())
        .orderBy('eventDate', descending: false)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Event.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
        });
  }

  /// Register a user for an event
  Future<bool> registerForEvent(String eventId, String userId) async {
    final docRef = _eventsCollection.doc(eventId);
    
    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return false;
      
      final event = Event.fromMap(doc.data()!, doc.id);
      if (event.isFull) return false;
      if (event.isUserRegistered(userId)) return false;
      
      final updatedList = [...event.registeredUserIds, userId];
      transaction.update(docRef, {'registeredUserIds': updatedList});
      return true;
    });
  }

  /// Unregister a user from an event
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    final docRef = _eventsCollection.doc(eventId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;
      
      final event = Event.fromMap(doc.data()!, doc.id);
      final updatedList = event.registeredUserIds.where((id) => id != userId).toList();
      transaction.update(docRef, {'registeredUserIds': updatedList});
    });
  }

  /// Get total count of verified alumni
  Future<int> getAlumniCount() async {
    final snapshot = await _usersCollection
        .where('role', isEqualTo: 'alumni')
        .where('verificationStatus', isEqualTo: 'verified')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Stream total count of verified alumni
  Stream<int> streamAlumniCount() {
    return _usersCollection
        .where('role', isEqualTo: 'alumni')
        .where('verificationStatus', isEqualTo: 'verified')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVED ALUMNI METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save an alumni to user's saved list
  Future<void> saveAlumni(String userId, String alumniId) async {
    await _usersCollection.doc(userId).update({
      'savedAlumniIds': FieldValue.arrayUnion([alumniId]),
    });
  }

  /// Unsave an alumni from user's saved list
  Future<void> unsaveAlumni(String userId, String alumniId) async {
    await _usersCollection.doc(userId).update({
      'savedAlumniIds': FieldValue.arrayRemove([alumniId]),
    });
  }

  /// Check if alumni is saved
  Future<bool> isAlumniSaved(String userId, String alumniId) async {
    final user = await getUser(userId);
    final savedIds = user?.savedAlumniIds ?? [];
    return savedIds.contains(alumniId);
  }

  /// Stream saved alumni list
  Stream<List<AppUser>> streamSavedAlumni(String userId) {
    return _usersCollection.doc(userId).snapshots().asyncMap((userDoc) async {
      final data = userDoc.data();
      if (data == null) return <AppUser>[];
      
      final savedIds = List<String>.from(data['savedAlumniIds'] ?? []);
      if (savedIds.isEmpty) return <AppUser>[];
      
      final futures = savedIds.map((id) => getUser(id));
      final users = await Future.wait(futures);
      return users.whereType<AppUser>().toList();
    });
  }

  /// Get unique industries from all alumni (for dynamic filters)
  Future<List<String>> getUniqueIndustries() async {
    final snapshot = await _usersCollection
        .where('role', isEqualTo: 'alumni')
        .where('verificationStatus', isEqualTo: 'verified')
        .get();
    
    final industries = <String>{};
    for (final doc in snapshot.docs) {
      final industry = doc.data()['industry'] as String?;
      if (industry != null && industry.isNotEmpty) {
        industries.add(industry);
      }
    }
    return industries.toList()..sort();
  }

  /// Stream unique industries from all alumni
  Stream<List<String>> streamUniqueIndustries() {
    return _usersCollection
        .where('role', isEqualTo: 'alumni')
        .where('verificationStatus', isEqualTo: 'verified')
        .snapshots()
        .map((snapshot) {
          final industries = <String>{};
          for (final doc in snapshot.docs) {
            final industry = doc.data()['industry'] as String?;
            if (industry != null && industry.isNotEmpty) {
              industries.add(industry);
            }
          }
          return industries.toList()..sort();
        });
  }

  /// Stream upcoming events excluding those created by the given user
  Stream<List<Event>> streamUpcomingEventsExcludingOwn(String userId) {
    return _eventsCollection
        .where('eventDate', isGreaterThan: Timestamp.now())
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .where((event) => event.createdByUserId != userId)
            .toList());
  }

  /// Get the next upcoming event not created by the user
  Stream<Event?> streamNextEventExcludingOwn(String userId) {
    return _eventsCollection
        .where('eventDate', isGreaterThan: Timestamp.now())
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => Event.fromMap(doc.data(), doc.id))
              .where((event) => event.createdByUserId != userId)
              .toList();
          return events.isEmpty ? null : events.first;
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESOURCE-RELATED METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get resources collection reference
  CollectionReference<Map<String, dynamic>> get _resourcesCollection =>
      _firestore.collection('resources');

  /// Stream all resources (sorted by upload date descending)
  Stream<List<Resource>> streamResources() {
    return _resourcesCollection
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Resource.fromFirestore(doc))
            .toList());
  }

  /// Upload a new resource
  Future<void> uploadResource({
    required String title,
    required String description,
    required String category,
    required String driveLink,
  }) async {
    // Get current user info from Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    
    String uploadedBy = '';
    String uploadedByName = 'Unknown';
    
    if (currentUser != null) {
      uploadedBy = currentUser.uid;
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        uploadedByName = userDoc.data()!['name'] ?? currentUser.displayName ?? 'Unknown';
      }
    }

    await _resourcesCollection.add({
      'title': title,
      'description': description,
      'category': category,
      'pdfUrl': driveLink,
      'driveLink': driveLink,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'uploadDate': Timestamp.now(),
    });
  }

  // ==================== MENTORSHIP REQUESTS ====================

  /// Get mentorship requests collection reference
  CollectionReference<Map<String, dynamic>> get _mentorshipRequestsCollection =>
      _firestore.collection('mentorship_requests');

  /// Send a mentorship request
  Future<void> sendMentorshipRequest(MentorshipRequest request) async {
    await _mentorshipRequestsCollection.doc(request.id).set(request.toMap());
  }

  /// Get mentorship requests for an alumni
  Stream<List<MentorshipRequest>> streamMentorshipRequestsForAlumni(String alumniId) {
    return _mentorshipRequestsCollection
        .where('alumniId', isEqualTo: alumniId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MentorshipRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get mentorship requests sent by a student
  Stream<List<MentorshipRequest>> streamMentorshipRequestsForStudent(String studentId) {
    return _mentorshipRequestsCollection
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MentorshipRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Update mentorship request status
  Future<void> updateMentorshipRequestStatus(String requestId, String status) async {
    await _mentorshipRequestsCollection.doc(requestId).update({'status': status});
  }

  // ==================== SESSION BOOKINGS ====================

  /// Get session bookings collection reference
  CollectionReference<Map<String, dynamic>> get _sessionBookingsCollection =>
      _firestore.collection('session_bookings');

  /// Book a session
  Future<void> bookSession(SessionBooking session) async {
    print('📅 Booking session: ${session.id}');
    print('📅 Alumni ID: ${session.alumniId}');
    print('📅 Student ID: ${session.studentId}');
    await _sessionBookingsCollection.doc(session.id).set(session.toMap());
    print('✅ Session booked successfully');
  }

  /// Stream all sessions for an alumni (filter by status on client side to avoid index issues)
  Stream<List<SessionBooking>> streamAllSessionsForAlumni(String alumniId) {
    print('🔍 Streaming sessions for alumni: $alumniId');
    return _sessionBookingsCollection
        .where('alumniId', isEqualTo: alumniId)
        .snapshots()
        .map((snapshot) {
          print('📊 Found ${snapshot.docs.length} sessions for alumni');
          return snapshot.docs
              .map((doc) => SessionBooking.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Stream pending sessions for an alumni (uses client-side filtering)
  Stream<List<SessionBooking>> streamPendingSessionsForAlumni(String alumniId) {
    return streamAllSessionsForAlumni(alumniId).map((sessions) {
      final pending = sessions.where((s) => s.status == 'pending').toList();
      print('⏳ Pending sessions: ${pending.length}');
      return pending..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Stream accepted sessions for an alumni (uses client-side filtering)
  Stream<List<SessionBooking>> streamAcceptedSessionsForAlumni(String alumniId) {
    return streamAllSessionsForAlumni(alumniId).map((sessions) {
      final accepted = sessions.where((s) => s.status == 'accepted').toList();
      print('✅ Accepted sessions: ${accepted.length}');
      return accepted..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Stream all sessions for a student
  Stream<List<SessionBooking>> streamSessionsForStudent(String studentId) {
    return _sessionBookingsCollection
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SessionBooking.fromMap(doc.data(), doc.id))
            .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Update session status
  Future<void> updateSessionStatus(String sessionId, String status, {String? meetingLink}) async {
    final updates = <String, dynamic>{'status': status};

    // Generate meeting link if accepting and none provided
    if (status == 'accepted' && meetingLink == null) {
      // Create a unique room name for the meeting
      updates['meetingLink'] = 'session_${const Uuid().v4().substring(0, 8)}';
    } else if (meetingLink != null) {
      updates['meetingLink'] = meetingLink;
    }

    await _sessionBookingsCollection.doc(sessionId).update(updates);

    // Increment session counts if completed
    if (status == 'completed') {
      try {
        final doc = await _sessionBookingsCollection.doc(sessionId).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            final studentId = data['studentId'];
            final alumniId = data['alumniId'];

            // Increment for student and add XP
            await _usersCollection.doc(studentId).update({
              'totalSessions': FieldValue.increment(1),
              'xp': FieldValue.increment(50),
            });

            // Increment for alumni
            await _usersCollection.doc(alumniId).update({
              'totalSessions': FieldValue.increment(1),
            });
          }
        }
      } catch (e) {
        print('Error updating session counts: $e');
      }
    }
  }

  /// Get pending sessions count for alumni
  Future<int> getPendingSessionsCount(String alumniId) async {
    final snapshot = await _sessionBookingsCollection
        .where('alumniId', isEqualTo: alumniId)
        .get();
    return snapshot.docs.where((doc) => doc.data()['status'] == 'pending').length;
  }
}