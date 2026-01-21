import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/referral_model.dart';

/// Service for referral-related Firestore operations
class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _referralsRef =>
      _firestore.collection('referrals');

  CollectionReference<Map<String, dynamic>> get _referralRequestsRef =>
      _firestore.collection('referral_requests');

  // ═══════════════════════════════════════════════════════════════════════════
  // REFERRAL AVAILABILITY (Alumni)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create or update alumni's referral availability
  Future<String> setReferralAvailability({
    required String alumniId,
    required String alumniName,
    String? alumniProfileImage,
    required String company,
    required String role,
    String? department,
    List<String> skills = const [],
    String? requirements,
    bool isAvailable = true,
  }) async {
    // Check if alumni already has a referral entry
    final existing = await _referralsRef
        .where('alumniId', isEqualTo: alumniId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update existing
      final docId = existing.docs.first.id;
      await _referralsRef.doc(docId).update({
        'company': company,
        'role': role,
        if (department != null) 'department': department,
        'skills': skills,
        if (requirements != null) 'requirements': requirements,
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.now(),
      });
      return docId;
    } else {
      // Create new
      final docRef = await _referralsRef.add({
        'alumniId': alumniId,
        'alumniName': alumniName,
        if (alumniProfileImage != null) 'alumniProfileImage': alumniProfileImage,
        'company': company,
        'role': role,
        if (department != null) 'department': department,
        'skills': skills,
        if (requirements != null) 'requirements': requirements,
        'isAvailable': isAvailable,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return docRef.id;
    }
  }

  /// Toggle referral availability on/off
  Future<void> toggleAvailability(String referralId, bool isAvailable) async {
    await _referralsRef.doc(referralId).update({
      'isAvailable': isAvailable,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get alumni's referral availability
  Future<ReferralAvailability?> getMyReferral(String alumniId) async {
    final snapshot = await _referralsRef
        .where('alumniId', isEqualTo: alumniId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ReferralAvailability.fromMap(
        snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  /// Stream alumni's referral availability
  Stream<ReferralAvailability?> streamMyReferral(String alumniId) {
    return _referralsRef
        .where('alumniId', isEqualTo: alumniId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ReferralAvailability.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  /// Stream all available referrals (for students)
  Stream<List<ReferralAvailability>> streamAvailableReferrals() {
    return _referralsRef
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final referrals = snapshot.docs
          .map((doc) => ReferralAvailability.fromMap(doc.data(), doc.id))
          .toList();
      // Sort client-side to avoid composite index requirement
      referrals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return referrals;
    });
  }

  /// Search referrals by company
  Stream<List<ReferralAvailability>> searchReferralsByCompany(String query) {
    // Firestore doesn't support substring search, so we filter client-side
    return streamAvailableReferrals().map((referrals) => referrals
        .where((r) =>
            r.company.toLowerCase().contains(query.toLowerCase()) ||
            r.role.toLowerCase().contains(query.toLowerCase()) ||
            r.alumniName.toLowerCase().contains(query.toLowerCase()))
        .toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFERRAL REQUESTS (Student)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send a referral request
  Future<void> sendReferralRequest({
    required String referralId,
    required String alumniId,
    required String alumniName,
    required String company,
    required String role,
    required String studentId,
    required String studentName,
    String? studentEmail,
    String? studentProfileImage,
    String? message,
  }) async {
    // Check if already requested
    final existing = await _referralRequestsRef
        .where('referralId', isEqualTo: referralId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already requested a referral from this alumni');
    }

    await _referralRequestsRef.add({
      'referralId': referralId,
      'alumniId': alumniId,
      'alumniName': alumniName,
      'company': company,
      'role': role,
      'studentId': studentId,
      'studentName': studentName,
      if (studentEmail != null) 'studentEmail': studentEmail,
      if (studentProfileImage != null) 'studentProfileImage': studentProfileImage,
      'status': 'pending',
      if (message != null) 'message': message,
      'createdAt': Timestamp.now(),
    });
  }

  /// Stream requests received by alumni
  Stream<List<ReferralRequest>> streamAlumniRequests(String alumniId) {
    return _referralRequestsRef
        .where('alumniId', isEqualTo: alumniId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream pending requests for alumni
  Stream<List<ReferralRequest>> streamPendingRequests(String alumniId) {
    return _referralRequestsRef
        .where('alumniId', isEqualTo: alumniId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => ReferralRequest.fromMap(doc.data(), doc.id))
          .where((r) => r.isPending || r.isResumeRequested)
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  /// Stream requests sent by student
  Stream<List<ReferralRequest>> streamStudentRequests(String studentId) {
    return _referralRequestsRef
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Check if student already requested this referral
  Future<ReferralRequest?> getExistingRequest(
      String referralId, String studentId) async {
    final snapshot = await _referralRequestsRef
        .where('referralId', isEqualTo: referralId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ReferralRequest.fromMap(
        snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REQUEST ACTIONS (Alumni)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Accept a referral request
  Future<void> acceptRequest(String requestId, {String? note}) async {
    await _referralRequestsRef.doc(requestId).update({
      'status': 'accepted',
      if (note != null) 'alumniNote': note,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Reject a referral request
  Future<void> rejectRequest(String requestId, {String? note}) async {
    await _referralRequestsRef.doc(requestId).update({
      'status': 'rejected',
      if (note != null) 'alumniNote': note,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Request resume from student
  Future<void> requestResume(String requestId, {String? note}) async {
    await _referralRequestsRef.doc(requestId).update({
      'status': 'resumeRequested',
      if (note != null) 'alumniNote': note,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Student uploads resume
  Future<void> uploadResume(String requestId, String resumeUrl) async {
    await _referralRequestsRef.doc(requestId).update({
      'resumeUrl': resumeUrl,
      'status': 'pending', // Back to pending for review
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a referral request
  Future<void> deleteRequest(String requestId) async {
    await _referralRequestsRef.doc(requestId).delete();
  }
}
