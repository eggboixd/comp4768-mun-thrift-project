import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
	const EditProfileScreen({Key? key}) : super(key: key);

	@override
	State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
	File? _image;
	final picker = ImagePicker();
	final _nameController = TextEditingController();
	final _addressController = TextEditingController();
	final _aboutController = TextEditingController();

	final _formKey = GlobalKey<FormState>();

	Future<void> _pickImage() async {
		final pickedFile = await picker.pickImage(source: ImageSource.gallery);
		if (pickedFile != null) {
			setState(() {
				_image = File(pickedFile.path);
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Edit Profile'),
				centerTitle: true,
			),
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
												: const NetworkImage('https://placehold.co/600x400.png') as ImageProvider,
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
								onPressed: () {
									if (_formKey.currentState?.validate() ?? false) {
										// TODO: Save logic here
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
