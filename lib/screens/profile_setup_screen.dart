import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'student_dashboard.dart';
import 'alumni_dashboard.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String role;
  
  const ProfileSetupScreen({
    Key? key, 
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
  }) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Common Form Controllers
  final _universityController = TextEditingController();
  final _degreeController = TextEditingController();
  final _majorController = TextEditingController();
  
  // Alumni-specific Controllers
  final _companyController = TextEditingController();
  final _jobRoleController = TextEditingController();
  final _linkedinController = TextEditingController();
  
  String? _selectedGradYear;
  String? _selectedIndustry;
  final List<String> _selectedSkills = [];
  final List<String> _selectedInterests = [];
  final List<String> _selectedMentorshipAreas = [];
  
  final List<String> _availableSkills = [
    'Flutter', 'React', 'Python', 'Java', 'JavaScript',
    'Machine Learning', 'Data Science', 'UI/UX', 'Product Management',
    'Cloud Computing', 'DevOps', 'Mobile Development', 'Web Development',
  ];
  
  final List<String> _careerInterests = [
    'Software Development', 'Product Management', 'Data Science',
    'Consulting', 'Finance', 'Marketing', 'Design', 'Entrepreneurship',
  ];
  
  final List<String> _industries = [
    'Technology', 'Finance', 'Healthcare', 'Consulting', 
    'Education', 'Manufacturing', 'Retail', 'Media', 'Other',
  ];
  
  final List<String> _mentorshipAreas = [
    'Career Guidance', 'Technical Skills', 'Interview Prep',
    'Resume Review', 'Networking', 'Industry Insights', 'Startup Advice',
  ];

  int get _totalSteps => widget.role == 'student' ? 4 : 4;

  @override
  void dispose() {
    _pageController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _majorController.dispose();
    _companyController.dispose();
    _jobRoleController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    setState(() => _isLoading = true);
    
    try {
      Map<String, dynamic> profileData = {
        'profileCompleted': true,
      };
      
      if (widget.role == 'student') {
        profileData.addAll({
          'university': _universityController.text.trim(),
          'degree': _degreeController.text.trim(),
          'major': _majorController.text.trim(),
          'graduationYear': int.tryParse(_selectedGradYear ?? ''),
          'skills': _selectedSkills,
          'careerInterests': _selectedInterests,
        });
      } else {
        // Alumni profile
        profileData.addAll({
          'currentCompany': _companyController.text.trim(),
          'jobRole': _jobRoleController.text.trim(),
          'industry': _selectedIndustry,
          'linkedinUrl': _linkedinController.text.trim(),
          'university': _universityController.text.trim(),
          'graduationYear': int.tryParse(_selectedGradYear ?? ''),
          'mentorshipInterests': _selectedMentorshipAreas,
        });
      }
      
      await _firestoreService.updateUserProfile(widget.userId, profileData);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => widget.role == 'student' 
                ? const StudentDashboard() 
                : const AlumniDashboard(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _completeProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
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
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: widget.role == 'student'
                      ? [
                          _buildBasicInfoStep(isDark),
                          _buildEducationStep(isDark),
                          _buildSkillsStep(isDark),
                          _buildInterestsStep(isDark),
                        ]
                      : [
                          _buildAlumniBasicInfoStep(isDark),
                          _buildAlumniWorkStep(isDark),
                          _buildAlumniEducationStep(isDark),
                          _buildMentorshipStep(isDark),
                        ],
                ),
              ),
              _buildNavigationButtons(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final roleLabel = widget.role == 'student' ? 'Student' : 'Alumni';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back_rounded),
                  iconSize: 28,
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: widget.role == 'student'
                      ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)])
                      : const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Bar
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: isCompleted || isCurrent
                        ? (widget.role == 'student'
                            ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)])
                            : const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]))
                        : null,
                    color: isCompleted || isCurrent
                        ? null
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==================== STUDENT STEPS ====================
  
  Widget _buildBasicInfoStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, ${widget.userName}!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Let\'s set up your student profile', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)]),
                  ),
                  child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF0F0F1E) : Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          _buildInputField(controller: _universityController, label: 'University', icon: Icons.school_rounded, isDark: isDark),
          const SizedBox(height: 16),
          _buildInputField(controller: _degreeController, label: 'Degree (e.g., B.Tech, M.Sc)', icon: Icons.workspace_premium_rounded, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildEducationStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Education Details', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Help us understand your background', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          
          _buildInputField(controller: _majorController, label: 'Major/Specialization', icon: Icons.book_rounded, isDark: isDark),
          const SizedBox(height: 16),
          
          _buildDropdownField(
            label: 'Expected Graduation Year',
            icon: Icons.calendar_today_rounded,
            value: _selectedGradYear,
            items: List.generate(10, (index) => (DateTime.now().year + index).toString()),
            onChanged: (value) => setState(() => _selectedGradYear = value),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Skills', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Select your areas of expertise', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableSkills.map((skill) => _buildChip(skill, _selectedSkills, isDark, const Color(0xFF6C63FF))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Career Interests', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('What career paths interest you?', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _careerInterests.map((interest) => _buildChip(interest, _selectedInterests, isDark, const Color(0xFFFF6B9D))).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== ALUMNI STEPS ====================

  Widget _buildAlumniBasicInfoStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, ${widget.userName}!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Let\'s set up your alumni profile', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)]),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 60, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B9D),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF0F0F1E) : Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          _buildInputField(controller: _linkedinController, label: 'LinkedIn Profile URL', icon: Icons.link_rounded, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildAlumniWorkStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Work Experience', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Tell us about your current role', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          
          _buildInputField(controller: _companyController, label: 'Current Company', icon: Icons.business_rounded, isDark: isDark),
          const SizedBox(height: 16),
          _buildInputField(controller: _jobRoleController, label: 'Job Title/Role', icon: Icons.work_rounded, isDark: isDark),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Industry',
            icon: Icons.category_rounded,
            value: _selectedIndustry,
            items: _industries,
            onChanged: (value) => setState(() => _selectedIndustry = value),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAlumniEducationStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Education Background', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Share your alma mater details', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          
          _buildInputField(controller: _universityController, label: 'University/College', icon: Icons.school_rounded, isDark: isDark),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Graduation Year',
            icon: Icons.calendar_today_rounded,
            value: _selectedGradYear,
            items: List.generate(30, (index) => (DateTime.now().year - index).toString()),
            onChanged: (value) => setState(() => _selectedGradYear = value),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMentorshipStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mentorship Areas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('How would you like to help students?', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _mentorshipAreas.map((area) => _buildChip(area, _selectedMentorshipAreas, isDark, const Color(0xFFFF6B9D))).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildChip(String label, List<String> selectedList, bool isDark, Color accentColor) {
    final isSelected = selectedList.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedList.remove(label);
          } else {
            selectedList.add(label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [accentColor, accentColor.withOpacity(0.7)]) : null,
          color: isSelected ? null : (isDark ? Colors.white12 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white24 : Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.w600)),
            if (isSelected) ...[const SizedBox(width: 8), const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white)],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
          border: InputBorder.none,
        ),
        dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: widget.role == 'student' ? const Color(0xFF6C63FF) : const Color(0xFFFF6B9D)),
                ),
                child: Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.role == 'student' ? const Color(0xFF6C63FF) : const Color(0xFFFF6B9D))),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: widget.role == 'student' ? const Color(0xFF6C63FF) : const Color(0xFFFF6B9D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
