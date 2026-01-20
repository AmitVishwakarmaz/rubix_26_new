import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/community_service.dart';
import '../../services/firestore_service.dart';
import '../../models/community_model.dart';
import '../../models/user_model.dart';
import 'create_community_screen.dart';
import 'community_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final _communityService = CommunityService();
  final _firestoreService = FirestoreService();

  late TabController _tabController;
  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
          // Alumni: 3 tabs (Yours, Joined, All), Student: 2 tabs (Joined, All)
          _tabController = TabController(
            length: user?.isAlumni == true ? 3 : 2,
            vsync: this,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    if (!_isLoading) {
      _tabController.dispose();
    }
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

    final isAlumni = _currentUser?.isAlumni ?? false;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
      appBar: _buildAppBar(isDark, isAlumni),
      body: TabBarView(
        controller: _tabController,
        children: isAlumni
            ? [
                _buildCommunityList(isDark, 'yours'),
                _buildCommunityList(isDark, 'joined'),
                _buildCommunityList(isDark, 'all'),
              ]
            : [
                _buildCommunityList(isDark, 'joined'),
                _buildCommunityList(isDark, 'all'),
              ],
      ),
      floatingActionButton: isAlumni ? _buildCreateFAB(isDark) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, bool isAlumni) {
    return AppBar(
      title: const Text(
        'Communities',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF6C63FF),
        labelColor: const Color(0xFF6C63FF),
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
        tabs: isAlumni
            ? const [
                Tab(text: 'Yours'),
                Tab(text: 'Joined'),
                Tab(text: 'All'),
              ]
            : const [
                Tab(text: 'Joined'),
                Tab(text: 'All'),
              ],
      ),
    );
  }

  Widget _buildCommunityList(bool isDark, String type) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

    Stream<List<Community>> stream;
    switch (type) {
      case 'yours':
        stream = _communityService.streamCreatedCommunities(uid);
        break;
      case 'joined':
        stream = _communityService.streamJoinedCommunities(uid);
        break;
      case 'all':
      default:
        stream = _communityService.streamAllCommunities();
        break;
    }

    return StreamBuilder<List<Community>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final communities = snapshot.data ?? [];

        if (communities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 80,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(type),
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
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            return _buildCommunityCard(isDark, communities[index], type);
          },
        );
      },
    );
  }

  String _getEmptyMessage(String type) {
    switch (type) {
      case 'yours':
        return 'You haven\'t created any communities yet';
      case 'joined':
        return 'You haven\'t joined any communities yet';
      default:
        return 'No communities available';
    }
  }

  Widget _buildCommunityCard(bool isDark, Community community, String tabType) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = community.createdBy == uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCommunity(community),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          community.name.isNotEmpty
                              ? community.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  community.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCreator)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D4AA).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Creator',
                                    style: TextStyle(
                                      color: Color(0xFF00D4AA),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            community.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(community.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const Spacer(),
                    if (tabType == 'all')
                      FutureBuilder<bool>(
                        future: _communityService.isMember(
                          community.id,
                          uid ?? '',
                        ),
                        builder: (context, snapshot) {
                          final isMember = snapshot.data ?? false;
                          if (isMember) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Joined',
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return ElevatedButton(
                            onPressed: () => _joinCommunity(community),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Join',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    if (tabType != 'all')
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _joinCommunity(Community community) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await _communityService.joinCommunity(
        communityId: community.id,
        odId: user.userId,
        role: user.role,
        name: user.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined ${community.name}!'),
            backgroundColor: const Color(0xFF00D4AA),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openCommunity(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          community: community,
          currentUser: _currentUser!,
        ),
      ),
    );
  }

  Widget _buildCreateFAB(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateCommunityScreen(
                currentUser: _currentUser!,
              ),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
