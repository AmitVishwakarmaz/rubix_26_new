import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class CareerPathScreen extends StatefulWidget {
  const CareerPathScreen({Key? key}) : super(key: key);

  @override
  State<CareerPathScreen> createState() => _CareerPathScreenState();
}

class _CareerPathScreenState extends State<CareerPathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

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
          child: StreamBuilder<AppUser?>(
            stream: _firestoreService.streamUser(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final currentUser = userSnapshot.data;
              final interests = currentUser?.careerInterests ?? [];

              return StreamBuilder<List<AppUser>>(
                stream: _firestoreService.streamMatchedAlumni(interests),
                builder: (context, alumniSnapshot) {
                  if (alumniSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final matchedAlumni = alumniSnapshot.data ?? [];

                  return Column(
                    children: [
                      _buildHeader(isDark, currentUser),
                      if (matchedAlumni.isEmpty)
                        Expanded(child: _buildEmptyState(isDark))
                      else
                        Expanded(child: _buildCareerPath(isDark, matchedAlumni)),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No matching alumni found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try updating your career interests in your profile to find relevant mentors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppUser? currentUser) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Row(
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
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alumni Careers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser?.careerInterests != null && currentUser!.careerInterests!.isNotEmpty
                          ? 'Based on your interest in ${currentUser!.careerInterests!.first}'
                          : 'Find your mentors',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _buildInsightsButton(context),
          )
        ],
      ),
    );
  }

  Widget _buildCareerPath(bool isDark, List<AppUser> matchedAlumni) {
    return Stack(
      children: [
        // Background path line
        Positioned.fill(
          child: CustomPaint(
            painter: _PathPainter(
              alumniCount: matchedAlumni.length,
              progress: _animationController.value,
              isDark: isDark,
            ),
          ),
        ),
        
        // Career nodes
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: matchedAlumni.length,
          itemBuilder: (context, index) {
            return _buildAlumniNode(matchedAlumni[index], isDark, index);
          },
        ),
      ],
    );
  }

  Widget _buildAlumniNode(
    AppUser alumni,
    bool isDark,
    int index,
  ) {
    final delay = index * 0.15;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay.clamp(0.0, 0.7), (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut),
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
          left: index.isEven ? 40 : 10,
          right: index.isEven ? 10 : 40,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Node indicator
            Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Content card
            Expanded(
              child: GestureDetector(
                onTap: () => _showAlumniDetails(alumni, isDark),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
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
                                  alumni.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  alumni.jobRole ?? 'Alumni',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (alumni.profileImageUrl != null)
                             CircleAvatar(
                               radius: 16,
                               backgroundImage: NetworkImage(alumni.profileImageUrl!),
                             )
                          else
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, size: 18, color: Color(0xFF6C63FF)),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          if (alumni.currentCompany != null) ...[
                             _buildInfoChip(
                              Icons.business_rounded,
                              alumni.currentCompany!,
                              isDark,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (alumni.mentorshipInterests ?? []).take(2).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            size: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsButton(BuildContext context) {
    return InkWell(
      onTap: () => _showAIInsights(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Insights',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIInsights(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get the current matched alumni for the summary
    final user = _auth.currentUser;
    if (user == null) return;
    
    final currentUser = await _firestoreService.getUser(user.uid);
    final interests = currentUser?.careerInterests ?? [];
    final matchedAlumni = await _firestoreService.getMatchedAlumni(interests);

    String summary = 'No matching alumni found to generate insights.';
    if (matchedAlumni.isNotEmpty) {
      final names = matchedAlumni.take(2).map((a) => a.name).join(' and ');
      final industries = matchedAlumni.map((a) => a.industry).where((i) => i != null).toSet().take(3).join(', ');
      summary = "Found matched alumni like $names who are experts in $industries. They can provide valuable guidance on your career path.";
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded, color: Color(0xFF6C63FF)),
            SizedBox(width: 12),
            Text('AI Career Insights'),
          ],
        ),
        content: Text(
          summary,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great, thanks!', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  void _showAlumniDetails(AppUser alumni, bool isDark) {
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
                  Row(
                    children: [
                      if (alumni.profileImageUrl != null)
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(alumni.profileImageUrl!),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, size: 30, color: Color(0xFF6C63FF)),
                        ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alumni.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              alumni.jobRole ?? 'Alumni',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      'Professional Info',
                      Column(
                        children: [
                          if (alumni.currentCompany != null)
                             _buildDetailRow(Icons.business_rounded, 'Company', alumni.currentCompany!),
                          if (alumni.industry != null)
                             _buildDetailRow(Icons.category_rounded, 'Industry', alumni.industry!),
                          if (alumni.university != null)
                             _buildDetailRow(Icons.school_rounded, 'Alma Mater', alumni.university!),
                          if (alumni.graduationYear != null)
                             _buildDetailRow(Icons.calendar_today_rounded, 'Year', alumni.graduationYear.toString()),
                        ],
                      ),
                      isDark,
                    ),
                    const SizedBox(height: 24),
                    _buildDetailSection(
                      'Mentorship Expertise',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (alumni.mentorshipInterests ?? []).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      isDark,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Widget content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final int alumniCount;
  final double progress;
  final bool isDark;

  _PathPainter({
    required this.alumniCount,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (alumniCount < 2) return;

    final startY = 40.0;
    const nodeSpacing = 160.0;

    for (int i = 0; i < (alumniCount - 1); i++) {
      final startX = i.isEven ? 65.0 : 35.0;
      final endX = i.isEven ? 35.0 : 65.0;
      
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