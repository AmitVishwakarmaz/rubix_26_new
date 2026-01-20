import 'package:flutter/material.dart';
import 'mentor_matching_screen.dart';
import 'resources_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'career_path_screen.dart';
import 'ai_chat_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _authService.currentUser;
    
    // Screens array for persistent navigation
    final List<Widget> _screens = [
      _buildHomeContent(isDark, user?.uid),
      const MentorMatchingScreen(), // Assuming this screen handles its own Scaffold, might need wrapping or modifications if it has a Scaffold. 
                                    // ideally we pass a flag or refactor it to return a widget without Scaffold for nested nav, 
                                    // but for now let's assume we render it as is. 
                                    // Wait, if these screens have Scaffolds, they will nest inside this Scaffold.
                                    // Flutter allows nested Scaffolds but it's not always ideal for bottom bars.
                                    // If we want the bottom bar to stay, we should use a shell or simply switch the body.
                                    // However, persistent bottom bars often require screens to NOT have their own minimal Scaffolds or handle it carefully.
                                    // For this hackathon, switching the body with Scaffold-in-Scaffold is acceptable for "persistent nav" feel, 
                                    // OR we wrap them in a container.
                                    // Actually, if we want the bottom bar to be visible *while* on Explore/Events, 
                                    // this Dashboard Scaffold must remain the parent.
                                    // So the child screens should nominally simply be the "body" content.
                                    // If `MentorMatchingScreen` has a Scaffold, we might get double app bars or bottom bars if not careful.
                                    // Let's proceed with switching body.
      const EventsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // Only show App Bar header on Home tab, or handle headers inside each screen
      // Since `_buildHomeContent` has the header, we just return the selected widget.
      // But wait, `ProfileScreen` etc ALL have Scaffolds. 
      // If we render `ProfileScreen` (which has a Scaffold) inside `StudentDashboard` body, the `StudentDashboard` bottom bar will be visible below `ProfileScreen`'s content?
      // No, `ProfileScreen`'s Scaffold will take up the space. 
      // Note: If `ProfileScreen` does not have a bottom bar, `StudentDashboard`'s bottom bar will be visible if we put `ProfileScreen` in the body?
      // Yes, provided `resizeToAvoidBottomInset` etc are handled.
      // Let's try to just switch the body.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  // Extracted Home Content
  Widget _buildHomeContent(bool isDark, String? userId) {
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isDark, userId)),
              SliverToBoxAdapter(child: _buildStatsSection(isDark, userId)), // Modified to take userId
              SliverToBoxAdapter(child: _buildSectionTitle('Recommended Alumni', 'View All', isDark, () {
                 setState(() => _selectedIndex = 1); // Switch to Explore tab
              })),
              SliverToBoxAdapter(child: _buildQuickActions(isDark)),
              SliverToBoxAdapter(child: _buildSectionTitle('Quick Access', '', isDark, null)),
              SliverToBoxAdapter(child: _buildFeatureGrid(isDark)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      );
  }

  Widget _buildHeader(bool isDark, String? userId) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = 3); // Go to Profile
                },
                child: FutureBuilder<AppUser?>(
                  future: userId != null ? _firestoreService.getUser(userId) : null,
                  builder: (context, snapshot) {
                     final imageUrl = snapshot.data?.profileImageUrl;
                     return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
                        border: Border.all(color: Colors.white, width: 3),
                        image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                      ),
                      child: imageUrl == null ? const Icon(Icons.person_rounded, color: Colors.white, size: 28) : null,
                    );
                  }
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 4),
                    FutureBuilder<AppUser?>(
                      future: userId != null ? _firestoreService.getUser(userId) : null,
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data?.name ?? 'Loading...',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        );
                      }
                    ),
                  ],
                ),
              ),
              
              Stack(
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
                hintText: 'Search alumni, events, resources...',
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

  Widget _buildStatsSection(bool isDark, String? userId) {
    if (userId == null) return const SizedBox.shrink();
    
    return StreamBuilder<AppUser?>(
      stream: _firestoreService.streamUser(userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        // Default values if loading or null
        final sessions = user?.totalSessions.toString() ?? '0';
        final rank = user?.rank ?? 'Novice';
        // Assume some logic for "Alumni" count, or just hardcode for now as per plan
        // Maybe fetch total alumni count? For now let's keep it static or random-ish
        final alumniCount = '250+'; 

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(child: _buildStatCard(isDark, icon: Icons.people_rounded, label: 'Alumni', value: alumniCount, gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]))),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(isDark, icon: Icons.calendar_today_rounded, label: 'Sessions', value: sessions, gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]))),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(isDark, icon: Icons.emoji_events_rounded, label: rank, value: rank == 'Grandmaster' ? 'GM' : '${user?.xp ?? 0}', gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00A896)]))),
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatCard(bool isDark, {required IconData icon, required String label, required String value, required Gradient gradient}) {
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
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
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

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Find Your Perfect Alumni', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('AI-powered matching', style: TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            
            IconButton(
              onPressed: () {
                setState(() => _selectedIndex = 1); // Switch to Explore
              },
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(bool isDark) {
    // Note: We need to handle navigation here. 
    // Since we are using persistent nav, pushing new screens on top is okay for "deeper" navigation,
    // OR we change tabs.
    // For "Alumni Match" -> switch tab.
    // For others -> Push is fine.
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildFeatureCard(
            isDark,
            icon: Icons.auto_awesome_rounded, 
            title: 'Alumni Match', 
            color: const Color(0xFF6C63FF), 
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _buildFeatureCard(
            isDark,
            icon: Icons.library_books_rounded, 
            title: 'Resources', 
            color: const Color(0xFFFF6B9D), 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen())),
          ),
          _buildFeatureCard(
            isDark,
            icon: Icons.event_rounded, 
            title: 'Events', 
            color: const Color(0xFFFFA726), 
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          _buildFeatureCard(
            isDark,
            icon: Icons.trending_up_rounded, 
            title: 'Career Path', 
            color: const Color(0xFF00D4AA), 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareerPathScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(bool isDark, {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
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
        boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: IconButton(
        icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen()));
        },
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
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.explore_rounded, 'Explore'),
              const SizedBox(width: 64),
              _buildNavItem(2, Icons.event_rounded, 'Events'),
              _buildNavItem(3, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF6C63FF) : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF6C63FF) : Colors.grey)),
        ],
      ),
    );
  }
}
