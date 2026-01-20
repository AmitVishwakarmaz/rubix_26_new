import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
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

  // ──────────────────────────────────────────────
  //  Resource Management
  // ──────────────────────────────────────────────

  /// Upload PDF file to Firebase Storage
  Future<String> uploadPdfToStorage(File file, String fileName) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('resources/$fileName');
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }

  /// Create a new resource
  Future<void> createResource(Resource resource) async {
    await _firestore.collection('resources').doc(resource.id).set(resource.toFirestore());
  }

  /// Stream all resources
  Stream<List<Resource>> streamResources() {
    return _firestore.collection('resources')
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Resource.fromFirestore(doc))
            .toList());
  }

  /// Stream resources by category
  Stream<List<Resource>> streamResourcesByCategory(String category) {
    if (category == ResourceCategory.all) {
      return streamResources();
    }
    return _firestore.collection('resources')
        .where('category', isEqualTo: category)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Resource.fromFirestore(doc))
            .toList());
  }

  /// High-level method to upload a resource (Google Drive Link and metadata)
  Future<bool> uploadResource({
    required String title,
    required String description,
    required String category,
    required String driveLink,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('User profile not found');
      }

      final userName = userDoc.data()!['name'] ?? 'Unknown Alumni';
      final resourceId = const Uuid().v4();
      
      // Create Resource object with the Drive link stored in pdfUrl field
      final resource = Resource(
        id: resourceId,
        title: title,
        description: description,
        pdfUrl: driveLink.trim(),
        category: category,
        uploadedBy: currentUser.uid,
        uploadedByName: userName,
        uploadDate: DateTime.now(),
      );
      
      // Save to Firestore
      await createResource(resource);
      
      return true;
    } catch (e) {
      print('Error uploading resource: $e');
      return false;
    }
  }

  /// Delete a resource
  Future<void> deleteResource(String resourceId) async {
    try {
      await _firestore.collection('resources').doc(resourceId).delete();
    } catch (e) {
      throw Exception('Failed to delete resource: $e');
    }
  }

  /// Get resources uploaded by a specific user
  Stream<List<Resource>> streamUserResources(String userId) {
    return _firestore.collection('resources')
        .where('uploadedBy', isEqualTo: userId)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Resource.fromFirestore(doc))
            .toList());
  }

  /// Search resources by title or description
  Future<List<Resource>> searchResources(String query) async {
    try {
      final snapshot = await _firestore.collection('resources').get();
      final allResources = snapshot.docs
          .map((doc) => Resource.fromFirestore(doc))
          .toList();
      
      final lowerQuery = query.toLowerCase();
      return allResources.where((resource) {
        return resource.title.toLowerCase().contains(lowerQuery) ||
               resource.description.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Error searching resources: $e');
      return [];
    }
  }

  /// Get matched alumni based on student interests
  Future<List<AppUser>> getMatchedAlumni(List<String> interests) async {
    try {
      if (interests.isEmpty) return [];

      final snapshot = await _usersCollection
          .where('role', isEqualTo: 'alumni')
          .where('verificationStatus', isEqualTo: 'verified')
          .get();

      final List<AppUser> allAlumni = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();

      // Filter alumni who match any of the interests
      return allAlumni.where((alumni) {
        final industry = alumni.industry?.toLowerCase() ?? '';
        final jobRole = alumni.jobRole?.toLowerCase() ?? '';
        final mentorInterests = alumni.mentorshipInterests?.map((e) => e.toLowerCase()).toList() ?? [];

        return interests.any((interest) {
          final lowInterest = interest.toLowerCase();
          return industry.contains(lowInterest) ||
                 jobRole.contains(lowInterest) ||
                 mentorInterests.any((mi) => mi.contains(lowInterest));
        });
      }).toList();
    } catch (e) {
      print('Error matching alumni: $e');
      return [];
    }
  }

  /// Stream matched alumni based on student interests
  Stream<List<AppUser>> streamMatchedAlumni(List<String> interests) {
    if (interests.isEmpty) return Stream.value([]);

    return _usersCollection
        .where('role', isEqualTo: 'alumni')
        .where('verificationStatus', isEqualTo: 'verified')
        .snapshots()
        .map((snapshot) {
      final allAlumni = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();

      return allAlumni.where((alumni) {
        final industry = alumni.industry?.toLowerCase() ?? '';
        final jobRole = alumni.jobRole?.toLowerCase() ?? '';
        final mentorInterests = alumni.mentorshipInterests?.map((e) => e.toLowerCase()).toList() ?? [];

        return interests.any((interest) {
          final lowInterest = interest.toLowerCase();
          return industry.contains(lowInterest) ||
                 jobRole.contains(lowInterest) ||
                 mentorInterests.any((mi) => mi.contains(lowInterest));
        });
      }).toList();
    });
  }

  /// Send mentorship request
  Future<void> sendMentorshipRequest(MentorshipRequest request) async {
    await _firestore.collection('mentorship_requests').doc(request.id).set(request.toMap());
  }

  // ──────────────────────────────────────────────
  //  Session Booking Management
  // ──────────────────────────────────────────────

  /// Create a new session booking
  Future<void> createSessionBooking(SessionBooking booking) async {
    await _firestore.collection('session_bookings').doc(booking.id).set(booking.toMap());
  }

  /// Stream all session bookings for a student
  Stream<List<SessionBooking>> streamStudentBookings(String studentId) {
    return _firestore.collection('session_bookings')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SessionBooking.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream all session bookings for a mentor
  Stream<List<SessionBooking>> streamMentorBookings(String mentorId) {
    return _firestore.collection('session_bookings')
        .where('mentorId', isEqualTo: mentorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SessionBooking.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Update session booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('session_bookings').doc(bookingId).update({'status': status});
  }

  /// Get a specific session booking
  Future<SessionBooking?> getSessionBooking(String bookingId) async {
    final doc = await _firestore.collection('session_bookings').doc(bookingId).get();
    if (!doc.exists || doc.data() == null) return null;
    return SessionBooking.fromMap(doc.data()!, doc.id);
  }

  /// Delete a session booking
  Future<void> deleteSessionBooking(String bookingId) async {
    await _firestore.collection('session_bookings').doc(bookingId).delete();
  }
}