import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/referral_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gamification_service.dart';
import '../../models/referral_model.dart';
import '../../models/user_model.dart';

class ReferralAvailabilityScreen extends StatefulWidget {
  const ReferralAvailabilityScreen({super.key});

  @override
  State<ReferralAvailabilityScreen> createState() =>
      _ReferralAvailabilityScreenState();
}

class _ReferralAvailabilityScreenState extends State<ReferralAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  final _referralService = ReferralService();
  final _firestoreService = FirestoreService();
  final _gamificationService = GamificationService();

  late TabController _tabController;
  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _firestoreService.getUser(uid);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Referrals', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          tabs: const [
            Tab(text: 'My Availability'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailabilityTab(isDark),
          _buildRequestsTab(isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AVAILABILITY TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAvailabilityTab(bool isDark) {
    return StreamBuilder<ReferralAvailability?>(
      stream: _referralService.streamMyReferral(_currentUser!.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final referral = snapshot.data;

        if (referral == null) {
          return _buildSetupForm(isDark);
        }

        return _buildAvailabilityCard(isDark, referral);
      },
    );
  }

  Widget _buildSetupForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.volunteer_activism, size: 60, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Help Students Get Referrals',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your referral availability to help students land their dream jobs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _ReferralSetupForm(
            user: _currentUser!,
            onSave: (company, role, department, skills, requirements) async {
              await _referralService.setReferralAvailability(
                alumniId: _currentUser!.userId,
                alumniName: _currentUser!.name,
                alumniProfileImage: _currentUser!.profileImageUrl,
                company: company,
                role: role,
                department: department,
                skills: skills,
                requirements: requirements,
              );
              
              // Award XP for setting up referral
              await _gamificationService.awardXP(
                _currentUser!.userId,
                20,
                'Set up referral availability',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Referral availability set! +20 XP'),
                    backgroundColor: Color(0xFF00D4AA),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(bool isDark, ReferralAvailability referral) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: referral.isAvailable
                    ? const Color(0xFF00D4AA)
                    : Colors.grey,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          referral.isAvailable
                              ? 'Referrals Open'
                              : 'Referrals Closed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: referral.isAvailable
                                ? const Color(0xFF00D4AA)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          referral.isAvailable
                              ? 'Students can send you requests'
                              : 'Not accepting requests now',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: referral.isAvailable,
                      activeColor: const Color(0xFF00D4AA),
                      onChanged: (value) async {
                        await _referralService.toggleAvailability(
                            referral.id, value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(isDark, Icons.business, 'Company', referral.company),
                const Divider(height: 24),
                _buildInfoRow(isDark, Icons.work, 'Role', referral.role),
                if (referral.department != null) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                      isDark, Icons.category, 'Department', referral.department!),
                ],
                if (referral.skills.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Looking for skills:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: referral.skills
                        .map((skill) => Chip(
                              label: Text(skill, style: const TextStyle(fontSize: 12)),
                              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Edit Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditDialog(referral),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                side: const BorderSide(color: Color(0xFF6C63FF)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditDialog(ReferralAvailability referral) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _ReferralSetupForm(
            user: _currentUser!,
            initialCompany: referral.company,
            initialRole: referral.role,
            initialDepartment: referral.department,
            initialSkills: referral.skills,
            initialRequirements: referral.requirements,
            onSave: (company, role, department, skills, requirements) async {
              await _referralService.setReferralAvailability(
                alumniId: _currentUser!.userId,
                alumniName: _currentUser!.name,
                alumniProfileImage: _currentUser!.profileImageUrl,
                company: company,
                role: role,
                department: department,
                skills: skills,
                requirements: requirements,
              );
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REQUESTS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRequestsTab(bool isDark) {
    return StreamBuilder<List<ReferralRequest>>(
      stream: _referralService.streamAlumniRequests(_currentUser!.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 80,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No referral requests yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(isDark, requests[index]);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(bool isDark, ReferralRequest request) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (request.status) {
      case ReferralStatus.accepted:
        statusColor = const Color(0xFF00D4AA);
        statusText = 'Accepted';
        statusIcon = Icons.check_circle;
        break;
      case ReferralStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      case ReferralStatus.resumeRequested:
        statusColor = Colors.orange;
        statusText = 'Resume Requested';
        statusIcon = Icons.description;
        break;
      default:
        statusColor = const Color(0xFF6C63FF);
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                  backgroundImage: request.studentProfileImage != null
                      ? NetworkImage(request.studentProfileImage!)
                      : null,
                  child: request.studentProfileImage == null
                      ? Text(
                          request.studentName.isNotEmpty
                              ? request.studentName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (request.studentEmail != null)
                        Text(
                          request.studentEmail!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${request.message}"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
            if (request.resumeUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resume Uploaded',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            request.resumeUrl!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openResumeUrl(request.resumeUrl!),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
            ],
            if (request.isPending || request.isResumeRequested) ...[
              const SizedBox(height: 16),
              // First row: Reject and Ask Resume
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (request.resumeUrl == null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _requestResume(request),
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Ask Resume'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Second row: Accept button (full width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _acceptRequest(request),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept Referral Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(ReferralRequest request) async {
    await _referralService.acceptRequest(request.id);
    await _gamificationService.awardXP(
      _currentUser!.userId,
      15,
      'Accepted a referral request',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request accepted! +15 XP'),
          backgroundColor: Color(0xFF00D4AA),
        ),
      );
    }
  }

  Future<void> _rejectRequest(ReferralRequest request) async {
    await _referralService.rejectRequest(request.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    }
  }

  Future<void> _requestResume(ReferralRequest request) async {
    await _referralService.requestResume(request.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume requested from student'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _openResumeUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // Try to launch directly - canLaunchUrl often returns false on Android
      // for valid URLs like drive.google.com
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open resume link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SETUP FORM WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _ReferralSetupForm extends StatefulWidget {
  final AppUser user;
  final String? initialCompany;
  final String? initialRole;
  final String? initialDepartment;
  final List<String>? initialSkills;
  final String? initialRequirements;
  final Function(String company, String role, String? department,
      List<String> skills, String? requirements) onSave;

  const _ReferralSetupForm({
    required this.user,
    this.initialCompany,
    this.initialRole,
    this.initialDepartment,
    this.initialSkills,
    this.initialRequirements,
    required this.onSave,
  });

  @override
  State<_ReferralSetupForm> createState() => _ReferralSetupFormState();
}

class _ReferralSetupFormState extends State<_ReferralSetupForm> {
  late final _companyController = TextEditingController(
      text: widget.initialCompany ?? widget.user.currentCompany ?? '');
  late final _roleController = TextEditingController(
      text: widget.initialRole ?? widget.user.jobRole ?? '');
  late final _departmentController =
      TextEditingController(text: widget.initialDepartment ?? '');
  late final _requirementsController =
      TextEditingController(text: widget.initialRequirements ?? '');
  late final _skillController = TextEditingController();

  late List<String> _skills = widget.initialSkills?.toList() ?? [];
  bool _isSaving = false;

  // Common skills for referrals
  static const List<String> _suggestedSkills = [
    'Python',
    'Java',
    'JavaScript',
    'React',
    'Node.js',
    'Flutter',
    'AWS',
    'Docker',
    'Machine Learning',
    'Data Science',
    'SQL',
    'System Design',
    'Problem Solving',
    'Communication',
    'Leadership',
  ];

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    _requirementsController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _companyController,
          decoration: InputDecoration(
            labelText: 'Company *',
            hintText: 'e.g., Google, Microsoft',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _roleController,
          decoration: InputDecoration(
            labelText: 'Role *',
            hintText: 'e.g., Software Engineer, Product Manager',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.work),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _departmentController,
          decoration: InputDecoration(
            labelText: 'Department (Optional)',
            hintText: 'e.g., Engineering, Marketing',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.category),
          ),
        ),
        const SizedBox(height: 16),
        // Skill Suggestions
        const Text(
          'Suggested Skills (tap to add):',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedSkills
              .where((skill) => !_skills.contains(skill))
              .map((skill) => ActionChip(
                    label: Text(skill, style: const TextStyle(fontSize: 12)),
                    onPressed: () => setState(() => _skills.add(skill)),
                    backgroundColor: Colors.grey.withOpacity(0.2),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _skillController,
          decoration: InputDecoration(
            labelText: 'Or type custom skill',
            hintText: 'Type and press Enter',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.psychology),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addSkill,
            ),
          ),
          onSubmitted: (_) => _addSkill(),
        ),
        if (_skills.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Selected Skills:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills
                .map((skill) => Chip(
                      label: Text(skill),
                      onDeleted: () => setState(() => _skills.remove(skill)),
                      backgroundColor:
                          const Color(0xFF6C63FF).withOpacity(0.2),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _requirementsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Additional Requirements (Optional)',
            hintText: 'Any specific requirements for referral',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save Referral Availability',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
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

  Future<void> _save() async {
    final company = _companyController.text.trim();
    final role = _roleController.text.trim();

    if (company.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company and Role are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        company,
        role,
        _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim(),
        _skills,
        _requirementsController.text.trim().isEmpty
            ? null
            : _requirementsController.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
