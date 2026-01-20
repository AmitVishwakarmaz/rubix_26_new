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
}
