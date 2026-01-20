import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/new_model.dart';

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
        title: const Text("My Mentees"),
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
        child: StreamBuilder<List<MentorshipRequest>>(
          stream: firestoreService.getMyMentees(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final mentees = snapshot.data ?? [];

            if (mentees.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "No mentees yet",
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mentees.length,
              itemBuilder: (context, index) {
                final request = mentees[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6C63FF),
                      child: Text(request.studentName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(
                      request.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text("Since ${request.date.year}-${request.date.month}-${request.date.day}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.message_rounded, color: Color(0xFF6C63FF)),
                      onPressed: () {
                        // Navigate to chat
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}