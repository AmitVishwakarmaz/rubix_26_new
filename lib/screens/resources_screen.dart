import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firestore_service.dart';
import '../models/resource_model.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  String _selectedCategory = ResourceCategory.all;
  String _searchQuery = '';

  String? _userRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      
      if (uid == null) {
        print('⚠️ No user logged in');
        if (mounted) {
          setState(() => _isLoadingRole = false);
        }
        return;
      }

      print('🔍 Loading role for user: $uid');
      final role = await _firestoreService.getUserRole(uid);
      print('✅ User role loaded: $role');
      
      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user role: $e');
      if (mounted) {
        setState(() => _isLoadingRole = false);
      }
    }
  }

  bool get _canUpload =>
      _userRole == 'alumni' ||
      _userRole == 'mentor' ||
      _userRole == 'admin';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Resource> _filterResources(List<Resource> resources) {
    var filtered = resources;

    if (_selectedCategory != ResourceCategory.all) {
      filtered =
          filtered.where((r) => r.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.uploadedByName.toLowerCase().contains(q);
      }).toList();
    }

    return filtered;
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (e) {
      print('❌ Error opening link: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening link: $e')),
      );
    }
  }

  /// ===================== UPLOAD BOTTOM SHEET =====================
  void _showUploadBottomSheet() {
    String title = '';
    String description = '';
    String selectedCategory = '';
    String driveLink = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Upload New Resource',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => title = v.trim(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (v) => description = v.trim(),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedCategory.isEmpty ? null : selectedCategory,
                    hint: const Text('Select category'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ResourceCategory.uploadCategories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Google Drive Link',
                      hintText: 'https://drive.google.com/...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => driveLink = v.trim(),
                  ),
                  const SizedBox(height: 28),

                  FilledButton.icon(
                    onPressed: (title.isEmpty ||
                            selectedCategory.isEmpty ||
                            driveLink.isEmpty)
                        ? null
                        : () async {
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Uploading...')),
                            );

                            try {
                              await _firestoreService.uploadResource(
                                title: title,
                                description: description,
                                category: selectedCategory,
                                driveLink: driveLink,
                              );

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Resource uploaded successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Upload failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Upload'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingRole) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading user profile...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: _canUpload
          ? FloatingActionButton.extended(
              onPressed: _showUploadBottomSheet,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload Resource'),
              backgroundColor: const Color(0xFF6C63FF),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryFilter(isDark),
            Expanded(child: _buildResourcesList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: 'Search resources...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ResourceCategory.categories.length,
        itemBuilder: (context, index) {
          final cat = ResourceCategory.categories[index];
          final selected = _selectedCategory == cat;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF6C63FF)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourcesList(bool isDark) {
    return StreamBuilder<List<Resource>>(
      stream: _firestoreService.streamResources(),
      builder: (context, snapshot) {
        print('📊 StreamBuilder state: ${snapshot.connectionState}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading resources...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ Stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('⚠️ No data in snapshot');
          return const Center(
            child: Text('No data available'),
          );
        }

        print('✅ Resources loaded: ${snapshot.data!.length} items');
        final filtered = _filterResources(snapshot.data!);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty || _selectedCategory != ResourceCategory.all
                      ? 'No resources match your filters'
                      : 'No resources available yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_canUpload) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showUploadBottomSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Upload First Resource'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final r = filtered[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6C63FF),
                  child: Text(
                    r.title[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  r.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(r.description),
                    const SizedBox(height: 4),
                    Text(
                      'By ${r.uploadedByName} • ${r.category}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _openLink(r.pdfUrl),
                  tooltip: 'Open resource',
                ),
              ),
            );
          },
        );
      },
    );
  }
}