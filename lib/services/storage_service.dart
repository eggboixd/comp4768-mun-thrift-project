import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for FirebaseStorage instance
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// Storage service class
class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  // Upload image from bytes and return download URL (works on all platforms)
  Future<String> uploadImageBytes(Uint8List imageBytes, String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      final uploadTask = await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload multiple images from bytes
  Future<List<String>> uploadMultipleImageBytes(
    List<Uint8List> imageBytesList,
    String basePath,
  ) async {
    try {
      final List<String> downloadUrls = [];

      for (int i = 0; i < imageBytesList.length; i++) {
        final path = '$basePath/image_$i.jpg';
        final url = await uploadImageBytes(imageBytesList[i], path);
        downloadUrls.add(url);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Delete image by URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Delete multiple images
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        await deleteImage(url);
      }
    } catch (e) {
      throw Exception('Failed to delete images: $e');
    }
  }

  // Generate unique path for item images
  String generateItemImagePath(String userId, String itemId, int index) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'items/$userId/$itemId/${timestamp}_$index.jpg';
  }
}

// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(firebaseStorageProvider));
});
