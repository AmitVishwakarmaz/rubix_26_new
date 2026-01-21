import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/mentor_matching_screen.dart';
import 'screens/mentor_detail_screen.dart';
import 'screens/session_booking_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/events_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/career_path_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await dotenv.load(fileName: ".env");
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MentorLinkApp());
}

class MentorLinkApp extends StatelessWidget {
  const MentorLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MentorLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      // Define all routes for easy navigation
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(userId: null, userName: null, userEmail: null,),
        '/student-dashboard': (context) => const StudentDashboard(),
        '/mentor-matching': (context) => const MentorMatchingScreen(),
        '/resources': (context) => const ResourcesScreen(),
        '/events': (context) => const EventsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/career-path': (context) => const CareerPathScreen(),
        '/ai-chat': (context) => const AIChatScreen(),
      },
    );
  }
}

class AppTheme {
  // Premium Color Palette
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color secondaryBlue = Color(0xFF4E9FFF);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color successGreen = Color(0xFF00D4AA);
  static const Color warningOrange = Color(0xFFFFA726);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: const Color(0xFFF8F9FE),
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: secondaryBlue,
      tertiary: accentPink,
      surface: Colors.white,
      background: Color(0xFFF8F9FE),
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFF4A4A68),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF6B6B80),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: const Color(0xFF0F0F1E),
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: secondaryBlue,
      tertiary: accentPink,
      surface: Color(0xFF1A1A2E),
      background: Color(0xFF0F0F1E),
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFFB8B8D0),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF9898AC),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: const Color(0xFF1A1A2E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}