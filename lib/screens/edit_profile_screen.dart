import 'package:comp4768_mun_thrift/controllers/user_info_controller.dart';
import 'package:comp4768_mun_thrift/services/auth_service.dart';
import 'package:comp4768_mun_thrift/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  File? _image;
  String? networkImageUrl;
  final picker = ImagePicker();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _aboutController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        networkImageUrl = null;
      });
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

    final userInfoSetController = ref.read(
      userInfoControllerProvider(user.uid).notifier,
    );

    final userInfoController = ref.read(userInfoControllerProvider(user.uid));

    if (!_initialized && userInfoController.value != null) {
      final userInfo = userInfoController.value!;
      _nameController.text = userInfo.name;
      _addressController.text = userInfo.address;
      _aboutController.text = userInfo.about ?? '';
      if (userInfo.profileImageUrl.isNotEmpty) {
        networkImageUrl = userInfo.profileImageUrl;
        _image = null;
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
                    backgroundImage: _image != null
                        ? FileImage(_image!)
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
                    if (_image == null && networkImageUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a profile image.'),
                        ),
                      );
                      return;
                    }

                    // Upload image only if a new image is picked
                    String imageUrl = networkImageUrl ?? '';
                    if (_image != null) {
                      final imageUploader = ref.watch(storageServiceProvider);
                      imageUrl = await imageUploader.uploadImage(
                        _image!,
                        'user-images/${user.uid}',
                      );
                    }

                    final userInfo = {
                      'name': _nameController.text.trim(),
                      'address': _addressController.text.trim(),
                      'about': _aboutController.text.trim(),
                      'profileImageUrl': imageUrl,
                    };

                    // Check whether to update or save new
                    await userInfoSetController.loadUserInfo(user.uid);
                    if (userInfoController.value == null) {
                      await userInfoSetController.saveUserInfo(
                        user.uid,
                        userInfo,
                      );
                    } else {
                      await userInfoSetController.updateUserInfo(
                        user.uid,
                        userInfo,
                      );
                    }

                    context.go('/profile');
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
