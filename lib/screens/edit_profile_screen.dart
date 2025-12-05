import 'package:comp4768_mun_thrift/controllers/user_info_controller.dart';
import 'package:comp4768_mun_thrift/services/auth_service.dart';
import 'package:comp4768_mun_thrift/services/firestore_service.dart';
import 'package:comp4768_mun_thrift/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  Uint8List? _imageBytes;
  String? networkImageUrl;
  final picker = ImagePicker();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _aboutController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          networkImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;

    // Shouldn't be able to get here either way but just in case
    if (user == null) {
      context.go('/login');
      return Container();
    }

    final userInfoController = ref.watch(userInfoControllerProvider(user.uid));

    if (!_initialized &&
        userInfoController.hasValue &&
        userInfoController.value != null) {
      final userInfo = userInfoController.value!;
      _nameController.text = userInfo.name;
      _addressController.text = userInfo.address;
      _aboutController.text = userInfo.about ?? '';
      if (userInfo.profileImageUrl.isNotEmpty) {
        networkImageUrl = userInfo.profileImageUrl;
        _imageBytes = null;
      }
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _imageBytes != null
                        ? MemoryImage(_imageBytes!)
                        : (networkImageUrl != null
                              ? NetworkImage(networkImageUrl!)
                              : null),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _pickImage,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aboutController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'About',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    // Validate image selection
                    if (_imageBytes == null && networkImageUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a profile image.'),
                        ),
                      );
                      return;
                    }

                    try {
                      // Show loading indicator
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saving profile...')),
                      );

                      // Upload image only if a new image is picked
                      String imageUrl = networkImageUrl ?? '';
                      if (_imageBytes != null) {
                        final imageUploader = ref.read(storageServiceProvider);
                        imageUrl = await imageUploader.uploadImageBytes(
                          _imageBytes!,
                          'user-images/${user.uid}',
                        );
                      }

                      final userInfo = {
                        'name': _nameController.text.trim(),
                        'address': _addressController.text.trim(),
                        'about': _aboutController.text.trim(),
                        'profileImageUrl': imageUrl,
                      };

                      // Check if user profile exists by reading current value
                      final hasValue = userInfoController.hasValue;
                      final currentUserInfo = hasValue
                          ? userInfoController.value
                          : null;

                      // Save or update directly to Firestore
                      final firestoreService = ref.read(
                        firestoreServiceProvider,
                      );
                      if (currentUserInfo == null) {
                        await firestoreService.saveUserInfo(user.uid, userInfo);
                      } else {
                        await firestoreService.updateUserInfo(
                          user.uid,
                          userInfo,
                        );
                      }

                      // Invalidate the controller to refresh data
                      if (!mounted) return;
                      ref.invalidate(userInfoControllerProvider(user.uid));

                      if (!mounted) return;
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile saved successfully!'),
                          ),
                        );
                      }

                      // Navigate after a brief delay
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      if (mounted) context.go('/free');
                    } catch (e) {
                      if (!mounted) return;
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving profile: $e')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
