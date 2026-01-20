import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/google_calendar_service.dart';
import '../models/new_model.dart';

class SessionBookingScreen extends StatefulWidget {
  final Map<String, dynamic> mentor;
  
  const SessionBookingScreen({Key? key, required this.mentor}) : super(key: key);

  @override
  State<SessionBookingScreen> createState() => _SessionBookingScreenState();
}

class _SessionBookingScreenState extends State<SessionBookingScreen> {
  int _currentStep = 0;
  String? _selectedDate;
  String? _selectedTime;
  String? _selectedDuration;
  String? _selectedPurpose;
  final _notesController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  final List<String> _purposes = [
    'Career Guidance',
    'Resume Review',
    'Interview Preparation',
    'Industry Insights',
    'Skill Development',
    'Networking Advice',
  ];

  final List<String> _durations = ['30 min', '45 min', '60 min'];
  
  final List<String> _availableDates = [
    'Jan 22, 2026',
    'Jan 23, 2026',
    'Jan 25, 2026',
    'Jan 26, 2026',
  ];

  final Map<String, List<String>> _availableTimes = {
    'Jan 22, 2026': ['9:00 AM', '11:00 AM', '2:00 PM', '4:00 PM'],
    'Jan 23, 2026': ['10:00 AM', '1:00 PM', '3:00 PM', '5:00 PM'],
    'Jan 25, 2026': ['9:00 AM', '12:00 PM', '3:00 PM', '6:00 PM'],
    'Jan 26, 2026': ['8:00 AM', '11:00 AM', '2:00 PM', '5:00 PM'],
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedPurpose != null && _selectedDuration != null;
      case 1:
        return _selectedDate != null;
      case 2:
        return _selectedTime != null;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _confirmBooking();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _confirmBooking() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a session')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user's name from Firestore
      final userData = await _firestoreService.getUser(currentUser.uid);
      final studentName = userData?.name ?? currentUser.displayName ?? 'Student';

      // Debug: print mentor data to see what's available
      print('🔍 Mentor data keys: ${widget.mentor.keys.toList()}');
      print('🔍 userId: ${widget.mentor['userId']}');
      print('🔍 id: ${widget.mentor['id']}');
      print('🔍 name: ${widget.mentor['name']}');

      final alumniId = widget.mentor['userId'] ?? widget.mentor['id'] ?? '';
      print('📧 Using Alumni ID: $alumniId');

      // Create session booking
      final session = SessionBooking(
        id: const Uuid().v4(),
        studentId: currentUser.uid,
        studentName: studentName,
        alumniId: alumniId,
        alumniName: widget.mentor['name'] ?? 'Mentor',
        purpose: _selectedPurpose ?? '',
        duration: _selectedDuration ?? '',
        date: _selectedDate ?? '',
        time: _selectedTime ?? '',
        notes: _notesController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestoreService.bookSession(session);

      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildSuccessDialog(),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking session: $e')),
        );
      }
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
              _buildProgressIndicator(isDark),
              Expanded(child: _buildStepContent(isDark)),
              _buildNavigationButtons(isDark),
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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Book a Session',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'with ${widget.mentor['name']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    final steps = ['Purpose', 'Date', 'Time', 'Confirm'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? const Color(0xFF6C63FF)
                              : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                    
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: isCompleted || isCurrent
                            ? const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                              )
                            : null,
                        color: isCompleted || isCurrent
                            ? null
                            : (isDark ? Colors.white12 : Colors.black12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted && index < _currentStep - 1
                              ? const Color(0xFF6C63FF)
                              : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent
                        ? const Color(0xFF6C63FF)
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildPurposeStep(isDark);
      case 1:
        return _buildDateStep(isDark);
      case 2:
        return _buildTimeStep(isDark);
      case 3:
        return _buildConfirmStep(isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPurposeStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'What would you like to discuss?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          ..._purposes.map((purpose) {
            final isSelected = _selectedPurpose == purpose;
            return GestureDetector(
              onTap: () => setState(() => _selectedPurpose = purpose),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getPurposeIcon(purpose),
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        purpose,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 24),
          const Text(
            'Session Duration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: _durations.map((duration) {
              final isSelected = _selectedDuration == duration;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDuration = duration),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? Colors.white12 : Colors.black12),
                      ),
                    ),
                    child: Text(
                      duration,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Select a Date',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          ..._availableDates.map((date) {
            final isSelected = _selectedDate == date;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                  _selectedTime = null; // Reset time when date changes
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        date,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFF00D4AA).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_availableTimes[date]?.length ?? 0} slots',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF00D4AA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimeStep(bool isDark) {
    final times = _selectedDate != null
        ? (_availableTimes[_selectedDate!] ?? [])
        : [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Available Times',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'for $_selectedDate',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: times.length,
            itemBuilder: (context, index) {
              final time = times[index];
              final isSelected = _selectedTime == time;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedTime = time),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Session Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  Icons.person_rounded,
                  'Mentor',
                  widget.mentor['name'],
                  isDark,
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  Icons.description_rounded,
                  'Purpose',
                  _selectedPurpose ?? '',
                  isDark,
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  Icons.access_time_rounded,
                  'Duration',
                  _selectedDuration ?? '',
                  isDark,
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  Icons.calendar_today_rounded,
                  'Date',
                  _selectedDate ?? '',
                  isDark,
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  Icons.schedule_rounded,
                  'Time',
                  _selectedTime ?? '',
                  isDark,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Additional Notes (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell your mentor what you\'d like to focus on...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_canProceed && !_isLoading) ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentStep == 3 ? 'Confirm Booking' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 48,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Session Booked!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              'Your session with ${widget.mentor['name']} is confirmed for $_selectedDate at $_selectedTime',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Add to Calendly button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openCalendly(),
                icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                label: const Text(
                  'Add to Calendar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Go to Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCalendly() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await GoogleCalendarService.addSessionToCalendar(
        mentorName: widget.mentor['name'] ?? 'Mentor',
        mentorEmail: widget.mentor['email'] ?? '',
        date: _selectedDate ?? '',
        time: _selectedTime ?? '',
        duration: _selectedDuration ?? '30 min',
        purpose: _selectedPurpose ?? 'Mentoring',
        notes: _notesController.text,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result['message'] ?? 'Event added to calendar!')),
                ],
              ),
              backgroundColor: const Color(0xFF00D4AA),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not add to calendar: ${result['error']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      print('Calendar error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getPurposeIcon(String purpose) {
    switch (purpose) {
      case 'Career Guidance':
        return Icons.trending_up_rounded;
      case 'Resume Review':
        return Icons.description_rounded;
      case 'Interview Preparation':
        return Icons.quiz_rounded;
      case 'Industry Insights':
        return Icons.lightbulb_rounded;
      case 'Skill Development':
        return Icons.psychology_rounded;
      case 'Networking Advice':
        return Icons.people_rounded;
      default:
        return Icons.chat_rounded;
    }
  }
}