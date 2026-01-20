import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/alumni_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/student_profile_screen.dart';
import 'screens/alumni_profile_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

// Hardcoded admin emails for hackathon simplicity
const List<String> adminEmails = [
  'admin@alumni.com',
  'admin@rubix.com',
  // Add your admin email here
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Firebase, handle missing config
  bool firebaseInitialized = false;
  String? firebaseError;
  
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    firebaseError = e.toString();
    debugPrint('Firebase initialization failed: $e');
  }
  
  runApp(MyApp(
    firebaseInitialized: firebaseInitialized,
    firebaseError: firebaseError,
  ));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? firebaseError;
  
  const MyApp({
    super.key,
    required this.firebaseInitialized,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alumni Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: firebaseInitialized 
          ? const AuthWrapper() 
          : FirebaseSetupScreen(error: firebaseError),
    );
  }
}

/// Screen shown when Firebase is not configured
class FirebaseSetupScreen extends StatelessWidget {
  final String? error;
  
  const FirebaseSetupScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.settings_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Firebase Setup Required',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'To run this app, please:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStep('1', 'Create Firebase project at console.firebase.google.com'),
                        _buildStep('2', 'Add Android app to your project'),
                        _buildStep('3', 'Download google-services.json'),
                        _buildStep('4', 'Place it in android/app/ folder'),
                        _buildStep('5', 'Enable Google Sign-In & Email auth'),
                        _buildStep('6', 'Create Firestore database'),
                        _buildStep('7', 'Restart the app'),
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Error: $error',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper widget that handles authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final user = snapshot.data!;
        
        // Check if user is admin
        if (adminEmails.contains(user.email)) {
          return const AdminDashboard();
        }

        // Logged in - check user profile status
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserStatus(user.uid),
          builder: (context, statusSnapshot) {
            if (statusSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final status = statusSnapshot.data;
            
            // New user without role - they need to select one
            if (status == null || status['role'] == null) {
              return const LoginScreen();
            }

            final role = status['role'] as String;
            final profileCompleted = status['profileCompleted'] as bool? ?? false;

            // Profile not completed - redirect to profile screen
            if (!profileCompleted) {
              if (role == 'student') {
                return const StudentProfileScreen();
              } else {
                return const AlumniProfileScreen();
              }
            }

            // Navigate based on role
            if (role == 'student') {
              return const StudentDashboard();
            } else if (role == 'alumni') {
              return const AlumniDashboard();
            } else {
              return const AdminDashboard();
            }
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserStatus(String userId) async {
    final firestoreService = FirestoreService();
    final user = await firestoreService.getUser(userId);
    if (user == null) return null;
    return {
      'role': user.role,
      'profileCompleted': user.profileCompleted,
      'verificationStatus': user.verificationStatus.name,
    };
  }
}
