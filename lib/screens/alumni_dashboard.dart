import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/new_model.dart'; // assuming MentorshipRequest is here

import 'resources_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'ai_chat_screen.dart';
import 'alumni/mentorship_requests_screen.dart';
import 'alumni/post_job_screen.dart';
import 'alumni/my_mentees_screen.dart';
import 'verification_request_screen.dart';
import 'qr_verification_screen.dart';
import 'community/community_screen.dart';

class AlumniDashboard extends StatefulWidget {
  const AlumniDashboard({super.key});

  @override
  State<AlumniDashboard> createState() => _AlumniDashboardState();
}

class _AlumniDashboardState extends State<AlumniDashboard> {
  int _selectedIndex = 0;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  AppUser? _userProfile; // kept for quick access + compatibility

  @override
  void initState() {
    super.initState();
    _loadInitialUserProfile();
  }

  Future<void> _loadInitialUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profile = await _firestoreService.getUser(uid);
    if (mounted) {
      setState(() => _userProfile = profile);
    }
  }

  bool get isVerified => _userProfile?.isVerified ?? false;

  void _showVerificationRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile verification required to access this feature'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

    final List<Widget> screens = [
      Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => _buildHomeContent(isDark, uid),
          );
        },
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      floatingActionButton: _buildFloatingActionButton(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  Widget _buildHomeContent(bool isDark, String uid) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
              : [const Color(0xFFF8F9FE), const Color(0xFFFFFFFF)],
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<AppUser?>(
          stream: _firestoreService.streamUser(uid),
          builder: (context, snapshot) {
            final user = snapshot.data;
            _userProfile = user; // keep local copy in sync

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(isDark, user)),
                if (user != null) SliverToBoxAdapter(child: _buildVerificationBanner(user)),
                SliverToBoxAdapter(child: _buildStatsSection(isDark, uid)),
                SliverToBoxAdapter(
                  child: _buildSectionTitle(
                    'Pending Requests',
                    'View All',
                    isDark,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MentorshipRequestsScreen()),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildPendingRequestsPreview(isDark, uid)),
                SliverToBoxAdapter(child: _buildQuickActions(isDark)),
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Alumni Tools', '', isDark, null),
                ),
                SliverToBoxAdapter(child: _buildFeatureGrid(isDark)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!(user?.isVerified ?? false))
                          _buildVerificationButton(
                            icon: Icons.verified_user,
                            title: 'Request University/Alumni Verification',
                            subtitle: 'Verify your alumni status',
                            color: Colors.blue.shade600,
                            onTap: () {
                              final currentUser = FirebaseAuth.instance.currentUser;
                              if (user != null && currentUser != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerificationRequestScreen(
                                      userId: currentUser.uid,
                                      name: user.name,
                                      email: user.email,
                                      role: 'alumni',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        if (user?.isVerified ?? false)
                          _buildVerificationButton(
                            icon: Icons.badge,
                            title: 'View My E-ID',
                            subtitle: 'Your verified alumni identity card',
                            color: const Color(0xFF00D4AA),
                            onTap: () {
                              final currentUser = FirebaseAuth.instance.currentUser;
                              if (user != null && currentUser != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerificationRequestScreen(
                                      userId: currentUser.uid,
                                      name: user.name,
                                      email: user.email,
                                      role: 'alumni',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        const SizedBox(height: 16),
                        _buildVerificationButton(
                          icon: Icons.qr_code_scanner,
                          title: 'Verify QR Code',
                          subtitle: 'Scan or upload your alumni QR',
                          color: Colors.green.shade600,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QrVerificationScreen(userId: uid),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Header, Banner, Stats, Requests, Quick Actions, Grid, FAB, BottomNav
  // ──────────────────────────────────────────────

  Widget _buildHeader(bool isDark, AppUser? user) {
    final name = user?.name ?? 'Alumni';
    final imageUrl = user?.profileImageUrl;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]),
                    border: Border.all(color: Colors.white, width: 3),
                    image: imageUrl != null
                        ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imageUrl == null
                      ? const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              _buildNotificationIcon(isDark),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBox(isDark),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(AppUser user) {
    Color bgColor, textColor;
    IconData icon;
    String message;

    if (user.isVerified) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.verified_user;
      message = 'Your alumni profile is verified! Full access granted.';
    } else if (user.isRejected == true) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.cancel;
      message = 'Verification rejected. Please update and resubmit.';
    } else {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.pending;
      message = 'Verification pending. Some features are restricted.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isDark, String uid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<List<MentorshipRequest>>(
              stream: _firestoreService.getMyMentees(uid),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return _buildStatCard(
                  isDark,
                  icon: Icons.school_rounded,
                  label: 'Mentees',
                  value: '$count',
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          StreamBuilder<AppUser?>(
            stream: _firestoreService.streamUser(uid),
            builder: (context, snapshot) {
              final sessions = snapshot.data?.totalSessions ?? 0;
              return Expanded(
                child: _buildStatCard(
                  isDark,
                  icon: Icons.video_camera_front_rounded,
                  label: 'Sessions',
                  value: '$sessions',
                  gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          StreamBuilder<AppUser?>(
            stream: _firestoreService.streamUser(uid),
            builder: (context, snapshot) {
              final level = (snapshot.data?.xp ?? 0) ~/ 100 + 1;
              return Expanded(
                child: _buildStatCard(
                  isDark,
                  icon: Icons.emoji_events_rounded,
                  label: 'Level',
                  value: '$level',
                  gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00A896)]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsPreview(bool isDark, String uid) {
    return StreamBuilder<List<MentorshipRequest>>(
      stream: _firestoreService.getMentorshipRequestsForAlumni(uid),
      builder: (context, snapshot) {
        final requests = snapshot.data?.where((r) => r.status == 'pending').toList() ?? [];

        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No pending mentorship requests."),
              ),
            ),
          );
        }

        final latest = requests.first;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MentorshipRequestsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF6C63FF),
                    child: Text(latest.studentName[0], style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${latest.studentName} sent a request',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          latest.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MentorshipRequestsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00A896)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF00D4AA).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View All Requests',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review student profiles',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(bool isDark) {
    final features = [
      {
        'icon': Icons.campaign_rounded,
        'title': 'Post a Job',
        'color': const Color(0xFF6C63FF),
        'screen': const PostJobScreen(),
        'locked': !isVerified,
      },
      {
        'icon': Icons.groups_rounded,
        'title': 'My Mentees',
        'color': const Color(0xFFFF6B9D),
        'screen': const MyMenteesScreen(),
        'locked': false,
      },
      {
        'icon': Icons.event_available_rounded,
        'title': 'Manage Events',
        'color': const Color(0xFFFFA726),
        'screen': const EventsScreen(),
        'locked': false,
      },
      {
        'icon': Icons.auto_stories_rounded,
        'title': 'Knowledge Base',
        'color': const Color(0xFF00D4AA),
        'screen': const ResourcesScreen(),
        'locked': false,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final f = features[index];
          return GestureDetector(
            onTap: () {
              if (f['locked'] == true) {
                _showVerificationRequired();
                return;
              }
              final screen = f['screen'] as Widget;
              Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
            },
            child: Opacity(
              opacity: f['locked'] == true ? 0.6 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Icon(f['icon'] as IconData, color: f['color'] as Color, size: 36),
                        if (f['locked'] == true)
                          const Icon(Icons.lock, size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      f['title'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF6B9D).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 28),
        onPressed: isVerified
            ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen()))
            : _showVerificationRequired,
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Reusable small widgets (mostly unchanged)
  // ──────────────────────────────────────────────

  Widget _buildSearchBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search mentees, jobs, discussions...',
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          prefixIcon: const Icon(Icons.search_rounded),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(bool isDark) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(icon: const Icon(Icons.notifications_rounded), onPressed: () {}),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D),
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF0F0F1E) : Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action, bool isDark, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (action.isNotEmpty)
            TextButton(
              onPressed: onTap,
              child: Text(
                action,
                style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Home', null),
              _buildNavItem(-1, Icons.explore_rounded, 'Explore', const CommunityScreen()),
              const SizedBox(width: 64),
              _buildNavItem(-1, Icons.event_rounded, 'Events', const EventsScreen()),
              _buildNavItem(1, Icons.person_rounded, 'Profile', null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Widget? screen) {
    final isSelected = _selectedIndex == index && index >= 0;
    return GestureDetector(
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        } else if (index >= 0) {
          setState(() => _selectedIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF6C63FF) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.85)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}