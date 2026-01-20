import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/new_model.dart';

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
}