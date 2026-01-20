import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/new_models.dart';
import 'package:uuid/uuid.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({Key? key}) : super(key: key);

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController(); // Comma separated
  final _locationController = TextEditingController();
  final _typeController = TextEditingController(text: 'Full-time');
  final _urlController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    // Fetch user details to get name or just use fallback
    String posterName = "Alumni";
    final userDoc = await _firestoreService.getUser(user.uid);
    if(userDoc != null) posterName = userDoc.name;

    final job = JobPost(
      id: Uuid().v4(),
      title: _titleController.text,
      company: _companyController.text,
      description: _descriptionController.text,
      requirements: _requirementsController.text.split(',').map((e) => e.trim()).toList(),
      postedByUserId: user.uid,
      postedByName: posterName,
      location: _locationController.text,
      type: _typeController.text,
      postedDate: DateTime.now(),
      applicationUrl: _urlController.text.isEmpty ? null : _urlController.text,
    );
    
    try {
      await _firestoreService.createJobPost(job);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Posted Successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post a Job"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
                  : [const Color(0xFFF8F9FE), const Color(0xFFFFFFFF)],
            ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField("Job Title", _titleController, isDark),
                const SizedBox(height: 16),
                _buildTextField("Company", _companyController, isDark),
                const SizedBox(height: 16),
                _buildTextField("Location", _locationController, isDark),
                const SizedBox(height: 16),
                _buildDropdown("Type", _typeController, isDark),
                const SizedBox(height: 16),
                _buildTextField("Description", _descriptionController, isDark, maxLines: 4),
                 const SizedBox(height: 16),
                _buildTextField("Requirements (comma separated)", _requirementsController, isDark),
                 const SizedBox(height: 16),
                _buildTextField("Application URL (Optional)", _urlController, isDark),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Post Job", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (val) => (val == null || val.isEmpty) && !label.contains("Optional") ? "Required" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDropdown(String label, TextEditingController controller, bool isDark) {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? 'Full-time' : controller.text,
          onChanged: (val) => setState(() => controller.text = val!),
          items: ['Full-time', 'Part-time', 'Internship', 'Contract', 'Remote'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
           decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
          ),
        ),
      ],
     );
  }
}
