import 'package:flutter/material.dart';
import 'mentor_matching_screen.dart';
import 'resources_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'career_path_screen.dart';
import 'ai_chat_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
              SliverToBoxAdapter(child: _buildHeader(isDark)),
              SliverToBoxAdapter(child: _buildStatsSection(isDark)),
              SliverToBoxAdapter(child: _buildSectionTitle('Recommended Mentors', 'View All', isDark, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorMatchingScreen()));
              })),
              SliverToBoxAdapter(child: _buildQuickActions(isDark)),
              SliverToBoxAdapter(child: _buildSectionTitle('Quick Access', '', isDark, null)),
              SliverToBoxAdapter(child: _buildFeatureGrid(isDark)),
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
                    Text('Welcome back,', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 4),
                    const Text('Rahul Sharma', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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

  Widget _buildStatsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(isDark, icon: Icons.people_rounded, label: 'Mentors', value: '12', gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(isDark, icon: Icons.calendar_today_rounded, label: 'Sessions', value: '8', gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(isDark, icon: Icons.emoji_events_rounded, label: 'Level', value: '5', gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00A896)]))),
        ],
      ),
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
                  Text('Find Your Perfect Mentor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('AI-powered matching', style: TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorMatchingScreen()));
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
      {'icon': Icons.auto_awesome_rounded, 'title': 'Mentor Match', 'color': const Color(0xFF6C63FF), 'screen': const MentorMatchingScreen()},
      {'icon': Icons.library_books_rounded, 'title': 'Resources', 'color': const Color(0xFFFF6B9D), 'screen': const ResourcesScreen()},
      {'icon': Icons.event_rounded, 'title': 'Events', 'color': const Color(0xFFFFA726), 'screen': const EventsScreen()},
      {'icon': Icons.trending_up_rounded, 'title': 'Career Path', 'color': const Color(0xFF00D4AA), 'screen': const CareerPathScreen()},
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
          final feature = features[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => feature['screen'] as Widget));
            },
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
                  Icon(feature['icon'] as IconData, color: feature['color'] as Color, size: 36),
                  const SizedBox(height: 12),
                  Text(feature['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ],
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
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