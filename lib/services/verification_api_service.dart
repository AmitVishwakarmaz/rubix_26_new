import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for E-ID Verification API (JWT-based)
class VerificationApiService {
  // Use your computer's IP for physical device
  // For Android emulator use: 'http://10.0.2.2:5000/api'
  // For iOS simulator/web use: 'http://localhost:5000/api'
  static const String baseUrl = 'http://192.168.0.107:5000/api';

  /// Get universities list
  static Future<List<Map<String, dynamic>>> getUniversities() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/universities'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['universities'] ?? []);
      }
    } catch (e) {
      print('Error getting universities: $e');
    }
    return [];
  }

  /// Register for E-ID (creates JWT + QR)
  static Future<Map<String, dynamic>> registerForEid({
    required String userId,
    required String name,
    required String email,
    required String universityId,
    required String role,
    required String enteredId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'name': name,
          'email': email,
          'universityId': universityId,
          'role': role,
          'enteredId': enteredId,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user's E-ID with QR code
  static Future<Map<String, dynamic>> getMyEid(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/my-eid/$userId'));
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Admin: Get pending requests
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pending'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['requests'] ?? []);
      }
    } catch (e) {
      print('Error getting pending: $e');
    }
    return [];
  }

  /// Admin: Verify JWT token from QR
  static Future<Map<String, dynamic>> verifyJwt(String jwtToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-qr'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'jwt_token': jwtToken}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Admin: Verify QR image (base64)
  static Future<Map<String, dynamic>> verifyQrImage(String qrBase64) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-qr'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'qr_base64': qrBase64}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Admin: Approve E-ID
  static Future<Map<String, dynamic>> approveEid(String eid) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/approve/$eid'));
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Admin: Reject E-ID
  static Future<Map<String, dynamic>> rejectEid(String eid, {String reason = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reject/$eid'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reason': reason}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get E-ID status
  static Future<Map<String, dynamic>> getEidStatus(String eid) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status/$eid'));
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
