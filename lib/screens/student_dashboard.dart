import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'mentor_matching_screen.dart';
import 'resources_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'career_path_screen.dart';
import 'ai_chat_screen.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';           // assuming you renamed or want to keep this
import 'verification_request_screen.dart';
import 'qr_verification_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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
              SliverToBoxAdapter(
                child: _userProfile != null ? _buildVerificationBanner() : const SizedBox.shrink(),
              ),
              SliverToBoxAdapter(child: _buildStatsSection(isDark)),
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  'Recommended Mentors',
                  'View All',
                  isDark,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MentorMatchingScreen()),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildQuickActions(isDark)),
              SliverToBoxAdapter(
                child: _buildSectionTitle('Quick Access', '', isDark, null),
              ),
              SliverToBoxAdapter(child: _buildFeatureGrid(isDark)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          title: 'Request University Verification',
                          subtitle: 'Verify your student ID',
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
                                    role: 'student',
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
                        subtitle: 'Scan or upload your verification QR',
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

  Widget _buildHeader(bool isDark, User? currentUser) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _userProfile?.role == 'student'
                          ? const ProfileScreen()
                          : const ProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
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
                      _userProfile?.name ?? currentUser?.displayName ?? 'Student',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search mentors, events, resources...',
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                prefixIcon: const Icon(Icons.search_rounded),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildVerificationBanner() {
    if (_userProfile == null) return null;

    final profile = _userProfile!;
    Color bgColor;
    Color textColor;
    IconData icon;
    String message;

    if (profile.isVerified) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.verified_user;
      message = 'Your profile is verified! Full access granted.';
    } else if (profile.isRejected) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.cancel;
      message = 'Verification rejected. Please update your profile and resubmit.';
    } else {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.pending;
      message = 'Verification pending. Some features are locked.';
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

  // ──────────────────────────────────────────────
  //  The rest remains almost identical to your original beautiful UI
  // ──────────────────────────────────────────────

  Widget _buildStatsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.people_rounded,
              label: 'Mentors',
              value: '12',
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.calendar_today_rounded,
              label: 'Sessions',
              value: '8',
              gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.emoji_events_rounded,
              label: 'Level',
              value: '5',
              gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00A896)]),
            ),
          ),
        ],
      ),
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
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
          ),
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
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (action.isNotEmpty)
            TextButton(
              onPressed: onTap,
              child: Text(
                action,
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
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
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Your Perfect Mentor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'AI-powered matching',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                if (isVerified) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MentorMatchingScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please verify your profile first')),
                  );
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(bool isDark) {
    final features = [
      {
        'icon': Icons.auto_awesome_rounded,
        'title': 'Mentor Match',
        'color': const Color(0xFF6C63FF),
        'screen': const MentorMatchingScreen(),
        'locked': !isVerified,
      },
      {
        'icon': Icons.library_books_rounded,
        'title': 'Resources',
        'color': const Color(0xFFFF6B9D),
        'screen': const ResourcesScreen(),
        'locked': false,
      },
      {
        'icon': Icons.event_rounded,
        'title': 'Events',
        'color': const Color(0xFFFFA726),
        'screen': const EventsScreen(),
        'locked': false,
      },
      {
        'icon': Icons.trending_up_rounded,
        'title': 'Career Path',
        'color': const Color(0xFF00D4AA),
        'screen': const CareerPathScreen(),
        'locked': !isVerified,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile verification required')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => f['screen'] as Widget),
              );
            },
            child: Opacity(
              opacity: f['locked'] == true ? 0.55 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(16),
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
                        Icon(
                          f['icon'] as IconData,
                          color: f['color'] as Color,
                          size: 28,
                        ),
                        if (f['locked'] == true)
                          const Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.grey,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        f['title'] as String,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 28),
        onPressed: isVerified
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIChatScreen()),
                );
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please verify your profile to use AI Chat')),
                );
              },
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home', null),
              _buildNavItem(1, Icons.explore_rounded, 'Explore', const MentorMatchingScreen()),
              const SizedBox(width: 64),
              _buildNavItem(2, Icons.event_rounded, 'Events', const EventsScreen()),
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
          if (index == 1 && !isVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification required')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
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
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
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
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}