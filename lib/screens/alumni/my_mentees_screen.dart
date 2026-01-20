import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/new_model.dart';
import '../connect/quick_meeting_screen.dart';

class MyMenteesScreen extends StatelessWidget {
  const MyMenteesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestoreService = FirestoreService();
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Please log in")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentoring Sessions"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
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
        child: _buildAcceptedSessionsList(context, isDark, firestoreService, user.uid),
      ),
    );
  }

  Widget _buildAcceptedSessionsList(
    BuildContext context,
    bool isDark,
    FirestoreService firestoreService,
    String uid,
  ) {
    return StreamBuilder<List<SessionBooking>>(
      stream: firestoreService.streamAcceptedSessionsForAlumni(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined, 
                    size: 64, 
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "No upcoming sessions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Accept requests to schedule sessions",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _buildSessionCard(context, isDark, session, firestoreService);
          },
        );
      },
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    bool isDark,
    SessionBooking session,
    FirestoreService firestoreService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: const Color(0xFF6C63FF).withOpacity(0.2),
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      session.studentName.isNotEmpty ? session.studentName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.purpose,
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(Icons.calendar_today_rounded, session.date, isDark),
                  Container(width: 1, height: 40, color: isDark ? Colors.white12 : Colors.black12),
                  _buildInfoItem(Icons.access_time_rounded, session.time, isDark),
                  Container(width: 1, height: 40, color: isDark ? Colors.white12 : Colors.black12),
                  _buildInfoItem(Icons.timer_rounded, session.duration, isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final roomName = session.meetingLink ?? 'session_${session.id.substring(0, 8)}';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuickMeetingScreen(
                            roomName: roomName,
                            title: 'Session with ${session.studentName}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.videocam_rounded, size: 20),
                    label: const Text(
                      'Join Meeting',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Complete Session'),
                          content: const Text('Mark this session as completed?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D4AA),
                              ),
                              child: const Text('Complete'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        await firestoreService.updateSessionStatus(session.id, 'completed');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Session marked as completed!'),
                            backgroundColor: Color(0xFF00D4AA),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF00D4AA)),
                    tooltip: 'Mark as Complete',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
