import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/connection_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/connection_model.dart';
import '../mentor_detail_screen.dart';
import 'chat_screen.dart';

class StudentConnectScreen extends StatefulWidget {
  const StudentConnectScreen({super.key});

  @override
  State<StudentConnectScreen> createState() => _StudentConnectScreenState();
}

class _StudentConnectScreenState extends State<StudentConnectScreen>
    with SingleTickerProviderStateMixin {
  final _connectionService = ConnectionService();
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  late TabController _tabController;
  AppUser? _currentUser;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _firestoreService.getUser(uid);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
      appBar: _buildAppBar(isDark),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllAlumniTab(isDark),
          _buildSentRequestsTab(isDark),
          _buildConnectionsTab(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: const Text(
        'Connect',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF6C63FF),
        labelColor: const Color(0xFF6C63FF),
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
        tabs: const [
          Tab(text: 'All Alumni'),
          Tab(text: 'Requests'),
          Tab(text: 'Connections'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALL ALUMNI TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAllAlumniTab(bool isDark) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search alumni by name...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
            ),
          ),
        ),
        // Alumni List
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: _connectionService.streamAllAlumni(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var alumni = snapshot.data ?? [];
              
              // Filter by search query
              if (_searchQuery.isNotEmpty) {
                alumni = alumni
                    .where((user) => user.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();
              }

              if (alumni.isEmpty) {
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
                        _searchQuery.isNotEmpty
                            ? 'No alumni found matching "$_searchQuery"'
                            : 'No alumni available',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: alumni.length,
                itemBuilder: (context, index) {
                  return _buildAlumniCard(isDark, alumni[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlumniCard(bool isDark, AppUser alumni) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF6B9D + (alumni.name.hashCode % 500)),
                    Color(0xFFFFA726 + (alumni.name.hashCode % 500)),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      alumni.name.isNotEmpty ? alumni.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (alumni.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alumni.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (alumni.jobRole != null)
                    Text(
                      alumni.jobRole!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  if (alumni.currentCompany != null)
                    Text(
                      alumni.currentCompany!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                // View Profile Button
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Color(0xFF6C63FF)),
                  onPressed: () => _viewAlumniProfile(alumni),
                  tooltip: 'View Profile',
                ),
                // Connect Button
                _buildConnectButton(alumni),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton(AppUser alumni) {
    return StreamBuilder<ConnectionRequest?>(
      stream: _connectionService.streamRequestStatus(
        _currentUser!.userId,
        alumni.userId,
      ),
      builder: (context, snapshot) {
        final request = snapshot.data;

        if (request == null) {
          // No request sent yet
          return SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () => _sendRequest(alumni),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Connect', style: TextStyle(fontSize: 12)),
            ),
          );
        }

        // Request exists - show status
        Color bgColor;
        Color textColor;
        String text;
        IconData icon;

        switch (request.status) {
          case 'pending':
            bgColor = Colors.orange.withOpacity(0.2);
            textColor = Colors.orange;
            text = 'Pending';
            icon = Icons.hourglass_empty;
            break;
          case 'accepted':
            bgColor = const Color(0xFF00D4AA).withOpacity(0.2);
            textColor = const Color(0xFF00D4AA);
            text = 'Connected';
            icon = Icons.check_circle;
            break;
          case 'rejected':
            bgColor = Colors.red.withOpacity(0.2);
            textColor = Colors.red;
            text = 'Declined';
            icon = Icons.cancel;
            break;
          default:
            bgColor = Colors.grey.withOpacity(0.2);
            textColor = Colors.grey;
            text = 'Unknown';
            icon = Icons.help;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewAlumniProfile(AppUser alumni) {
    final mentorData = alumni.toMap();
    mentorData['role'] = alumni.jobRole ?? 'Alumni';
    mentorData['company'] = alumni.currentCompany ?? 'N/A';
    mentorData['matchScore'] = 95;
    mentorData['rating'] = 5.0;
    mentorData['mentees'] = 12;
    mentorData['sessions'] = alumni.totalSessions;
    mentorData['availability'] = 'High';
    mentorData['experience'] = '3+ Years';
    mentorData['responseTime'] = '< 24h';
    mentorData['skills'] = alumni.skills ?? [];
    mentorData['verified'] = alumni.isVerified;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MentorDetailScreen(mentor: mentorData),
      ),
    );
  }

  Future<void> _sendRequest(AppUser alumni) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SendRequestDialog(alumniName: alumni.name),
    );

    if (result != null) {
      try {
        await _connectionService.sendConnectionRequest(
          studentId: _currentUser!.userId,
          alumniId: alumni.userId,
          studentName: _currentUser!.name,
          alumniName: alumni.name,
          message: result.isNotEmpty ? result : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request sent to ${alumni.name}!'),
              backgroundColor: const Color(0xFF00D4AA),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SENT REQUESTS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSentRequestsTab(bool isDark) {
    return StreamBuilder<List<ConnectionRequest>>(
      stream: _connectionService.streamStudentPendingRequests(_currentUser!.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 80,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No requests sent yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse alumni and send connection requests',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(isDark, requests[index]);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(bool isDark, ConnectionRequest request) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending';
        break;
      case 'accepted':
        statusColor = const Color(0xFF00D4AA);
        statusIcon = Icons.check_circle;
        statusText = 'Accepted';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Declined';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                request.alumniName.isNotEmpty
                    ? request.alumniName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.alumniName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (request.isAccepted)
            ElevatedButton.icon(
              onPressed: () => _openChat(request.alumniId, request.alumniName),
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          if (request.isPending)
            OutlinedButton.icon(
              onPressed: () => _revokeRequest(request),
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              label: const Text('Revoke', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _revokeRequest(ConnectionRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Request'),
        content: Text('Are you sure you want to revoke your request to ${request.alumniName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _connectionService.revokeRequest(request.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request revoked successfully'),
              backgroundColor: Color(0xFF00D4AA),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to revoke: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTIONS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConnectionsTab(bool isDark) {
    return StreamBuilder<List<ConnectionRequest>>(
      stream: _connectionService.streamStudentConnections(_currentUser!.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final connections = snapshot.data ?? [];

        if (connections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 80,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No connections yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your accepted connections will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: connections.length,
          itemBuilder: (context, index) {
            return _buildConnectionCard(isDark, connections[index]);
          },
        );
      },
    );
  }

  Widget _buildConnectionCard(bool isDark, ConnectionRequest connection) {
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
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              connection.alumniName.isNotEmpty
                  ? connection.alumniName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(
          connection.alumniName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.check_circle, size: 14, color: Color(0xFF00D4AA)),
            const SizedBox(width: 4),
            const Text(
              'Connected',
              style: TextStyle(
                color: Color(0xFF00D4AA),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _openChat(connection.alumniId, connection.alumniName),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _openChat(String otherUserId, String otherUserName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          currentUserId: _currentUser!.userId,
          currentUserName: _currentUser!.name,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SEND REQUEST DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _SendRequestDialog extends StatefulWidget {
  final String alumniName;

  const _SendRequestDialog({required this.alumniName});

  @override
  State<_SendRequestDialog> createState() => _SendRequestDialogState();
}

class _SendRequestDialogState extends State<_SendRequestDialog> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Connect with ${widget.alumniName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add a message to introduce yourself (optional)',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Hi! I would love to connect...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _messageController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
          ),
          child: const Text('Send Request'),
        ),
      ],
    );
  }
}
