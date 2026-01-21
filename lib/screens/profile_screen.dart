import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/connection_service.dart';
import '../models/user_model.dart';
import '../models/connection_model.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final ConnectionService _connectionService = ConnectionService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen(role: 'student')), // Passing default role as it's unused but required
        (route) => false,
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);

      final user = _authService.currentUser;
      if (user == null) return;

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${user.uid}.jpg');

      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      // Update Firestore
      await _firestoreService.updateUserProfile(user.uid, {'profileImageUrl': url});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showEditProfileDialog(AppUser user) async {
    final nameController = TextEditingController(text: user.name);
    final roleController = TextEditingController(text: user.jobRole ?? ''); // Or degree for student
    final companyController = TextEditingController(text: user.currentCompany ?? user.university ?? '');
    final bioController = TextEditingController(text: user.role == 'student' ? user.major : user.industry); // Reusing fields as "Bio" is not in model yet, using existing fields for now or adding bio. 
    // Actually simpler to just edit existing fields.
    final linkedinController = TextEditingController(text: user.linkedinUrl ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              if (user.isAlumni) ...[
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Job Role'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Current Company'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Industry'),
                ),
              ] else ...[
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'University'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Degree'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Major'),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: linkedinController,
                decoration: const InputDecoration(labelText: 'LinkedIn URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final updates = {
                'name': nameController.text.trim(),
                'linkedinUrl': linkedinController.text.trim(),
              };
              
              if (user.isAlumni) {
                updates['jobRole'] = roleController.text.trim();
                updates['currentCompany'] = companyController.text.trim();
                updates['industry'] = bioController.text.trim();
              } else {
                updates['degree'] = roleController.text.trim();
                updates['university'] = companyController.text.trim();
                updates['major'] = bioController.text.trim();
              }
              
              await _firestoreService.updateUserProfile(user.userId, updates);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showEditTagsDialog(
    AppUser user, 
    String title, 
    List<String> currentTags, 
    List<String> suggestions,
    String fieldName
  ) async {
    final List<String> selectedTags = List.from(currentTags);
    final textController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit $title'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedTags.map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => setState(() => selectedTags.remove(tag)),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                      labelStyle: const TextStyle(color: Color(0xFF6C63FF)),
                    )).toList(),
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     controller: textController,
                     decoration: InputDecoration(
                       labelText: 'Add Custom $title',
                       suffixIcon: IconButton(
                         icon: const Icon(Icons.add),
                         onPressed: () {
                           if (textController.text.isNotEmpty) {
                             setState(() {
                               if (!selectedTags.contains(textController.text.trim())) {
                                 selectedTags.add(textController.text.trim());
                               }
                               textController.clear();
                             });
                           }
                         },
                       ),
                       border: const OutlineInputBorder(),
                     ),
                     onSubmitted: (value) {
                       if (value.isNotEmpty) {
                         setState(() {
                           if (!selectedTags.contains(value.trim())) {
                             selectedTags.add(value.trim());
                           }
                           textController.clear();
                         });
                       }
                     },
                   ),
                   const SizedBox(height: 16),
                   const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                   const SizedBox(height: 8),
                   Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions
                      .where((s) => !selectedTags.contains(s))
                      .map((s) => ActionChip(
                        label: Text(s),
                        onPressed: () => setState(() => selectedTags.add(s)),
                      )).toList(),
                   ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                   Navigator.pop(context);
                   await _firestoreService.updateUserProfile(user.userId, {fieldName: selectedTags});
                }, 
                child: const Text('Save')
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<AppUser?>(
      stream: _firestoreService.streamUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        }
        
        final appUser = snapshot.data;
        if (appUser == null) {
             return const Scaffold(body: Center(child: Text("User profile not found.")));
        }

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
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {}); 
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          _buildProfileCard(appUser, isDark),
                          const SizedBox(height: 24),
                          _buildLevelProgress(appUser, isDark),
                          const SizedBox(height: 24),
                          _buildStatsGrid(appUser, isDark),
                          const SizedBox(height: 24),
                          _buildSectionWithChips(
                            context: context,
                            title: 'Skills', 
                            tags: appUser.skills ?? [], 
                            isDark: isDark,
                            onEdit: () => _showEditTagsDialog(
                              appUser, 
                              'Skills', 
                              appUser.skills ?? [], 
                              ['Flutter', 'React', 'Python', 'Java', 'UI/UX', 'Product Management'], // Common suggestions
                              'skills'
                            )
                          ),
                          const SizedBox(height: 24),
                          if (appUser.isStudent) ...[
                            _buildSectionWithChips(
                              context: context,
                              title: 'Interests', 
                              tags: appUser.careerInterests ?? [], 
                              isDark: isDark,
                              accentColor: const Color(0xFFFF6B9D),
                              onEdit: () => _showEditTagsDialog(
                                appUser, 
                                'Interests', 
                                appUser.careerInterests ?? [], 
                                ['Software Development', 'Data Science', 'AI', 'Startup', 'Finance'], // Common suggestions
                                'careerInterests'
                              )
                            ),
                            const SizedBox(height: 24),
                          ],
                           Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _handleLogout,
                                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                label: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            // IconButton(
            //   onPressed: () {
            //     // Navigate to settings if implemented
            //   },
            //   icon: Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(
            //       color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            //       borderRadius: BorderRadius.circular(12),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black.withOpacity(0.05),
            //           blurRadius: 10,
            //           offset: const Offset(0, 5),
            //         ),
            //       ],
            //     ),
            //     child: const Icon(Icons.settings_rounded),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppUser user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF6C63FF + (user.name.hashCode % 1000)),
                          Color(0xFF4E9FFF + (user.name.hashCode % 1000)),
                        ],
                      ),
                      image: user.profileImageUrl != null
                        ? DecorationImage(image: NetworkImage(user.profileImageUrl!), fit: BoxFit.cover)
                        : null,
                    ),
                    child: user.profileImageUrl == null
                        ? Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: _isUploading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              user.isAlumni 
                  ? '${user.jobRole ?? 'Alumni'} at ${user.currentCompany ?? 'Unknown Company'}'
                  : '${user.major ?? 'Student'} at ${user.university ?? 'Unknown University'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () => _showEditProfileDialog(user),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgress(AppUser user, bool isDark) {
    // XP Logic: 100 XP per level
    final currentLevel = (user.xp / 100).floor() + 1;
    final progress = (user.xp % 100) / 100.0;
    final rank = user.rank;
    final rankColor = Color(user.rankColor);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
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
                      'Level $currentLevel',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.xp} XP',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rank, 
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                color: rankColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${100 - (user.xp % 100)} XP to reach Level ${currentLevel + 1}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AppUser user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Connections count - live from streams
          Expanded(
            child: StreamBuilder<List<ConnectionRequest>>(
              stream: user.isAlumni 
                  ? _connectionService.streamAlumniConnections(user.userId)
                  : _connectionService.streamStudentConnections(user.userId),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return _buildStatCard(
                  isDark,
                  icon: Icons.people_rounded,
                  label: 'Connections',
                  value: '$count',
                  color: const Color(0xFF6C63FF),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          // Communities joined - from Firestore communities collection
          Expanded(
            child: StreamBuilder<int>(
              stream: _firestoreService.streamUserCommunityCount(user.userId),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return _buildStatCard(
                  isDark,
                  icon: Icons.groups_rounded,
                  label: 'Communities',
                  value: '$count',
                  color: Colors.amber,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithChips({
    required BuildContext context,
    required String title,
    required List<String> tags,
    required bool isDark,
    required VoidCallback onEdit,
    Color accentColor = const Color(0xFF6C63FF),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: accentColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tags.isEmpty)
             Text(
               "No $title added yet.",
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
             )
          else
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.start,
                alignment: WrapAlignment.start,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      borderRadius: BorderRadius.circular(24), // Curved chips
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}