import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleCalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      gcal.CalendarApi.calendarEventsScope,
    ],
  );

  /// Add a session booking event to the user's Google Calendar
  static Future<Map<String, dynamic>> addSessionToCalendar({
    required String mentorName,
    required String mentorEmail,
    required String date,      // Format: "Jan 22, 2026"
    required String time,      // Format: "9:00 AM"
    required String duration,  // Format: "30 min"
    required String purpose,
    String? notes,
  }) async {
    try {
      // Sign in with Google if not already signed in
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      
      if (account == null) {
        return {
          'success': false,
          'error': 'Google Sign-In cancelled',
        };
      }

      // Get authenticated HTTP client using the extension
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        return {
          'success': false,
          'error': 'Could not get authenticated client',
        };
      }

      // Create Calendar API instance
      final calendarApi = gcal.CalendarApi(httpClient);

      // Parse date and time
      final eventDateTime = _parseDateTime(date, time);
      if (eventDateTime == null) {
        return {
          'success': false,
          'error': 'Could not parse date/time: $date $time',
        };
      }

      // Parse duration
      final durationMinutes = _parseDuration(duration);
      final endDateTime = eventDateTime.add(Duration(minutes: durationMinutes));

      // Create the event
      final event = gcal.Event(
        summary: 'Mentoring Session with $mentorName',
        description: '''
Purpose: $purpose
Duration: $duration
${notes != null && notes.isNotEmpty ? 'Notes: $notes' : ''}

This session was booked via the Mentorship App.
''',
        start: gcal.EventDateTime(
          dateTime: eventDateTime,
          timeZone: 'Asia/Kolkata', // Indian Standard Time
        ),
        end: gcal.EventDateTime(
          dateTime: endDateTime,
          timeZone: 'Asia/Kolkata',
        ),
        attendees: mentorEmail.isNotEmpty ? [
          gcal.EventAttendee(
            email: mentorEmail,
            displayName: mentorName,
          ),
        ] : null,
        reminders: gcal.EventReminders(
          useDefault: false,
          overrides: [
            gcal.EventReminder(method: 'email', minutes: 60),     // 1 hour before
            gcal.EventReminder(method: 'popup', minutes: 15),     // 15 min before
          ],
        ),
        colorId: '7', // Cyan color for mentoring sessions
      );

      // Insert the event
      final createdEvent = await calendarApi.events.insert(
        event,
        'primary', // Primary calendar
        sendUpdates: 'all', // Send invites to attendees
      );

      return {
        'success': true,
        'eventId': createdEvent.id,
        'eventLink': createdEvent.htmlLink,
        'message': 'Event added to calendar successfully!',
      };
    } catch (e) {
      print('Google Calendar Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Parse date string like "Jan 22, 2026" and time like "9:00 AM"
  static DateTime? _parseDateTime(String date, String time) {
    try {
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
        'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
        'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
      };

      // Parse date: "Jan 22, 2026"
      final dateParts = date.replaceAll(',', '').split(' ');
      if (dateParts.length < 3) return null;

      final month = months[dateParts[0]];
      final day = int.tryParse(dateParts[1]);
      final year = int.tryParse(dateParts[2]);

      if (month == null || day == null || year == null) return null;

      // Parse time: "9:00 AM"
      final timeParts = time.split(' ');
      final timeValues = timeParts[0].split(':');
      var hour = int.tryParse(timeValues[0]) ?? 9;
      final minute = int.tryParse(timeValues.length > 1 ? timeValues[1] : '0') ?? 0;

      if (timeParts.length > 1) {
        if (timeParts[1].toUpperCase() == 'PM' && hour != 12) {
          hour += 12;
        } else if (timeParts[1].toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print('Date parsing error: $e');
      return null;
    }
  }

  /// Parse duration string like "30 min" or "1 hour"
  static int _parseDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    if (match != null) {
      final value = int.tryParse(match.group(1)!) ?? 30;
      if (duration.toLowerCase().contains('hour')) {
        return value * 60;
      }
      return value;
    }
    return 30; // Default 30 minutes
  }

  /// Check if user is signed in with calendar scope
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
