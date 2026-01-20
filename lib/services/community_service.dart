import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_model.dart';

/// Service for all community-related Firestore operations
class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _communitiesRef =>
      _firestore.collection('communities');

  CollectionReference<Map<String, dynamic>> get _userCommunitiesRef =>
      _firestore.collection('user_communities');

  // ─────────────────────────────────────────────────────────────
  //  Community CRUD
  // ─────────────────────────────────────────────────────────────

  /// Create a new community (alumni only)
  Future<String> createCommunity({
    required String name,
    required String description,
    required String creatorId,
    required String creatorRole,
    required String creatorName,
  }) async {
    final docRef = _communitiesRef.doc();
    final community = Community(
      id: docRef.id,
      name: name,
      description: description,
      createdBy: creatorId,
      createdByRole: creatorRole,
      createdAt: DateTime.now(),
      isActive: true,
    );

    await docRef.set(community.toMap());

    // Add creator as first member
    await docRef.collection('members').doc(creatorId).set({
      'role': creatorRole,
      'joinedAt': Timestamp.now(),
      'name': creatorName,
    });

    // Update user_communities
    await _userCommunitiesRef.doc(creatorId).set({
      'joinedCommunities': FieldValue.arrayUnion([docRef.id]),
      'createdCommunities': FieldValue.arrayUnion([docRef.id]),
    }, SetOptions(merge: true));

    return docRef.id;
  }

  /// Get a single community by ID
  Future<Community?> getCommunity(String communityId) async {
    final doc = await _communitiesRef.doc(communityId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Community.fromMap(doc.data()!, doc.id);
  }

  /// Stream all active communities (for "All" tab)
  Stream<List<Community>> streamAllCommunities() {
    return _communitiesRef
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Community.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream communities created by user (for "Yours" tab - alumni)
  Stream<List<Community>> streamCreatedCommunities(String userId) {
    return _communitiesRef
        .where('createdBy', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Community.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream communities user has joined (for "Joined" tab)
  Stream<List<Community>> streamJoinedCommunities(String userId) {
    return _userCommunitiesRef.doc(userId).snapshots().asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) return <Community>[];

      final joinedIds = List<String>.from(doc.data()!['joinedCommunities'] ?? []);
      if (joinedIds.isEmpty) return <Community>[];

      // Firestore 'whereIn' limited to 10, so batch if needed
      final communities = <Community>[];
      for (var i = 0; i < joinedIds.length; i += 10) {
        final batch = joinedIds.skip(i).take(10).toList();
        final snapshot = await _communitiesRef
            .where(FieldPath.documentId, whereIn: batch)
            .where('isActive', isEqualTo: true)
            .get();
        communities.addAll(
          snapshot.docs.map((doc) => Community.fromMap(doc.data(), doc.id)),
        );
      }
      return communities;
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  Member Management
  // ─────────────────────────────────────────────────────────────

  /// Join a community
  Future<void> joinCommunity({
    required String communityId,
    required String odId,
    required String role,
    required String name,
  }) async {
    // Add to members subcollection
    await _communitiesRef.doc(communityId).collection('members').doc(odId).set({
      'role': role,
      'joinedAt': Timestamp.now(),
      'name': name,
    });

    // Update user_communities
    await _userCommunitiesRef.doc(odId).set({
      'joinedCommunities': FieldValue.arrayUnion([communityId]),
    }, SetOptions(merge: true));
  }

  /// Leave a community (self-removal)
  Future<void> leaveCommunity({
    required String communityId,
    required String odId,
  }) async {
    await _communitiesRef.doc(communityId).collection('members').doc(odId).delete();

    await _userCommunitiesRef.doc(odId).update({
      'joinedCommunities': FieldValue.arrayRemove([communityId]),
    });
  }

  /// Kick a member from community (alumni creator only, students only)
  Future<void> kickMember({
    required String communityId,
    required String memberId,
  }) async {
    // Remove from members subcollection
    await _communitiesRef.doc(communityId).collection('members').doc(memberId).delete();

    // Remove from user_communities
    await _userCommunitiesRef.doc(memberId).update({
      'joinedCommunities': FieldValue.arrayRemove([communityId]),
    });
  }

  /// Check if user is a member of community
  Future<bool> isMember(String communityId, String odId) async {
    final doc = await _communitiesRef
        .doc(communityId)
        .collection('members')
        .doc(odId)
        .get();
    return doc.exists;
  }

  /// Stream members of a community
  Stream<List<CommunityMember>> streamMembers(String communityId) {
    return _communitiesRef
        .doc(communityId)
        .collection('members')
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityMember.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ─────────────────────────────────────────────────────────────
  //  Messages (Chat)
  // ─────────────────────────────────────────────────────────────

  /// Send a message to community chat
  Future<void> sendMessage({
    required String communityId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    final message = CommunityMessage(
      id: '',
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: text,
      createdAt: DateTime.now(),
    );

    await _communitiesRef.doc(communityId).collection('messages').add(message.toMap());
  }

  /// Stream messages for a community
  Stream<List<CommunityMessage>> streamMessages(String communityId) {
    return _communitiesRef
        .doc(communityId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ─────────────────────────────────────────────────────────────
  //  Polls
  // ─────────────────────────────────────────────────────────────

  /// Create a poll (alumni only)
  Future<String> createPoll({
    required String communityId,
    required String question,
    required List<String> options,
    required String creatorId,
  }) async {
    final docRef = _communitiesRef.doc(communityId).collection('polls').doc();
    final poll = Poll(
      id: docRef.id,
      question: question,
      options: options,
      createdBy: creatorId,
      createdAt: DateTime.now(),
    );

    await docRef.set(poll.toMap());
    return docRef.id;
  }

  /// Stream polls for a community
  Stream<List<Poll>> streamPolls(String communityId) {
    return _communitiesRef
        .doc(communityId)
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Poll.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Vote on a poll (one vote per user)
  Future<void> votePoll({
    required String communityId,
    required String pollId,
    required String odId,
    required String option,
  }) async {
    final voteRef = _communitiesRef
        .doc(communityId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(odId);

    await voteRef.set({
      'option': option,
      'votedAt': Timestamp.now(),
    });
  }

  /// Get user's vote on a poll
  Future<Vote?> getUserVote(String communityId, String pollId, String odId) async {
    final doc = await _communitiesRef
        .doc(communityId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(odId)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return Vote.fromMap(doc.data()!, doc.id);
  }

  /// Stream vote counts for a poll
  Stream<Map<String, int>> streamVoteCounts(String communityId, String pollId) {
    return _communitiesRef
        .doc(communityId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .snapshots()
        .map((snapshot) {
      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final option = doc.data()['option'] as String?;
        if (option != null) {
          counts[option] = (counts[option] ?? 0) + 1;
        }
      }
      return counts;
    });
  }

  /// Stream user's vote on a poll
  Stream<Vote?> streamUserVote(String communityId, String pollId, String odId) {
    return _communitiesRef
        .doc(communityId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(odId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Vote.fromMap(doc.data()!, doc.id);
    });
  }
}