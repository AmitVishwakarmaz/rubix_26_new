import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_seed_service.dart';
import '../services/verification_api_service.dart';
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
  
  List<Map<String, dynamic>> _universities = [];
  String? _selectedUniversityId;
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
  }

  Future<void> _loadUniversities() async {
    final universities = await _seedService.getUniversities();
    setState(() {
      _universities = universities;
      _isLoading = false;
    });
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
      builder: (context) => AlertDialog(
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
                    colors: [Colors.indigo.shade600, Colors.purple.shade600],
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
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('View My E-ID'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role == 'student' ? 'Student' : 'Alumni'} Verification'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                          colors: [Colors.indigo.shade600, Colors.purple.shade600],
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
                        prefixIcon: const Icon(Icons.school),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      value: _selectedUniversityId,
                      hint: const Text('Choose your university'),
                      isExpanded: true,
                      items: _universities.map((uni) {
                        return DropdownMenuItem<String>(
                          value: uni['id'] as String,
                          child: Text(uni['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedUniversityId = value),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // ID Input
                    TextFormField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: widget.role == 'student' ? 'Student ID' : 'Alumni ID',
                        hintText: widget.role == 'student' ? 'e.g., IITD2023001' : 'e.g., IITDALUM001',
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                        backgroundColor: Colors.indigo.shade600,
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

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }
}
