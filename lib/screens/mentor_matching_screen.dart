import 'package:flutter/material.dart';
import 'mentor_detail_screen.dart';

class MentorMatchingScreen extends StatefulWidget {
  const MentorMatchingScreen({Key? key}) : super(key: key);

  @override
  State<MentorMatchingScreen> createState() => _MentorMatchingScreenState();
}

class _MentorMatchingScreenState extends State<MentorMatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  bool _isMatching = false;
  bool _matchComplete = false;
  String _selectedFilter = 'All';
  String _selectedSort = 'Best Match';
  
  final List<String> _filters = ['All', 'Technology', 'Finance', 'Consulting', 'Healthcare'];
  final List<String> _sortOptions = ['Best Match', 'Experience', 'Availability', 'Rating'];
  
  final List<Map<String, dynamic>> _mentors = [
    {
      'name': 'Sarah Johnson',
      'role': 'Senior Software Engineer',
      'company': 'Google',
      'matchScore': 95,
      'experience': '8 years',
      'sessions': 45,
      'rating': 4.9,
      'skills': ['Flutter', 'React', 'Python', 'System Design'],
      'industry': 'Technology',
      'availability': 'High',
      'responseTime': '< 2 hours',
      'mentees': 32,
      'verified': true,
    },
    {
      'name': 'Michael Chen',
      'role': 'Product Manager',
      'company': 'Microsoft',
      'matchScore': 92,
      'experience': '6 years',
      'sessions': 38,
      'rating': 4.8,
      'skills': ['Product Strategy', 'User Research', 'Agile', 'Data Analytics'],
      'industry': 'Technology',
      'availability': 'Medium',
      'responseTime': '< 4 hours',
      'mentees': 28,
      'verified': true,
    },
    {
      'name': 'Priya Patel',
      'role': 'Data Scientist',
      'company': 'Meta',
      'matchScore': 88,
      'experience': '7 years',
      'sessions': 52,
      'rating': 5.0,
      'skills': ['Machine Learning', 'Python', 'AI', 'Deep Learning'],
      'industry': 'Technology',
      'availability': 'High',
      'responseTime': '< 1 hour',
      'mentees': 41,
      'verified': true,
    },
    {
      'name': 'David Kim',
      'role': 'Investment Banker',
      'company': 'Goldman Sachs',
      'matchScore': 82,
      'experience': '9 years',
      'sessions': 29,
      'rating': 4.7,
      'skills': ['Finance', 'Investment', 'M&A', 'Valuation'],
      'industry': 'Finance',
      'availability': 'Low',
      'responseTime': '< 12 hours',
      'mentees': 22,
      'verified': true,
    },
    {
      'name': 'Emily Rodriguez',
      'role': 'Management Consultant',
      'company': 'McKinsey',
      'matchScore': 85,
      'experience': '5 years',
      'sessions': 34,
      'rating': 4.9,
      'skills': ['Strategy', 'Business Analysis', 'Leadership', 'Case Studies'],
      'industry': 'Consulting',
      'availability': 'Medium',
      'responseTime': '< 6 hours',
      'mentees': 26,
      'verified': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
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

  List<Map<String, dynamic>> get _filteredMentors {
    var filtered = _mentors.where((mentor) {
      if (_selectedFilter == 'All') return true;
      return mentor['industry'] == _selectedFilter;
    }).toList();
    
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Experience':
          return b['sessions'].compareTo(a['sessions']);
        case 'Availability':
          return _getAvailabilityScore(b['availability'])
              .compareTo(_getAvailabilityScore(a['availability']));
        case 'Rating':
          return b['rating'].compareTo(a['rating']);
        default:
          return b['matchScore'].compareTo(a['matchScore']);
      }
    });
    
    return filtered;
  }
  
  int _getAvailabilityScore(String availability) {
    switch (availability) {
      case 'High': return 3;
      case 'Medium': return 2;
      case 'Low': return 1;
      default: return 0;
    }
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
                _buildFiltersRow(isDark),
                Expanded(child: _buildMentorsList(isDark)),
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
                'Find Your Mentor',
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
                'Smart Mentor Matching',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Our AI analyzes your profile, skills, and goals to find the perfect mentors for your career journey',
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
                        'Find My Mentors',
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

  Widget _buildFiltersRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Found ${_filteredMentors.length} mentors',
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
                    children: _filters.map((filter) {
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

  Widget _buildMentorsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: _filteredMentors.length,
      itemBuilder: (context, index) {
        return _buildMentorCard(_filteredMentors[index], isDark);
      },
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MentorDetailScreen(mentor: mentor),
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
                        Color(0xFF6C63FF + (mentor['name'].hashCode % 1000)),
                        Color(0xFF4E9FFF + (mentor['name'].hashCode % 1000)),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          mentor['name'][0],
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (mentor['verified'])
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
                              mentor['name'],
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
                                  '${mentor['matchScore']}%',
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
                        mentor['role'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      
                      Text(
                        mentor['company'],
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
                  '${mentor['rating']}',
                  Colors.amber,
                ),
                const SizedBox(width: 12),
                _buildStatBadge(
                  Icons.groups_rounded,
                  '${mentor['mentees']}',
                  const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 12),
                _buildStatBadge(
                  Icons.videocam_rounded,
                  '${mentor['sessions']}',
                  const Color(0xFF00D4AA),
                ),
                const Spacer(),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getAvailabilityColor(mentor['availability']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mentor['availability'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getAvailabilityColor(mentor['availability']),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Skills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (mentor['skills'] as List).take(4).map((skill) {
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
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_outline_rounded),
                    label: const Text('Save'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
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
                          builder: (_) => MentorDetailScreen(mentor: mentor),
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