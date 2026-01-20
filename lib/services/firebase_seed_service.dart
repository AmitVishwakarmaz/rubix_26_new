import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to seed Firebase with demo university data
class FirebaseSeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Demo universities data
  final Map<String, Map<String, dynamic>> _universities = {
    'uni_001': {
      'name': 'IIT Delhi',
      'student_ids': {
        'IITD2023001': {
          'studentId': 'IITD2023001',
          'name': 'Amit Vishwakarma',
          'department': 'Computer Science',
          'year': '3rd Year',
        },
        'IITD2023002': {
          'studentId': 'IITD2023002',
          'name': 'Priya Sharma',
          'department': 'Electronics',
          'year': '2nd Year',
        },
        'IITD2022003': {
          'studentId': 'IITD2022003',
          'name': 'Rahul Verma',
          'department': 'Mechanical',
          'year': '4th Year',
        },
      },
      'alumni_ids': {
        'IITDALUM001': {
          'alumniId': 'IITDALUM001',
          'name': 'Krishna Kumar',
          'graduationYear': 2022,
          'department': 'Computer Science',
        },
        'IITDALUM002': {
          'alumniId': 'IITDALUM002',
          'name': 'Neha Gupta',
          'graduationYear': 2021,
          'department': 'Information Technology',
        },
      },
    },
    'uni_002': {
      'name': 'IIT Bombay',
      'student_ids': {
        'IITB2023001': {
          'studentId': 'IITB2023001',
          'name': 'Vikram Patel',
          'department': 'Computer Science',
          'year': '3rd Year',
        },
        'IITB2023002': {
          'studentId': 'IITB2023002',
          'name': 'Sneha Reddy',
          'department': 'Civil Engineering',
          'year': '2nd Year',
        },
      },
      'alumni_ids': {
        'IITBALUM001': {
          'alumniId': 'IITBALUM001',
          'name': 'Anjali Menon',
          'graduationYear': 2020,
          'department': 'Electrical Engineering',
        },
      },
    },
    'uni_003': {
      'name': 'NIT Trichy',
      'student_ids': {
        'NITT2023001': {
          'studentId': 'NITT2023001',
          'name': 'Karthik Rajan',
          'department': 'Electronics',
          'year': '3rd Year',
        },
      },
      'alumni_ids': {
        'NITTALUM001': {
          'alumniId': 'NITTALUM001',
          'name': 'Divya Krishnan',
          'graduationYear': 2019,
          'department': 'Computer Science',
        },
      },
    },
  };

  /// Check if universities collection exists
  Future<bool> universitiesExist() async {
    final snapshot = await _firestore.collection('universities').limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Seed all demo data to Firebase
  Future<void> seedDemoData() async {
    try {
      // Check if data already exists
      if (await universitiesExist()) {
        print('[Seed] Universities already exist, skipping seed');
        return;
      }

      await _createUniversityData();
    } catch (e) {
      print('[Seed] Error seeding data: $e');
    }
  }

  /// Force re-seed: Delete all existing university data and create fresh
  Future<void> forceSeedDemoData() async {
    try {
      print('[Seed] Force re-seeding: Deleting existing data...');

      // Delete all existing universities
      final existingUnis = await _firestore.collection('universities').get();
      for (final uniDoc in existingUnis.docs) {
        // Delete student_ids subcollection
        final studentIds = await uniDoc.reference.collection('student_ids').get();
        for (final doc in studentIds.docs) {
          await doc.reference.delete();
        }

        // Delete alumni_ids subcollection
        final alumniIds = await uniDoc.reference.collection('alumni_ids').get();
        for (final doc in alumniIds.docs) {
          await doc.reference.delete();
        }

        // Delete the university document itself
        await uniDoc.reference.delete();
        print('[Seed] Deleted university: ${uniDoc.id}');
      }

      print('[Seed] All existing universities deleted. Creating fresh data...');
      await _createUniversityData();
    } catch (e) {
      print('[Seed] Error force seeding data: $e');
    }
  }

  /// Internal method to create university data
  Future<void> _createUniversityData() async {
    print('[Seed] Seeding demo data...');

    for (final entry in _universities.entries) {
      final uniId = entry.key;
      final uniData = entry.value;

      // Create university document
      await _firestore.collection('universities').doc(uniId).set({
        'name': uniData['name'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add student_ids subcollection
      final studentIds = uniData['student_ids'] as Map<String, dynamic>;
      for (final studentEntry in studentIds.entries) {
        await _firestore
            .collection('universities')
            .doc(uniId)
            .collection('student_ids')
            .doc(studentEntry.key)
            .set(studentEntry.value);
      }

      // Add alumni_ids subcollection
      final alumniIds = uniData['alumni_ids'] as Map<String, dynamic>;
      for (final alumniEntry in alumniIds.entries) {
        await _firestore
            .collection('universities')
            .doc(uniId)
            .collection('alumni_ids')
            .doc(alumniEntry.key)
            .set(alumniEntry.value);
      }

      print('[Seed] Created university: ${uniData['name']}');
    }

    print('[Seed] Demo data seeded successfully!');
  }

  /// Get all universities
  Future<List<Map<String, dynamic>>> getUniversities() async {
    try {
      final snapshot = await _firestore.collection('universities').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] ?? '',
      }).toList();
    } catch (e) {
      print('[Firestore] Error getting universities: $e');
      return [];
    }
  }

  /// Check if student ID exists
  Future<Map<String, dynamic>?> checkStudentId(String universityId, String studentId) async {
    try {
      final doc = await _firestore
          .collection('universities')
          .doc(universityId)
          .collection('student_ids')
          .doc(studentId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('[Firestore] Error checking student ID: $e');
      return null;
    }
  }

  /// Check if alumni ID exists
  Future<Map<String, dynamic>?> checkAlumniId(String universityId, String alumniId) async {
    try {
      final doc = await _firestore
          .collection('universities')
          .doc(universityId)
          .collection('alumni_ids')
          .doc(alumniId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('[Firestore] Error checking alumni ID: $e');
      return null;
    }
  }
}
