import 'package:cloud_firestore/cloud_firestore.dart';

class Resource {
  final String id;
  final String title;
  final String description;
  final String pdfUrl;
  final String category;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime uploadDate;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.pdfUrl,
    required this.category,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadDate,
  });

  factory Resource.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle uploadDate - can be Timestamp, String, or null
    DateTime uploadDate = DateTime.now();
    try {
      final dateData = data['uploadDate'];
      if (dateData is Timestamp) {
        uploadDate = dateData.toDate();
      } else if (dateData is String) {
        uploadDate = DateTime.parse(dateData);
      } else if (dateData == null) {
        uploadDate = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Error parsing uploadDate for ${doc.id}: $e');
      uploadDate = DateTime.now();
    }
    
    return Resource(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pdfUrl: data['pdfUrl'] ?? data['driveLink'] ?? '',
      category: data['category'] ?? ResourceCategory.other,
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedByName: data['uploadedByName'] ?? 'Unknown',
      uploadDate: uploadDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'pdfUrl': pdfUrl,
      'category': category,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'uploadDate': Timestamp.fromDate(uploadDate),
    };
  }

  // Alias for backward compatibility
  Map<String, dynamic> toMap() => toFirestore();
}

class ResourceCategory {
  // Filter categories (includes "All")
  static const String all = 'All';
  static const String technology = 'Technology';
  static const String science = 'Science';
  static const String mathematics = 'Mathematics';
  static const String business = 'Business';
  static const String arts = 'Arts';
  static const String engineering = 'Engineering';
  static const String other = 'Other';

  // All categories for filtering (includes "All")
  static const List<String> categories = [
    all,
    technology,
    science,
    mathematics,
    business,
    arts,
    engineering,
    other,
  ];

  // Upload categories (excludes "All")
  static const List<String> uploadCategories = [
    technology,
    science,
    mathematics,
    business,
    arts,
    engineering,
    other,
  ];
}