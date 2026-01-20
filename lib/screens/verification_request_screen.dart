import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_seed_service.dart';
import '../services/firestore_service.dart';
import '../services/verification_api_service.dart';
import '../models/user_model.dart';
import 'dart:convert';

/// Screen for students/alumni to register for E-ID verification
class VerificationRequestScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String email;
  final String role;

  const VerificationRequestScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  State<VerificationRequestScreen> createState() => _VerificationRequestScreenState();
}

class _VerificationRequestScreenState extends State<VerificationRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _seedService = FirebaseSeedService();
  final _firestoreService = FirestoreService();
  
  List<Map<String, dynamic>> _universities = [];
  String? _selectedUniversityId;
  AppUser? _userProfile;
  Map<String, dynamic>? _existingVerification;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _seedService.seedDemoData();
    await _loadUniversities();
    await _loadUserProfile();
    await _checkExistingVerification();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _firestoreService.getUser(widget.userId);
      if (profile != null && mounted) {
        setState(() {
          _userProfile = profile;
        });
        
        // Auto-select university if user has one in their profile
        if (profile.university != null && profile.university!.isNotEmpty) {
          _autoSelectUniversity(profile.university!);
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }
  
  void _autoSelectUniversity(String universityName) {
    // Try to find matching university by name
    for (var uni in _universities) {
      if ((uni['name'] as String).toLowerCase() == universityName.toLowerCase()) {
        setState(() {
          _selectedUniversityId = uni['id'] as String;
        });
        break;
      }
    }
  }

  Future<void> _loadUniversities() async {
    final universities = await _seedService.getUniversities();
    setState(() {
      _universities = universities;
      _isLoading = false;
    });
  }

  Future<void> _checkExistingVerification() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('verification_requests')
          .where('userId', isEqualTo: widget.userId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _existingVerification = querySnapshot.docs.first.data();
        });
      }
    } catch (e) {
      print('Error checking existing verification: $e');
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUniversityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a university')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Call backend API to create E-ID with JWT and QR
      final result = await VerificationApiService.registerForEid(
        userId: widget.userId,
        name: widget.name,
        email: widget.email,
        universityId: _selectedUniversityId!,
        role: widget.role,
        enteredId: _idController.text.trim(),
      );

      if (result['success'] == true) {
        // Save to Firestore with JWT and QR
        await FirebaseFirestore.instance.collection('verification_requests').doc(result['eid']).set({
          'eid': result['eid'],
          'userId': widget.userId,
          'name': widget.name,
          'email': widget.email,
          'universityId': _selectedUniversityId,
          'role': widget.role,
          'enteredId': _idController.text.trim(),
          'autoMatched': result['autoMatched'],
          'matchedData': result['matchedData'],
          'jwtToken': result['jwt_token'],
          'qr_base64': result['qr_base64'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update user document
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'verificationStatus': 'pending',
          'eid': result['eid'],
        });

        setState(() => _isSubmitting = false);
        _showSuccessDialog(result);
      } else {
        throw Exception(result['error'] ?? 'Failed to create E-ID');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    final matched = result['autoMatched'] == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('E-ID Created!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // E-ID Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.role == 'student'
                        ? [const Color(0xFF6C63FF), const Color(0xFF4E9FFF)]
                        : [const Color(0xFFFF6B9D), const Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.badge, size: 40, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      result['eid'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // QR Code
              if (result['qr_base64'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.memory(
                    base64Decode(result['qr_base64']),
                    width: 150,
                    height: 150,
                  ),
                ),
              const SizedBox(height: 16),

              // Match Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: matched ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      matched ? Icons.verified : Icons.pending,
                      color: matched ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      matched ? '✅ ID Matched!' : '⏳ Awaiting Review',
                      style: TextStyle(
                        color: matched ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Show your QR code to admin for verification',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Refresh data from Firestore to get actual status
              await _checkExistingVerification();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == 'student' ? 'Student Verification' : 'Alumni Verification'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            )
          : _existingVerification != null
              ? _buildExistingEIDView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.role == 'student'
                              ? [const Color(0xFF6C63FF), const Color(0xFF4E9FFF)]
                              : [const Color(0xFFFF6B9D), const Color(0xFFFFA726)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.badge, size: 56, color: Colors.white),
                          const SizedBox(height: 12),
                          const Text(
                            'Get Your E-ID',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Verified ${widget.role == 'student' ? 'Student' : 'Alumni'} Identity',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // University Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select University',
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white70 
                              : Colors.black87,
                        ),
                        prefixIcon: Icon(
                          Icons.school,
                          color: widget.role == 'student' 
                              ? const Color(0xFF6C63FF) 
                              : const Color(0xFFFF6B9D),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1A1A2E)
                            : Colors.grey.shade50,
                      ),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1A1A2E)
                          : Colors.white,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black87,
                        fontSize: 16,
                      ),
                      value: _selectedUniversityId,
                      hint: Text(
                        'Choose your university',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white54 
                              : Colors.black54,
                        ),
                      ),
                      isExpanded: true,
                      items: _universities.map((uni) {
                        return DropdownMenuItem<String>(
                          value: uni['id'] as String,
                          child: Text(
                            uni['name'] as String,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedUniversityId = value),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // ID Input
                    TextFormField(
                      controller: _idController,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: widget.role == 'student' ? 'Student ID' : 'Alumni ID',
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white70 
                              : Colors.black87,
                        ),
                        hintText: widget.role == 'student' ? 'e.g., IITD2023001' : 'e.g., IITDALUM001',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white38 
                              : Colors.black38,
                        ),
                        prefixIcon: Icon(
                          Icons.numbers,
                          color: widget.role == 'student' 
                              ? const Color(0xFF6C63FF) 
                              : const Color(0xFFFF6B9D),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1A1A2E)
                            : Colors.grey.shade50,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 28),

                    // User Info
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(height: 20),
                            _infoRow(Icons.person, 'Name', widget.name),
                            _infoRow(Icons.email, 'Email', widget.email),
                            _infoRow(Icons.work, 'Role', widget.role.toUpperCase()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitVerification,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: widget.role == 'student' 
                            ? const Color(0xFF6C63FF) 
                            : const Color(0xFFFF6B9D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Create My E-ID', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 20),

                    // Demo IDs
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 Demo IDs for testing:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            widget.role == 'student'
                                ? 'IITD2023001, IITB2023001, NITT2023001'
                                : 'IITDALUM001, IITBALUM001, NITTALUM001',
                            style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildExistingEIDView() {
    final eid = _existingVerification!['eid'] as String?;
    final qrBase64 = _existingVerification!['qr_base64'] as String?;
    // Check both verification_request status AND user profile verificationStatus
    var status = _existingVerification!['status'] as String? ?? 'pending';
    // If user profile says verified, use that (it's the source of truth)
    if (_userProfile?.isVerified == true) {
      status = 'verified';
    } else if (_userProfile?.isRejected == true) {
      status = 'rejected';
    }
    final autoMatched = _existingVerification!['autoMatched'] as bool? ?? false;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // E-ID Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.role == 'student'
                    ? [const Color(0xFF6C63FF), const Color(0xFF4E9FFF)]
                    : [const Color(0xFFFF6B9D), const Color(0xFFFFA726)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (widget.role == 'student' 
                      ? const Color(0xFF6C63FF) 
                      : const Color(0xFFFF6B9D)).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.badge, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Your E-ID',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (eid != null)
                  Text(
                    eid,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // QR Code
          if (qrBase64 != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Verification QR Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Image.memory(
                    base64Decode(qrBase64),
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Show this QR code to admin for verification',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: status == 'verified' 
                  ? Colors.green.shade50 
                  : status == 'rejected'
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: status == 'verified' 
                    ? Colors.green.shade200 
                    : status == 'rejected'
                        ? Colors.red.shade200
                        : Colors.orange.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'verified' 
                      ? Icons.verified 
                      : status == 'rejected'
                          ? Icons.cancel
                          : Icons.pending,
                  color: status == 'verified' 
                      ? Colors.green.shade700 
                      : status == 'rejected'
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    status == 'verified' 
                        ? '✅ Verified' 
                        : status == 'rejected'
                            ? '❌ Rejected'
                            : autoMatched 
                                ? '✅ ID Matched - Awaiting Admin Approval'
                                : '⏳ Awaiting Review',
                    style: TextStyle(
                      color: status == 'verified' 
                          ? Colors.green.shade800 
                          : status == 'rejected'
                              ? Colors.red.shade800
                              : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }
}