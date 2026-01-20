import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mentor_detail_screen.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class MentorMatchingScreen extends StatefulWidget {
  const MentorMatchingScreen({Key? key}) : super(key: key);

  @override
  State<MentorMatchingScreen> createState() => _MentorMatchingScreenState();
}

class _MentorMatchingScreenState extends State<MentorMatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late TabController _tabController;
  bool _isMatching = false;
  bool _matchComplete = false;
  String _selectedFilter = 'All';
  String _selectedSort = 'Best Match';
  
  final FirestoreService _firestoreService = FirestoreService();
  
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  List<String> _dynamicFilters = ['All'];
  final List<String> _sortOptions = ['Best Match', 'Experience', 'Availability', 'Rating'];

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _tabController = TabController(length: 2, vsync: this);
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final industries = await _firestoreService.getUniqueIndustries();
    if (mounted) {
      setState(() {
        _dynamicFilters = ['All', ...industries];
      });
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _startMatching() async {
    setState(() {
      _isMatching = true;
    });
    
    _loadingController.repeat();
    
    await Future.delayed(const Duration(seconds: 3));
    
    _loadingController.stop();
    setState(() {
      _isMatching = false;
      _matchComplete = true;
    });
  }

  List<AppUser> _filterAlumni(List<AppUser> alumni) {
    if (_selectedFilter == 'All') return alumni;
    return alumni.where((user) => user.industry == _selectedFilter).toList();
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              if (_isMatching) _buildMatchingLoader(),
              if (!_isMatching && !_matchComplete) _buildMatchingPrompt(isDark),
              if (_matchComplete) ...[
                _buildTabBar(isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllAlumniTab(isDark),
                      _buildSavedAlumniTab(isDark),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            iconSize: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find Your Alumni',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'AI-Powered Matching',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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
            Tab(text: 'All Alumni'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAlumniTab(bool isDark) {
    return StreamBuilder<List<AppUser>>(
      stream: _firestoreService.streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allAlumni = snapshot.data ?? [];
        final filteredAlumni = _filterAlumni(allAlumni);

        return Column(
          children: [
            _buildFiltersRow(isDark, filteredAlumni.length),
            Expanded(child: _buildMentorsList(isDark, filteredAlumni)),
          ],
        );
      },
    );
  }

  Widget _buildSavedAlumniTab(bool isDark) {
    final userId = _currentUserId;
    if (userId == null) {
      return const Center(child: Text('Please sign in to view saved alumni'));
    }
    
    return StreamBuilder<List<AppUser>>(
      stream: _firestoreService.streamSavedAlumni(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final savedAlumni = snapshot.data ?? [];
        
        if (savedAlumni.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.bookmark_border_rounded,
                    size: 56,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Saved Alumni',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Save alumni to quickly access their profiles later',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          itemCount: savedAlumni.length,
          itemBuilder: (context, index) {
            return _buildMentorCard(savedAlumni[index], isDark, isSaved: true);
          },
        );
      },
    );
  }

  Widget _buildMatchingPrompt(bool isDark) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              
              const Text(
                'Smart Alumni Matching',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Our AI analyzes your profile, skills, and goals to find the perfect alumni for your career journey',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startMatching,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Find My Alumni',
                        style: TextStyle(
                          fontSize: 18,
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
        ),
      ),
    );
  }

  Widget _buildMatchingLoader() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _loadingController,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Finding your perfect matches...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            const Text(
              'Analyzing your profile and preferences',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow(bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Found $count alumni',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _dynamicFilters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isDark ? Colors.white24 : Colors.black12),
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black87),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              PopupMenuButton<String>(
                initialValue: _selectedSort,
                onSelected: (value) => setState(() => _selectedSort = value),
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  child: const Icon(Icons.tune_rounded),
                ),
                itemBuilder: (context) => _sortOptions.map((option) {
                  return PopupMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMentorsList(bool isDark, List<AppUser> alumni) {
    if (alumni.isEmpty) {
      return Center(
        child: Text(
          "No alumni found.",
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: alumni.length,
      itemBuilder: (context, index) {
        return _buildMentorCard(alumni[index], isDark);
      },
    );
  }

  Widget _buildMentorCard(AppUser user, bool isDark, {bool isSaved = false}) {
    final userId = _currentUserId;
    final matchScore = 95; 
    final rating = 5.0;
    final mentees = 12;
    final sessions = 24;
    final availability = 'High';
    
    return FutureBuilder<bool>(
      future: userId != null 
          ? _firestoreService.isAlumniSaved(userId, user.userId)
          : Future.value(false),
      builder: (context, savedSnapshot) {
        final isAlumniSaved = savedSnapshot.data ?? isSaved;
        
        return GestureDetector(
          // Inside _buildMentorCard in mentor_matching_screen.dart

          onTap: () {
            // Create a comprehensive map that includes everything the detail screen needs
            final mentorData = user.toMap();
            
            // Dynamic data calculations
            final dynamicRating = (4.0 + (user.xp % 20) / 10).clamp(4.0, 5.0).toStringAsFixed(1);
            final dynamicSessions = user.totalSessions > 0 ? '${user.totalSessions}' : '0';
            final dynamicMentees = user.mentorsConnected > 0 ? '${user.mentorsConnected}' : '0'; // Assuming this field tracks connections for alumni too
            
            // Add/Map the specific keys that MentorDetailScreen expects
            mentorData['role'] = user.jobRole ?? 'Alumni';
            mentorData['company'] = user.currentCompany ?? 'N/A';
            mentorData['matchScore'] = matchScore; // Uses the calculated match score from above
            mentorData['rating'] = dynamicRating;
            mentorData['mentees'] = dynamicMentees;
            mentorData['sessions'] = user.totalSessions > 0 ? '${user.totalSessions}' : 'New';
            mentorData['availability'] = availability;
            mentorData['experience'] = '${(user.xp / 100).floor()}+ Years'; // Infer experience from XP for now
            mentorData['responseTime'] = '< 24h';
            mentorData['skills'] = user.skills ?? ['Mentoring']; 
            mentorData['verified'] = user.verificationStatus == VerificationStatus.verified;

            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => MentorDetailScreen(mentor: mentorData),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6C63FF + (user.name.hashCode % 1000)),
                            Color(0xFF4E9FFF + (user.name.hashCode % 1000)),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (user.verificationStatus == VerificationStatus.verified)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00D4AA),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
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
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00D4AA).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 14,
                                      color: Color(0xFF00D4AA),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$matchScore%',
                                      style: const TextStyle(
                                        color: Color(0xFF00D4AA),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          Text(
                            user.jobRole ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          
                          Text(
                            user.currentCompany ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Stats Row
                Row(
                  children: [
                    _buildStatBadge(
                      Icons.star_rounded,
                      '$rating',
                      Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    _buildStatBadge(
                      Icons.groups_rounded,
                      '$mentees',
                      const Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 12),
                    _buildStatBadge(
                      Icons.videocam_rounded,
                      '$sessions',
                      const Color(0xFF00D4AA),
                    ),
                    const Spacer(),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getAvailabilityColor(availability).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        availability,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getAvailabilityColor(availability),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Skills
                if (user.skills != null && user.skills!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.skills!.take(4).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleSaveAlumni(user.userId, isAlumniSaved),
                        icon: Icon(
                          isAlumniSaved 
                              ? Icons.bookmark_rounded 
                              : Icons.bookmark_outline_rounded,
                          color: isAlumniSaved ? const Color(0xFF6C63FF) : null,
                        ),
                        label: Text(isAlumniSaved ? 'Saved' : 'Save'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: isAlumniSaved ? const Color(0xFF6C63FF) : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isAlumniSaved 
                                ? const Color(0xFF6C63FF) 
                                : (isDark ? Colors.white24 : Colors.black12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MentorDetailScreen(mentor: user.toMap()),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('View Profile'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleSaveAlumni(String alumniId, bool isCurrentlySaved) async {
    final userId = _currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save alumni')),
      );
      return;
    }
    
    try {
      if (isCurrentlySaved) {
        await _firestoreService.unsaveAlumni(userId, alumniId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alumni unsaved')),
          );
        }
      } else {
        await _firestoreService.saveAlumni(userId, alumniId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alumni saved!')),
          );
        }
      }
      setState(() {}); // Refresh UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvailabilityColor(String availability) {
    switch (availability) {
      case 'High':
        return const Color(0xFF00D4AA);
      case 'Medium':
        return const Color(0xFFFFA726);
      case 'Low':
        return const Color(0xFFFF6B9D);
      default:
        return Colors.grey;
    }
  }
}