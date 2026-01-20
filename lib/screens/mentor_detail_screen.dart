import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'session_booking_screen.dart';
import '../services/firestore_service.dart';
import '../models/new_model.dart';
import '../models/user_model.dart';

class MentorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> mentor;
  
  const MentorDetailScreen({super.key, required this.mentor});

  @override
  State<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends State<MentorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildProfileSection(isDark)),
                  SliverToBoxAdapter(child: _buildStatsCards(isDark)),
                  SliverToBoxAdapter(child: _buildTabBar(isDark)),
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAboutTab(isDark),
                        _buildReviewsTab(isDark),
                        _buildAvailabilityTab(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const Spacer(),
            
            IconButton(
              onPressed: () {},
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share_rounded),
              ),
            ),
            
            IconButton(
              onPressed: () {
                setState(() => _isSaved = !_isSaved);
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: _isSaved ? const Color(0xFF6C63FF) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isDark) {
    final String name = widget.mentor['name'] ?? 'Alumni';
    final String role = widget.mentor['jobRole'] ?? widget.mentor['role'] ?? 'Mentor';
    final String company = widget.mentor['currentCompany'] ?? widget.mentor['company'] ?? 'N/A';
    final bool isVerified = widget.mentor['verificationStatus'] == 'verified' || (widget.mentor['verified'] ?? false);
    final int matchScore = widget.mentor['matchScore'] ?? 90;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar with Match Score
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6C63FF + (name.hashCode % 1000)),
                      Color(0xFF4E9FFF + (name.hashCode % 1000)),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Verified Badge
              if (isVerified)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F0F1E) : Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              // Match Score
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF00A896)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4AA).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$matchScore%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Name & Title
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            role,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              company,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickStat(Icons.work_rounded, widget.mentor['experience'] ?? '5+ yrs'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: 1,
                height: 30,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              _buildQuickStat(Icons.access_time_rounded, widget.mentor['responseTime'] ?? '< 24h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.star_rounded,
              label: 'Rating',
              value: '${widget.mentor['rating'] ?? 5.0}',
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.groups_rounded,
              label: 'Mentees',
              value: '${widget.mentor['mentees'] ?? 10}',
              color: const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.videocam_rounded,
              label: 'Sessions',
              value: '${widget.mentor['sessions'] ?? widget.mentor['totalSessions'] ?? 25}',
              color: const Color(0xFF00D4AA),
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
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'Reviews'),
            Tab(text: 'Availability'),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(bool isDark) {
    final String role = widget.mentor['jobRole'] ?? widget.mentor['role'] ?? 'Mentor';
    final String company = widget.mentor['currentCompany'] ?? widget.mentor['company'] ?? 'N/A';
    final String experience = widget.mentor['experience'] ?? '5+ yrs';
    final List<String> skills = (widget.mentor['skills'] as List?)?.cast<String>() ?? 
                               (widget.mentor['mentorshipInterests'] as List?)?.cast<String>() ?? 
                               ['Mentoring', 'Leadership', 'Strategy'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          Text(
            'Passionate $role at $company with $experience of experience. I love helping students navigate their career paths and achieve their goals. My expertise spans across multiple domains, and I\'m always excited to share my knowledge and learn from mentees as well.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Expertise',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Career Journey',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildCareerTimeline(isDark, role, company),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCareerTimeline(bool isDark, String currentRole, String currentCompany) {
    final positions = [
      {'year': '2024 - Present', 'title': currentRole, 'company': currentCompany},
      {'year': '2021 - 2024', 'title': 'Software Engineer', 'company': 'Tech Startup'},
      {'year': '2018 - 2021', 'title': 'Junior Developer', 'company': 'Software Company'},
    ];
    
    return Column(
      children: positions.asMap().entries.map((entry) {
        final index = entry.key;
        final position = entry.value;
        final isLast = index == positions.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: index == 0
                        ? const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                          )
                        : null,
                    color: index == 0 ? null : (isDark ? Colors.white10 : Colors.black12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    index == 0 ? Icons.work_rounded : Icons.work_outline_rounded,
                    color: index == 0 ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position['year']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      position['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      position['company']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildReviewsTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildReviewCard(isDark, index);
      },
    );
  }

  Widget _buildReviewCard(bool isDark, int index) {
    final reviews = [
      {
        'name': 'Alex Kumar',
        'rating': 5.0,
        'date': '2 weeks ago',
        'review': 'Amazing mentor! Really helped me prepare for my interviews and gave valuable insights about the industry.',
      },
      {
        'name': 'Emily Watson',
        'rating': 5.0,
        'date': '1 month ago',
        'review': 'Very knowledgeable and patient. The resume review session was incredibly helpful.',
      },
      {
        'name': 'Rahul Sharma',
        'rating': 4.5,
        'date': '2 months ago',
        'review': 'Great experience! Learned a lot about career growth strategies.',
      },
    ];
    
    if (index >= reviews.length) return const SizedBox.shrink();
    final review = reviews[index];
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6C63FF + (index * 2000)),
                      Color(0xFF4E9FFF + (index * 2000)),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    review['name']?.toString().substring(0, 1) ?? '',
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
                      review['name'].toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      review['date'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${review['rating']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            review['review'].toString(),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTab(bool isDark) {
    final String availability = widget.mentor['availability'] ?? 'Flexible';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Availability status: $availability',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Available Time Slots',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildTimeSlots(isDark),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(bool isDark) {
    final timeSlots = ['9:00 AM', '11:00 AM', '2:00 PM', '4:00 PM', '6:00 PM'];
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: timeSlots.map((time) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionBookingScreen(mentor: widget.mentor),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Book a Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showConnectDialog(BuildContext context) {
    final TextEditingController messageController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Connect with Mentor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a message to introduce yourself and explain why you\'d like to connect with ${widget.mentor['name']}.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
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
            onPressed: () async {
              final message = messageController.text.trim();
              if (message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a message')),
                );
                return;
              }

              final currentUser = _auth.currentUser;
              if (currentUser == null) return;

              // Show loading
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sending request...')),
              );

              try {
                final studentData = await _firestoreService.getUser(currentUser.uid);
                if (studentData == null) return;

                final request = MentorshipRequest(
                  id: const Uuid().v4(),
                  studentId: currentUser.uid,
                  studentName: studentData.name,
                  alumniId: widget.mentor['userId'] ?? widget.mentor['id'] ?? '',
                  alumniName: widget.mentor['name'] ?? '',
                  message: message,
                  status: 'pending',
                  date: DateTime.now(),
                );

                await _firestoreService.sendMentorshipRequest(request);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connection request sent!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sending request: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}