import 'dart:typed_data';
import 'package:comp4768_mun_thrift/controllers/item_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key, this.editItemId});

  final String? editItemId;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _ListingImage {
  final Uint8List bytes;
  final String? url;
  final bool isNew;

  _ListingImage({required this.bytes, this.url, this.isNew = false});
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  ItemType _selectedType = ItemType.free;
  ItemCondition _selectedCondition = ItemCondition.good;
  String? _selectedCategory;

  // Predefined categories
  static const List<String> _categories = [
    'Clothing',
    'Electronics',
    'Books',
    'Furniture',
    'Sports & Outdoors',
    'Home & Garden',
    'Toys & Games',
    'Other',
  ];
  // Track current images shown in the UI. For existing images we store the
  // original URL and downloaded bytes; for new images, url is null and
  // isNew=true.
  final List<_ListingImage> _images = [];
  Item? _originalItem;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    if (widget.editItemId != null) {
      _loadExistingItem();
    }
  }

  Future<void> _checkAuthentication() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to create a listing')),
        );
        context.go('/auth');
      }
    }
  }

  Future<void> _loadExistingItem() async {
    final item = await ref
        .read(firestoreServiceProvider)
        .getItemById(widget.editItemId!);
    if (item != null) {
      setState(() {
        _originalItem = item;
        _titleController.text = item.title;
        _descriptionController.text = item.description;
        _selectedType = item.type;
        if (item.price != null) {
          _priceController.text = item.price.toString();
        }
        _selectedCondition = item.condition;
        _selectedCategory = item.category;
        _quantityController.text = item.quantity.toString();
      });

      // Load images and preserve their original URLs
      for (int i = 0; i < item.imageUrls.length; i++) {
        final imageUrl = item.imageUrls[i];
        final bytes = await ref
            .read(storageServiceProvider)
            .downloadImage(imageUrl);
        if (bytes != null && mounted) {
          setState(() {
            final insertIndex = i <= _images.length ? i : _images.length;
            _images.insert(
              insertIndex,
              _ListingImage(bytes: bytes, url: imageUrl, isNew: false),
            );
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 images allowed'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Show bottom sheet for source selection
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
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _images.add(_ListingImage(bytes: bytes, url: null, isNew: true));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image added (${_images.length}/5)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
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

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated. Please sign in again.');
      }

      // Ensure auth token is fresh before uploading to Storage
      await user.getIdToken(true);

      // Storage + Firestore services
      final storageService = ref.read(storageServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      // For creating a new item, use a temp ID for storage paths
      final tempItemId =
          widget.editItemId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Build lists of existing images kept (original URLs) and new images
      final List<String> keptOriginalUrls = _images
          .where((img) => img.url != null && !img.isNew)
          .map((img) => img.url!)
          .toList();

      final List<_ListingImage> newImages = _images
          .where((img) => img.isNew)
          .toList();

      final List<String> newUploadedUrls = [];
      for (int i = 0; i < newImages.length; i++) {
        final path = storageService.generateItemImagePath(
          user.uid,
          tempItemId,
          i,
        );
        final url = await storageService.uploadImageBytes(
          newImages[i].bytes,
          path,
        );
        newUploadedUrls.add(url);
      }

      final List<String> imageUrls = [...keptOriginalUrls, ...newUploadedUrls];

      // Create or update item
      final item = Item(
        id: widget.editItemId ?? '', // Will be set by Firestore on add
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        price: _selectedType == ItemType.buy
            ? double.tryParse(_priceController.text)
            : null,
        imageUrls: imageUrls,
        userId: user.uid,
        userEmail: user.email ?? '',
        condition: _selectedCondition,
        category: _selectedCategory,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAvailable: true,
        quantity: int.tryParse(_quantityController.text) ?? 1,
      );

      if (widget.editItemId == null) {
        // Create new
        await firestoreService.addItem(item);
      } else {
        // Update existing - compute which original images were removed
        final originalUrls = _originalItem?.imageUrls ?? [];
        final removedOriginalUrls = originalUrls
            .where((url) => !keptOriginalUrls.contains(url))
            .toList();

        // Update Firestore document
        final updates = {
          'title': item.title,
          'description': item.description,
          'type': item.type.name,
          'price': item.price,
          'imageUrls': imageUrls,
          'condition': item.condition.name,
          'category': item.category,
          'quantity': item.quantity,
        };

        await firestoreService.updateItem(widget.editItemId!, updates);

        // After successful update, delete removed images from Storage
        try {
          for (final url in removedOriginalUrls) {
            await storageService.deleteImage(url);
          }
        } catch (e) {
          // Not critical continue
        }
      }

      // Clear item cache after create or update and refresh item provider
      try {
        final allItemsController = ref.read(
          allItemsControllerProvider.notifier,
        );
        await allItemsController.clearCache();
        // Refresh the single-item provider if we updated an existing item so
        // any open product detail page reflecting that item will reload.
        if (widget.editItemId != null) {
          ref.invalidate(itemByIdControllerProvider(widget.editItemId!));
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editItemId == null
                  ? 'Item listed successfully!'
                  : 'Item updated successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Navigate back to profile screen
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editItemId == null
                  ? 'Error creating listing: ${e.toString()}'
                  : 'Failed to update listing: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editItemId == null ? 'Create Listing' : 'Edit Listing',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker section
              const Text(
                'Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add image button
                    if (_images.length < 5)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photos',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                '(${_images.length}/5)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Display selected images
                    ..._images.asMap().entries.map((entry) {
                      final index = entry.key;
                      final listingImage = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: MemoryImage(listingImage.bytes),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Item type selection
              const Text(
                'Listing Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Free'),
                      ),
                      selected: _selectedType == ItemType.free,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = ItemType.free);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Trade'),
                      ),
                      selected: _selectedType == ItemType.trade,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = ItemType.trade);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Sell'),
                      ),
                      selected: _selectedType == ItemType.buy,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = ItemType.buy);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Blue Winter Jacket',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe your item...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price field (only for buy items)
              if (_selectedType == ItemType.buy) ...[
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  validator: (value) {
                    if (_selectedType == ItemType.buy) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a price';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Quantity field
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  hintText: 'How many are available?',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Condition dropdown
              DropdownButtonFormField<ItemCondition>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: ItemCondition.values.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCondition = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown (optional)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select a category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 32),

              // Submit button
              FilledButton(
                onPressed: _isLoading ? null : _submitListing,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.editItemId == null ? 'List Item' : 'Update Item',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
