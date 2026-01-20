import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/new_models.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'session_booking_screen.dart';

class MentorDetailScreen extends StatefulWidget {
  final AppUser mentor;
  
  const MentorDetailScreen({Key? key, required this.mentor}) : super(key: key);

  @override
  State<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends State<MentorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfSaved();
  }
  
  Future<void> _checkIfSaved() async {
    final user = _authService.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      final saved = await _firestoreService.isAlumniSaved(user.uid, widget.mentor.userId);
      if (mounted) {
        setState(() {
          _isSaved = saved;
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    if (_currentUserId == null) return;
    
    setState(() => _isLoading = true);
    await _firestoreService.toggleSavedAlumni(_currentUserId!, widget.mentor.userId);
    
    if (mounted) {
      setState(() {
        _isSaved = !_isSaved;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isSaved ? 'Alumni saved to bookmarks' : 'Alumni removed from bookmarks')),
      );
    }
  }

  Future<void> _handleConnect() async {
    if (_currentUserId == null) return;

    final messageController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect with Alumni'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send a mentorship request to this alumni.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Write a brief message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (messageController.text.trim().isEmpty) return;
              Navigator.pop(context);
              _sendRequest(messageController.text.trim());
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(String message) async {
    try {
      if (_currentUserId == null) return;
      
      // Fetch current user name for the request
      final currentUser = await _firestoreService.getUser(_currentUserId!);
      
      final request = MentorshipRequest(
        id: Uuid().v4(),
        studentId: _currentUserId!,
        alumniId: widget.mentor.userId,
        studentName: currentUser?.name ?? 'Student',
        alumniName: widget.mentor.name,
        date: DateTime.now(),
        status: 'pending',
        message: message,
      );

      await _firestoreService.sendMentorshipRequest(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mentorship request sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e')),
        );
      }
    }
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
              onPressed: () {}, // Share logic specific to platform, skipped for now
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
              onPressed: _toggleSave,
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
                      Color(0xFF6C63FF + (widget.mentor.name.hashCode % 1000)),
                      Color(0xFF4E9FFF + (widget.mentor.name.hashCode % 1000)),
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
                    widget.mentor.name.isNotEmpty ? widget.mentor.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Verified Badge
              if (widget.mentor.isVerified)
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
              
              // Match Score (Mocked for now as it's computed logic)
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
                        '95%', // Mock score
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
            widget.mentor.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            widget.mentor.jobRole ?? 'Alumni Role',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.mentor.currentCompany ?? 'Company',
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
              _buildQuickStat(Icons.work_rounded, '5 years'), // Mock experience
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: 1,
                height: 30,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              _buildQuickStat(Icons.access_time_rounded, '< 24 hrs'), // Mock response time
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
              value: '5.0', // Mock
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.groups_rounded,
              label: 'Mentees',
              value: '12', // Mock
              color: const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: _buildStatCard(
              isDark,
              icon: Icons.videocam_rounded,
              label: 'Sessions',
              value: '24', // Mock
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
            'Passionate ${widget.mentor.jobRole} at ${widget.mentor.currentCompany}. I love helping students navigate their career paths and achieve their goals. My expertise spans across multiple domains, and I\'m always excited to share my knowledge and learn from mentees as well.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          
          if (widget.mentor.skills != null && widget.mentor.skills!.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'Expertise',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.mentor.skills!.map((skill) {
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
          ],
          
          const SizedBox(height: 32),
          
          const Text(
            'Career Journey',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildCareerTimeline(isDark),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCareerTimeline(bool isDark) {
    final positions = [
      {'year': 'Present', 'title': widget.mentor.jobRole ?? 'Role', 'company': widget.mentor.currentCompany ?? 'Company'},
      {'year': 'Past', 'title': 'Software Engineer', 'company': 'Tech Startup'}, // Mock past
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
                    color: index == 0 ? null : Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    index == 0 ? Icons.work_rounded : Icons.work_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white24,
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
      itemCount: 3, // Mock count
      itemBuilder: (context, index) {
        return _buildReviewCard(isDark, index);
      },
    );
  }

  Widget _buildReviewCard(bool isDark, int index) {
    // Mock reviews
    final reviews = [
      {
        'name': 'Alex Kumar',
        'rating': 5.0,
        'date': '2 weeks ago',
        'review': 'Amazing alumni! Really helped me prepare for my interviews.',
      },
      {
        'name': 'Emily Watson',
        'rating': 5.0,
        'date': '1 month ago',
        'review': 'Very knowledgeable and patient.',
      },
      {
        'name': 'Rahul Sharma',
        'rating': 4.5,
        'date': '2 months ago',
        'review': 'Great experience!',
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
                const Expanded(
                  child: Text(
                    'Availability status: High', // Mock
                    style: TextStyle(
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
      padding: const EdgeInsets.all(24),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Color(0xFF6C63FF)),
                  foregroundColor: const Color(0xFF6C63FF),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _handleConnect,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Connect'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
