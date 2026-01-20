import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

import 'resources_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'ai_chat_screen.dart';
import 'auth_screen.dart';
// import 'mentee_requests_screen.dart';     // uncomment when ready
// import 'job_posting_screen.dart';        // uncomment when ready
import 'verification_request_screen.dart';
import 'qr_verification_screen.dart';

class AlumniDashboard extends StatefulWidget {
  const AlumniDashboard({super.key});

  @override
  State<AlumniDashboard> createState() => _AlumniDashboardState();
}

class _AlumniDashboardState extends State<AlumniDashboard> {
  int _selectedIndex = 0;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  AppUser? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _firestoreService.getUser(user.uid);
      if (mounted) {
        setState(() => _userProfile = profile);
      }
    }
  }

  bool get isVerified => _userProfile?.isVerified ?? false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(isDark, currentUser),
              ),
              if (_userProfile != null)
                SliverToBoxAdapter(child: _buildVerificationBanner()),
              SliverToBoxAdapter(child: _buildStatsSection(isDark)),
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  'Pending Requests',
                  'View All',
                  isDark,
                  () {
                    // TODO: Navigate to Mentee Requests screen when implemented
                    if (!isVerified) {
                      _showVerificationRequired();
                    }
                  },
                ),
              ),
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
                      if (!isVerified)
                        _buildVerificationButton(
                          icon: Icons.verified_user,
                          title: 'Request University/Alumni Verification',
                          subtitle: 'Verify your alumni status',
                          color: Colors.blue.shade600,
                          onTap: () {
                            if (currentUser != null && _userProfile != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VerificationRequestScreen(
                                    userId: currentUser.uid,
                                    name: _userProfile!.name,
                                    email: _userProfile!.email,
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
                          if (currentUser != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QrVerificationScreen(userId: currentUser.uid),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  void _showVerificationRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile verification required')),
    );
  }

  Widget _buildHeader(bool isDark, User? currentUser) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
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
                      _userProfile?.name ?? currentUser?.displayName ?? 'Mentor',
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen(role: '',)),
                    );
                  }
                },
                icon: Icon(Icons.logout_rounded, color: isDark ? Colors.white70 : Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner() {
    final profile = _userProfile!;
    Color bgColor, textColor;
    IconData icon;
    String message;

    if (profile.isVerified) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.verified_user;
      message = 'Your alumni profile is verified! Full access granted.';
    } else if (profile.isRejected) {
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

  Widget _buildStatsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.school_rounded,
              label: 'Mentees',
              value: '4',
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.video_camera_front_rounded,
              label: 'Hours',
              value: '42',
              gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.star_rounded,
              label: 'Rating',
              value: '4.9',
              gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00A896)]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: isVerified
            ? () {
                // TODO: Navigate to mentee requests screen
              }
            : _showVerificationRequired,
        child: Opacity(
          opacity: isVerified ? 1.0 : 0.75,
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
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Mentorship Request',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Review student profile',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (!isVerified) const Icon(Icons.lock, color: Colors.white70, size: 20),
                if (isVerified) const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
              ],
            ),
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
        'locked': !isVerified,
        // 'screen': const JobPostingScreen(), // uncomment when ready
      },
      {
        'icon': Icons.groups_rounded,
        'title': 'My Mentees',
        'color': const Color(0xFFFF6B9D),
        'locked': false,
        // 'screen': const MenteeListScreen(), // when ready
      },
      {
        'icon': Icons.event_available_rounded,
        'title': 'Manage Events',
        'color': const Color(0xFFFFA726),
        'locked': false,
        'screen': const EventsScreen(),
      },
      {
        'icon': Icons.auto_stories_rounded,
        'title': 'Knowledge Base',
        'color': const Color(0xFF00D4AA),
        'locked': false,
        'screen': const ResourcesScreen(),
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
              final screen = f['screen'] as Widget?;
              if (screen != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
              }
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

  Widget _buildFloatingActionButton() {
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
  //  Reusable helpers (kept from your original + minor tweaks)
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
              child: Text(action, style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
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
              // _buildNavItem(1, Icons.people_alt_rounded, 'Mentees', const MenteeRequestsScreen()),
              const SizedBox(width: 64),
              // _buildNavItem(2, Icons.work_rounded, 'Jobs', const JobPostingScreen()),
              _buildNavItem(3, Icons.person_rounded, 'Profile', const ProfileScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Widget? screen) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF6C63FF) : Colors.grey, size: 28),
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