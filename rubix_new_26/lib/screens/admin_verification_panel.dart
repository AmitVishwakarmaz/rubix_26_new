import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/verification_api_service.dart';

/// Admin panel for verifying E-IDs by scanning QR codes
class AdminVerificationPanel extends StatefulWidget {
  const AdminVerificationPanel({super.key});

  @override
  State<AdminVerificationPanel> createState() => _AdminVerificationPanelState();
}

class _AdminVerificationPanelState extends State<AdminVerificationPanel> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _verifyAndShowDialog(Map<String, dynamic> data) async {
    final jwtToken = data['jwtToken'] ?? '';
    final qrBase64 = data['qr_base64'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => _VerifyDialog(
        data: data,
        jwtToken: jwtToken,
        qrBase64: qrBase64,
        onApprove: () => _approve(data),
        onReject: () => _reject(data),
      ),
    );
  }

  Future<void> _approve(Map<String, dynamic> data) async {
    try {
      final eid = data['eid'];
      final userId = data['userId'];

      // Update verification request status
      await _firestore.collection('verification_requests').doc(eid).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Update user's verification status
      await _firestore.collection('users').doc(userId).update({
        'verificationStatus': 'verified',
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${data['name']} approved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> data) async {
    try {
      final eid = data['eid'];
      final userId = data['userId'];

      await _firestore.collection('verification_requests').doc(eid).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(userId).update({
        'verificationStatus': 'rejected',
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${data['name']} rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-ID Verification'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('verification_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No Pending Requests',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All verification requests processed',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildRequestCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data) {
    final isStudent = data['role'] == 'student';
    final isMatched = data['autoMatched'] == true;
    final qrBase64 = data['qr_base64'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isStudent ? Colors.blue.shade100 : Colors.purple.shade100,
                  child: Text(
                    (data['name'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: isStudent ? Colors.blue : Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        data['eid'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Info
            _infoRow(Icons.badge, 'ID', data['enteredId'] ?? ''),
            _infoRow(Icons.email, 'Email', data['email'] ?? ''),
            _infoRow(Icons.work, 'Role', (data['role'] ?? '').toString().toUpperCase()),

            const SizedBox(height: 12),

            // Match Status
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMatched ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isMatched ? Icons.check_circle : Icons.warning,
                    color: isMatched ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMatched ? '✅ ID Matched in Records' : '⚠️ ID Not Found',
                    style: TextStyle(
                      color: isMatched ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // QR Code Preview
            if (qrBase64.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.memory(
                    base64Decode(qrBase64),
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Verify & Approve Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _verifyAndShowDialog(data),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Verify QR & Approve/Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

/// Dialog for verifying QR and approving/rejecting
class _VerifyDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final String jwtToken;
  final String qrBase64;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerifyDialog({
    required this.data,
    required this.jwtToken,
    required this.qrBase64,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_VerifyDialog> createState() => _VerifyDialogState();
}

class _VerifyDialogState extends State<_VerifyDialog> {
  bool _isVerifying = false;
  bool _isVerified = false;
  String? _verifyMessage;
  Map<String, dynamic>? _verifiedData;

  Future<void> _verifyQr() async {
    if (widget.jwtToken.isEmpty) {
      setState(() {
        _verifyMessage = '❌ No JWT token found';
        _isVerified = false;
      });
      return;
    }

    setState(() => _isVerifying = true);

    final result = await VerificationApiService.verifyJwt(widget.jwtToken);

    setState(() {
      _isVerifying = false;
      if (result['success'] == true && result['verified'] == true) {
        _isVerified = true;
        _verifyMessage = result['message'];
        _verifiedData = result['data'];
      } else {
        _isVerified = false;
        _verifyMessage = result['message'] ?? 'Verification failed';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'Verify E-ID',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // QR Code
            if (widget.qrBase64.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.memory(
                  base64Decode(widget.qrBase64),
                  width: 180,
                  height: 180,
                ),
              ),
            const SizedBox(height: 16),

            // User Info
            Text(widget.data['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.data['eid'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
            Text('ID: ${widget.data['enteredId']}'),

            const SizedBox(height: 20),

            // Verify Button
            if (!_isVerified)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _verifyQr,
                  icon: _isVerifying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.verified_user),
                  label: Text(_isVerifying ? 'Verifying...' : 'Verify QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

            // Verification Result
            if (_verifyMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isVerified ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isVerified ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isVerified ? Icons.verified : Icons.error,
                      color: _isVerified ? Colors.green : Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isVerified ? 'VERIFIED' : 'FAILED',
                      style: TextStyle(
                        color: _isVerified ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      _verifyMessage!,
                      style: TextStyle(color: _isVerified ? Colors.green.shade800 : Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Approve/Reject Buttons (only show after verification)
            if (_isVerified) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Close Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
