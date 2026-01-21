import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connection_model.dart';
import '../models/user_model.dart';

/// Service for all connection and chat operations
class ConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection('connection_requests');

  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  // ═══════════════════════════════════════════════════════════════════════════
  // ALUMNI BROWSING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream all alumni (verified preferred)
  Stream<List<AppUser>> streamAllAlumni() {
    return _usersRef
        .where('role', isEqualTo: 'alumni')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Search alumni by name
  Future<List<AppUser>> searchAlumniByName(String query) async {
    if (query.isEmpty) return [];
    
    final snapshot = await _usersRef
        .where('role', isEqualTo: 'alumni')
        .get();
    
    final alumni = snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data(), doc.id))
        .where((user) => 
            user.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    return alumni;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTION REQUESTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send connection request from student to alumni
  Future<void> sendConnectionRequest({
    required String studentId,
    required String alumniId,
    required String studentName,
    required String alumniName,
    String? message,
  }) async {
    // Check if request already exists
    final existing = await _requestsRef
        .where('studentId', isEqualTo: studentId)
        .where('alumniId', isEqualTo: alumniId)
        .get();
    
    if (existing.docs.isNotEmpty) {
      throw Exception('Request already sent to this alumni');
    }

    await _requestsRef.add({
      'studentId': studentId,
      'alumniId': alumniId,
      'studentName': studentName,
      'alumniName': alumniName,
      'status': 'pending',
      'message': message,
      'createdAt': Timestamp.now(),
    });
  }

  /// Stream requests sent by student (all statuses)
  Stream<List<ConnectionRequest>> streamStudentRequests(String studentId) {
    return _requestsRef
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConnectionRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream only PENDING requests sent by student (for Requests tab)
  Stream<List<ConnectionRequest>> streamStudentPendingRequests(String studentId) {
    return _requestsRef
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ConnectionRequest.fromMap(doc.data(), doc.id))
              .where((r) => r.status == 'pending')
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// Stream pending requests for alumni (simplified query - client-side filter for ordering)
  Stream<List<ConnectionRequest>> streamAlumniPendingRequests(String alumniId) {
    return _requestsRef
        .where('alumniId', isEqualTo: alumniId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ConnectionRequest.fromMap(doc.data(), doc.id))
              .where((r) => r.status == 'pending')
              .toList();
          // Sort client-side to avoid needing composite index
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// Revoke/cancel a pending connection request (student only)
  Future<void> revokeRequest(String requestId) async {
    await _requestsRef.doc(requestId).delete();
  }

  /// Accept connection request
  Future<void> acceptRequest(String requestId) async {
    await _requestsRef.doc(requestId).update({
      'status': 'accepted',
      'updatedAt': Timestamp.now(),
    });
  }

  /// Reject connection request
  Future<void> rejectRequest(String requestId) async {
    await _requestsRef.doc(requestId).update({
      'status': 'rejected',
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get request status between student and alumni
  Future<ConnectionRequest?> getRequestStatus(String studentId, String alumniId) async {
    final snapshot = await _requestsRef
        .where('studentId', isEqualTo: studentId)
        .where('alumniId', isEqualTo: alumniId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return ConnectionRequest.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  /// Stream request status between student and alumni
  Stream<ConnectionRequest?> streamRequestStatus(String studentId, String alumniId) {
    return _requestsRef
        .where('studentId', isEqualTo: studentId)
        .where('alumniId', isEqualTo: alumniId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ConnectionRequest.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream student's accepted connections (alumni they're connected to)
  Stream<List<ConnectionRequest>> streamStudentConnections(String studentId) {
    return _requestsRef
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ConnectionRequest.fromMap(doc.data(), doc.id))
              .where((r) => r.status == 'accepted')
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// Stream alumni's accepted connections (students they're connected to)
  Stream<List<ConnectionRequest>> streamAlumniConnections(String alumniId) {
    return _requestsRef
        .where('alumniId', isEqualTo: alumniId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ConnectionRequest.fromMap(doc.data(), doc.id))
              .where((r) => r.status == 'accepted')
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// Get user by ID
  Future<AppUser?> getUser(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate chat ID from two user IDs (sorted to ensure consistency)
  String _generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Send a chat message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final chatId = _generateChatId(senderId, receiverId);
    
    // Create or update chat room
    await _chatsRef.doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessage': text,
      'lastMessageAt': Timestamp.now(),
    }, SetOptions(merge: true));

    // Add message to subcollection
    await _chatsRef.doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.now(),
      'read': false,
    });
  }

  /// Stream chat messages between two users
  Stream<List<ChatMessage>> streamMessages(String userId1, String userId2) {
    final chatId = _generateChatId(userId1, userId2);
    
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    final chatId = _generateChatId(senderId, receiverId);
    
    final unread = await _chatsRef
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: senderId)
        .where('read', isEqualTo: false)
        .get();
    
    for (final doc in unread.docs) {
      await doc.reference.update({'read': true});
    }
  }

  /// Send a meeting invite message
  Future<void> sendMeetingInvite({
    required String senderId,
    required String receiverId,
    required String roomName,
    required String token,
    required String meetingTitle,
    required DateTime scheduledTime,
  }) async {
    final chatId = _generateChatId(senderId, receiverId);
    
    // Create or update chat room
    await _chatsRef.doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessage': '📹 Meeting: $meetingTitle',
      'lastMessageAt': Timestamp.now(),
    }, SetOptions(merge: true));

    // Add meeting message to subcollection
    await _chatsRef.doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': 'Meeting Invite',
      'type': 'meeting',
      'meetingData': {
        'roomName': roomName,
        'token': token,
        'meetingTitle': meetingTitle,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'createdBy': senderId,
      },
      'createdAt': Timestamp.now(),
      'read': false,
    });
  }
}
