import 'package:cloud_firestore/cloud_firestore.dart';

/// Gamification service for XP rewards and ranking system
/// 
/// Rank System (similar to Codeforces):
/// - Level 1-2: Newbie (0-199 XP)
/// - Level 3-4: Pupil (200-499 XP)
/// - Level 5-6: Specialist (500-999 XP)
/// - Level 7-8: Expert (1000-1999 XP)
/// - Level 9-10: Master (2000-2999 XP)
/// - Level 11+: Grandmaster (3000+ XP)
class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // XP REWARDS TABLE
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const int xpUploadResource = 25;
  static const int xpDownloadResource = 5;
  static const int xpCompleteSession = 50;
  static const int xpSendConnection = 5;
  static const int xpAcceptConnection = 10;
  static const int xpJoinCommunity = 10;
  static const int xpCreatePoll = 15;
  static const int xpVoteInPoll = 5;
  static const int xpDailyLogin = 3;
  static const int xpCompleteProfile = 30;
  static const int xpFirstMentor = 20;

  // ═══════════════════════════════════════════════════════════════════════════
  // RANK SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Get rank title based on XP (like Codeforces)
  static String getRank(int xp) {
    final level = getLevel(xp);
    if (level <= 2) return 'Newbie';
    if (level <= 4) return 'Pupil';
    if (level <= 6) return 'Specialist';
    if (level <= 8) return 'Expert';
    if (level <= 10) return 'Master';
    return 'Grandmaster';
  }
  
  /// Get rank color based on XP
  static int getRankColorValue(int xp) {
    final level = getLevel(xp);
    if (level <= 2) return 0xFF808080;      // Gray - Newbie
    if (level <= 4) return 0xFF00C853;      // Green - Pupil
    if (level <= 6) return 0xFF00BCD4;      // Cyan - Specialist
    if (level <= 8) return 0xFF2196F3;      // Blue - Expert
    if (level <= 10) return 0xFFFF9800;     // Orange - Master
    return 0xFFE91E63;                       // Pink/Red - Grandmaster
  }
  
  /// Get level from XP (100 XP per level)
  static int getLevel(int xp) {
    return (xp / 100).floor() + 1;
  }
  
  /// Get XP needed for next level
  static int xpToNextLevel(int xp) {
    final currentLevel = getLevel(xp);
    final nextLevelXp = currentLevel * 100;
    return nextLevelXp - xp;
  }
  
  /// Get progress percentage to next level
  static double levelProgress(int xp) {
    return (xp % 100) / 100.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // XP AWARDING
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Award XP to a user
  Future<void> awardXP(String userId, int amount, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'xp': FieldValue.increment(amount),
      });
      
      // Log the XP gain for history/analytics
      await _firestore.collection('xp_logs').add({
        'userId': userId,
        'amount': amount,
        'reason': reason,
        'timestamp': Timestamp.now(),
      });
      
      print('Awarded $amount XP to $userId for: $reason');
    } catch (e) {
      print('Error awarding XP: $e');
    }
  }
  
  /// Check and award daily login XP (once per day)
  Future<bool> checkDailyLoginXP(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final data = userDoc.data();
      final lastLogin = data?['lastLoginDate'] as Timestamp?;
      final today = DateTime.now();
      
      if (lastLogin != null) {
        final lastLoginDate = lastLogin.toDate();
        if (lastLoginDate.year == today.year &&
            lastLoginDate.month == today.month &&
            lastLoginDate.day == today.day) {
          // Already logged in today
          return false;
        }
      }
      
      // Award daily login XP
      await _firestore.collection('users').doc(userId).update({
        'xp': FieldValue.increment(xpDailyLogin),
        'lastLoginDate': Timestamp.now(),
      });
      
      return true; // XP awarded
    } catch (e) {
      print('Error checking daily login: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVENIENCE METHODS FOR SPECIFIC ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> onResourceUpload(String userId) async {
    await awardXP(userId, xpUploadResource, 'Uploaded a resource');
  }
  
  Future<void> onResourceDownload(String userId) async {
    await awardXP(userId, xpDownloadResource, 'Downloaded a resource');
  }
  
  Future<void> onSessionComplete(String userId) async {
    await awardXP(userId, xpCompleteSession, 'Completed a mentorship session');
  }
  
  Future<void> onConnectionSent(String userId) async {
    await awardXP(userId, xpSendConnection, 'Sent a connection request');
  }
  
  Future<void> onConnectionAccepted(String userId) async {
    await awardXP(userId, xpAcceptConnection, 'Accepted a connection');
  }
  
  Future<void> onCommunityJoin(String userId) async {
    await awardXP(userId, xpJoinCommunity, 'Joined a community');
  }
  
  Future<void> onPollCreate(String userId) async {
    await awardXP(userId, xpCreatePoll, 'Created a poll');
  }
  
  Future<void> onPollVote(String userId) async {
    await awardXP(userId, xpVoteInPoll, 'Voted in a poll');
  }
  
  Future<void> onProfileComplete(String userId) async {
    await awardXP(userId, xpCompleteProfile, 'Completed profile setup');
  }
  
  Future<void> onFirstMentor(String userId) async {
    await awardXP(userId, xpFirstMentor, 'Connected with first mentor');
  }
}
