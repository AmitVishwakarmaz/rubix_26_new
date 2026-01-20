import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'student_profile_screen.dart';
import 'verification_request_screen.dart';
import 'qr_verification_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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
      setState(() => _userProfile = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4facfe),
              const Color(0xFF00f2fe),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.displayName ?? _userProfile?.name ?? 'Student'}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Student Dashboard',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _authService.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verification Status Banner
                        if (_userProfile != null) _buildVerificationBanner(),
                        
                        const Text(
                          'Welcome to Student Portal',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect with alumni mentors and explore opportunities.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Quick Actions
                        _buildQuickAction(
                          icon: Icons.people_rounded,
                          title: 'Find Mentors',
                          subtitle: 'Connect with experienced alumni',
                          color: const Color(0xFF4facfe),
                          locked: !(_userProfile?.isVerified ?? false),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickAction(
                          icon: Icons.event_rounded,
                          title: 'Events',
                          subtitle: 'Upcoming networking sessions',
                          color: const Color(0xFF764ba2),
                          locked: false,
                        ),
                        const SizedBox(height: 16),
                        _buildQuickAction(
                          icon: Icons.work_rounded,
                          title: 'Job Board',
                          subtitle: 'Explore career opportunities',
                          color: const Color(0xFFf093fb),
                          locked: !(_userProfile?.isVerified ?? false),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickAction(
                          icon: Icons.chat_rounded,
                          title: 'Messages',
                          subtitle: 'Chat with your mentors',
                          color: const Color(0xFF00f2fe),
                          locked: !(_userProfile?.isVerified ?? false),
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Verification Section
                        Text(
                          'Verification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Request Verification
                        if (!(_userProfile?.isVerified ?? false))
                          _buildVerificationButton(
                            icon: Icons.verified_user,
                            title: 'Request University Verification',
                            subtitle: 'Verify your student ID',
                            color: Colors.blue.shade600,
                            onTap: () {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null && _userProfile != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerificationRequestScreen(
                                      userId: user.uid,
                                      name: _userProfile!.name,
                                      email: _userProfile!.email,
                                      role: 'student',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        const SizedBox(height: 12),
                        
                        // Verify QR Code
                        _buildVerificationButton(
                          icon: Icons.qr_code_scanner,
                          title: 'Verify QR Code',
                          subtitle: 'Scan or upload your verification QR',
                          color: Colors.green.shade600,
                          onTap: () {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QrVerificationScreen(userId: user.uid),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, 
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool locked = false,
  }) {
    return Opacity(
      opacity: locked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2d3748),
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.lock, size: 14, color: Colors.grey.shade500),
                      ],
                    ],
                  ),
                  Text(
                    locked ? 'Verification required' : subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, 
                color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }
}
