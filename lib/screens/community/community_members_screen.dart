import 'package:flutter/material.dart';

import '../../services/community_service.dart';
import '../../models/community_model.dart';
import '../../models/user_model.dart';

class CommunityMembersScreen extends StatefulWidget {
  final Community community;
  final AppUser currentUser;

  const CommunityMembersScreen({
    super.key,
    required this.community,
    required this.currentUser,
  });

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  final _communityService = CommunityService();

  bool get isCreator => widget.community.createdBy == widget.currentUser.userId;
  bool get isAlumni => widget.currentUser.isAlumni;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Members',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<CommunityMember>>(
        stream: _communityService.streamMembers(widget.community.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data ?? [];

          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No members yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Member count header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                child: Text(
                  '${members.length} member${members.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return _buildMemberCard(isDark, members[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemberCard(bool isDark, CommunityMember member) {
    final isMemberAlumni = member.role == 'alumni';
    final isMemberCreator = member.odId == widget.community.createdBy;
    final isSelf = member.odId == widget.currentUser.userId;
    // Alumni creator can kick students only
    final canKick = isCreator && isAlumni && member.role == 'student' && !isSelf;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMemberAlumni
                  ? [const Color(0xFFFF6B9D), const Color(0xFFFFA726)]
                  : [const Color(0xFF6C63FF), const Color(0xFF4E9FFF)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              (member.name?.isNotEmpty == true)
                  ? member.name![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.name ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isMemberCreator)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Creator',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF00D4AA),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMemberAlumni
                    ? const Color(0xFFFF6B9D).withOpacity(0.2)
                    : const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isMemberAlumni ? 'Alumni' : 'Student',
                style: TextStyle(
                  fontSize: 10,
                  color: isMemberAlumni
                      ? const Color(0xFFFF6B9D)
                      : const Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Joined ${_formatDate(member.joinedAt)}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        trailing: canKick
            ? IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.red),
                onPressed: () => _showKickDialog(member),
                tooltip: 'Remove member',
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  void _showKickDialog(CommunityMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove "${member.name ?? 'this member'}" from the community?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _kickMember(member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _kickMember(CommunityMember member) async {
    try {
      await _communityService.kickMember(
        communityId: widget.community.id,
        memberId: member.odId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name ?? 'Member'} has been removed'),
            backgroundColor: const Color(0xFF6C63FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
