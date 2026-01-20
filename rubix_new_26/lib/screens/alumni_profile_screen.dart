import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'alumni_dashboard.dart';

class AlumniProfileScreen extends StatefulWidget {
  const AlumniProfileScreen({super.key});

  @override
  State<AlumniProfileScreen> createState() => _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends State<AlumniProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobRoleController = TextEditingController();
  final _industryController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _skillController = TextEditingController();
  
  final List<String> _skills = [];
  final List<String> _selectedMentorshipInterests = [];
  bool _isLoading = false;

  final List<String> _mentorshipOptions = [
    'Career Guidance',
    'Resume Review',
    'Interview Prep',
    'Startup Advice',
    'Technical Mentoring',
    'Industry Insights',
  ];

  final List<String> _industryOptions = [
    'Technology',
    'Finance',
    'Healthcare',
    'Consulting',
    'Education',
    'Manufacturing',
    'Retail',
    'Media',
    'Government',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _firestoreService.getUser(user.uid);
      if (profile != null) {
        setState(() {
          _nameController.text = profile.name;
          _universityController.text = profile.university ?? '';
          _graduationYearController.text = profile.graduationYear?.toString() ?? '';
          _companyController.text = profile.currentCompany ?? '';
          _jobRoleController.text = profile.jobRole ?? '';
          _industryController.text = profile.industry ?? '';
          _linkedinController.text = profile.linkedinUrl ?? '';
          if (profile.skills != null) _skills.addAll(profile.skills!);
          if (profile.mentorshipInterests != null) {
            _selectedMentorshipInterests.addAll(profile.mentorshipInterests!);
          }
        });
      } else {
        _nameController.text = user.displayName ?? '';
      }
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one skill')),
      );
      return;
    }
    if (_selectedMentorshipInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one mentorship interest')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await _firestoreService.updateUserProfile(user.uid, {
        'name': _nameController.text.trim(),
        'university': _universityController.text.trim(),
        'graduationYear': int.tryParse(_graduationYearController.text.trim()),
        'currentCompany': _companyController.text.trim(),
        'jobRole': _jobRoleController.text.trim(),
        'industry': _industryController.text.trim(),
        'linkedinUrl': _linkedinController.text.trim(),
        'skills': _skills,
        'mentorshipInterests': _selectedMentorshipInterests,
        'profileCompleted': true,
        'verificationStatus': 'pending',
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AlumniDashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _graduationYearController.dispose();
    _companyController.dispose();
    _jobRoleController.dispose();
    _industryController.dispose();
    _linkedinController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.work, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Alumni Verification',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _universityController,
                            label: 'University (Alma Mater)',
                            icon: Icons.account_balance,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _graduationYearController,
                            label: 'Graduation Year',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v!.isEmpty) return 'Required';
                              final year = int.tryParse(v);
                              if (year == null || year < 1960 || year > 2025) {
                                return 'Enter valid year';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _companyController,
                                  label: 'Current Company',
                                  icon: Icons.business,
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _jobRoleController,
                                  label: 'Job Role',
                                  icon: Icons.badge,
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Industry Dropdown
                          const Text(
                            'Industry',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _industryController.text.isEmpty 
                                ? null 
                                : _industryController.text,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: _industryOptions.map((industry) {
                              return DropdownMenuItem(
                                value: industry,
                                child: Text(industry),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _industryController.text = value ?? '');
                            },
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _linkedinController,
                            label: 'LinkedIn URL',
                            icon: Icons.link,
                            keyboardType: TextInputType.url,
                            validator: (v) {
                              if (v!.isEmpty) return 'Required';
                              if (!v.contains('linkedin.com')) {
                                return 'Enter valid LinkedIn URL';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Skills
                          const Text(
                            'Skills',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _skillController,
                                  decoration: InputDecoration(
                                    hintText: 'Add a skill',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (_) => _addSkill(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _addSkill,
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF667eea),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _skills.map((skill) => Chip(
                              label: Text(skill),
                              onDeleted: () => _removeSkill(skill),
                              backgroundColor: const Color(0xFF667eea).withValues(alpha: 0.1),
                            )).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Mentorship Interests
                          const Text(
                            'Mentorship Interests',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'What areas are you willing to mentor students in?',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _mentorshipOptions.map((interest) {
                              final isSelected = _selectedMentorshipInterests.contains(interest);
                              return FilterChip(
                                label: Text(interest),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedMentorshipInterests.add(interest);
                                    } else {
                                      _selectedMentorshipInterests.remove(interest);
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFF667eea).withValues(alpha: 0.2),
                                checkmarkColor: const Color(0xFF667eea),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Submit for Verification',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Your profile will be reviewed by an admin',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
