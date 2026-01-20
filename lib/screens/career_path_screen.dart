import 'package:flutter/material.dart';

class CareerPathScreen extends StatefulWidget {
  const CareerPathScreen({Key? key}) : super(key: key);

  @override
  State<CareerPathScreen> createState() => _CareerPathScreenState();
}

class _CareerPathScreenState extends State<CareerPathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedMajor = 'Computer Science';
  
  final List<String> _majors = [
    'Computer Science',
    'Business Administration',
    'Mechanical Engineering',
    'Data Science',
  ];

  final Map<String, List<Map<String, dynamic>>> _careerPaths = {
    'Computer Science': [
      {
        'level': 1,
        'title': 'Student',
        'subtitle': 'Current Position',
        'avgYears': '0',
        'salary': '\$0',
        'companies': [],
        'skills': ['Programming Basics', 'Problem Solving'],
        'isCurrent': true,
      },
      {
        'level': 2,
        'title': 'Junior Developer',
        'subtitle': 'Entry Level',
        'avgYears': '0-2',
        'salary': '\$60K - \$80K',
        'companies': ['Startups', 'Small Companies'],
        'skills': ['Web Development', 'Version Control', 'Testing'],
        'isCurrent': false,
      },
      {
        'level': 3,
        'title': 'Software Engineer',
        'subtitle': 'Mid Level',
        'avgYears': '2-5',
        'salary': '\$80K - \$120K',
        'companies': ['Google', 'Microsoft', 'Amazon'],
        'skills': ['System Design', 'Architecture', 'Mentoring'],
        'isCurrent': false,
      },
      {
        'level': 4,
        'title': 'Senior Engineer',
        'subtitle': 'Senior Level',
        'avgYears': '5-8',
        'salary': '\$120K - \$180K',
        'companies': ['FAANG', 'Tech Giants'],
        'skills': ['Leadership', 'Strategic Planning', 'Innovation'],
        'isCurrent': false,
      },
      {
        'level': 5,
        'title': 'Tech Lead / Manager',
        'subtitle': 'Leadership',
        'avgYears': '8-12',
        'salary': '\$150K - \$250K',
        'companies': ['Top Tech Companies'],
        'skills': ['Team Management', 'Product Strategy', 'Business Acumen'],
        'isCurrent': false,
      },
      {
        'level': 6,
        'title': 'Engineering Director',
        'subtitle': 'Executive',
        'avgYears': '12+',
        'salary': '\$200K - \$400K+',
        'companies': ['Fortune 500'],
        'skills': ['Organizational Leadership', 'Vision', 'C-Suite Collaboration'],
        'isCurrent': false,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentPath {
    return _careerPaths[_selectedMajor] ?? [];
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
              _buildMajorSelector(isDark),
              Expanded(child: _buildCareerPath(isDark)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildInsightsButton(),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(width: 12),
          
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Career Path',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Visualize your journey',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorSelector(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _majors.length,
        itemBuilder: (context, index) {
          final major = _majors[index];
          final isSelected = _selectedMajor == major;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedMajor = major);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? Colors.white24 : Colors.black12),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                major,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCareerPath(bool isDark) {
    return Stack(
      children: [
        // Background path line
        Positioned.fill(
          child: CustomPaint(
            painter: _PathPainter(
              pathNodes: _currentPath,
              progress: _animationController.value,
              isDark: isDark,
            ),
          ),
        ),
        
        // Career nodes
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: _currentPath.length,
          itemBuilder: (context, index) {
            return _buildCareerNode(_currentPath[index], isDark, index);
          },
        ),
      ],
    );
  }

  Widget _buildCareerNode(
    Map<String, dynamic> node,
    bool isDark,
    int index,
  ) {
    final delay = index * 0.15;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: 24,
          left: index.isEven ? 0 : 40,
          right: index.isEven ? 40 : 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Node indicator
            Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: node['isCurrent']
                        ? const LinearGradient(
                            colors: [Color(0xFF00D4AA), Color(0xFF00A896)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (node['isCurrent']
                                ? const Color(0xFF00D4AA)
                                : const Color(0xFF6C63FF))
                            .withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${node['level']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 20),
            
            // Content card
            Expanded(
              child: GestureDetector(
                onTap: () => _showNodeDetails(node, isDark),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: node['isCurrent']
                          ? const Color(0xFF00D4AA)
                          : (isDark ? Colors.white12 : Colors.black12),
                      width: node['isCurrent'] ? 2 : 1,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  node['title'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  node['subtitle'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (node['isCurrent'])
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D4AA).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00D4AA),
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.access_time_rounded,
                            '${node['avgYears']} years',
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            Icons.attach_money_rounded,
                            node['salary'],
                            isDark,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Key Skills:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (node['skills'] as List).take(3).map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      if ((node['companies'] as List).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Companies: ${(node['companies'] as List).join(', ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsButton() {
    return FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: const Color(0xFF6C63FF),
      icon: const Icon(Icons.insights_rounded, color: Colors.white),
      label: const Text(
        'Get Insights',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showNodeDetails(Map<String, dynamic> node, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node['title'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    node['subtitle'],
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Detailed information about ${node['title']} would be displayed here, including responsibilities, common career transitions, top companies, and advice from alumni...',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.6,
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

class _PathPainter extends CustomPainter {
  final List<Map<String, dynamic>> pathNodes;
  final double progress;
  final bool isDark;

  _PathPainter({
    required this.pathNodes,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (pathNodes.length < 2) return;

    final nodeSpacing = 150.0;
    final startY = 50.0;

    for (int i = 0; i < pathNodes.length - 1; i++) {
      final startX = i.isEven ? 40.0 : 80.0;
      final endX = i.isEven ? 80.0 : 40.0;
      
      final path = Path()
        ..moveTo(startX, startY + (i * nodeSpacing))
        ..quadraticBezierTo(
          (startX + endX) / 2,
          startY + (i * nodeSpacing) + nodeSpacing / 2,
          endX,
          startY + ((i + 1) * nodeSpacing),
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) => progress != oldDelegate.progress;
}