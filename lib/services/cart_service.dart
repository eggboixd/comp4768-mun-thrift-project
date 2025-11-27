import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/cart_item.dart';

class CartService {
  final FirebaseFirestore _firestore;
  static const String _hiveBoxName = 'cart_box';
  static const String _hiveCartKey = 'cart_items';

  CartService(this._firestore);

  // Get reference to user's cart in Firestore
  DocumentReference _getUserCartRef(String userId) {
    return _firestore.collection('carts').doc(userId);
  }

  // Save cart to Firestore
  Future<void> saveCartToFirestore(
    String userId,
    List<CartItem> cartItems,
  ) async {
    try {
      final cartData = {
        'items': cartItems.map((item) => item.toJson()).toList(),
        'updatedAt': Timestamp.now(),
      };
      await _getUserCartRef(userId).set(cartData);
    } catch (e) {
      print('Error saving cart to Firestore: $e');
      // Don't throw - we want the app to continue working even if Firestore fails
    }
  }

  // Load cart from Firestore
  Future<List<CartItem>> loadCartFromFirestore(String userId) async {
    try {
      final doc = await _getUserCartRef(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;
        if (items != null) {
          return items
              .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading cart from Firestore: $e');
      return [];
    }
  }

  // Clear cart from Firestore
  Future<void> clearCartFromFirestore(String userId) async {
    try {
      await _getUserCartRef(userId).delete();
    } catch (e) {
      print('Error clearing cart from Firestore: $e');
    }
  }

  // Save cart to local storage (Hive)
  Future<void> saveCartToLocal(List<CartItem> cartItems) async {
    try {
      final box = await Hive.openBox(_hiveBoxName);
      final cartData = cartItems.map((item) => item.toJson()).toList();
      await box.put(_hiveCartKey, cartData);
    } catch (e) {
      print('Error saving cart to local storage: $e');
    }
  }

  // Load cart from local storage (Hive)
  Future<List<CartItem>> loadCartFromLocal() async {
    try {
      final box = await Hive.openBox(_hiveBoxName);
      final cartData = box.get(_hiveCartKey) as List<dynamic>?;
      if (cartData != null) {
        return cartData
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error loading cart from local storage: $e');
      return [];
    }
  }

  // Clear cart from local storage
  Future<void> clearCartFromLocal() async {
    try {
      final box = await Hive.openBox(_hiveBoxName);
      await box.delete(_hiveCartKey);
    } catch (e) {
      print('Error clearing cart from local storage: $e');
    }
  }

  // Hybrid save - saves to both Firestore and local storage
  Future<void> saveCart(String? userId, List<CartItem> cartItems) async {
    // Always save locally
    await saveCartToLocal(cartItems);

    // Save to Firestore if user is logged in
    if (userId != null) {
      await saveCartToFirestore(userId, cartItems);
    }
  }

  // Hybrid load - prioritizes Firestore, falls back to local storage
  Future<List<CartItem>> loadCart(String? userId) async {
    // If user is logged in, try Firestore first
    if (userId != null) {
      final firestoreCart = await loadCartFromFirestore(userId);
      if (firestoreCart.isNotEmpty) {
        // Sync to local storage
        await saveCartToLocal(firestoreCart);
        return firestoreCart;
      }
    }

    // Fall back to local storage
    return await loadCartFromLocal();
  }

  // Clear cart from both storage locations
  Future<void> clearCart(String? userId) async {
    await clearCartFromLocal();
    if (userId != null) {
      await clearCartFromFirestore(userId);
    }
  }

  // Merge local cart with Firestore cart (useful when user logs in)
  Future<List<CartItem>> mergeAndSyncCarts(String userId) async {
    final localCart = await loadCartFromLocal();
    final firestoreCart = await loadCartFromFirestore(userId);

    // Create a map to merge items by item ID
    final Map<String, CartItem> mergedCart = {};

    // Add Firestore items first
    for (final item in firestoreCart) {
      mergedCart[item.item.id] = item;
    }

    // Merge local items (increase quantity if item exists)
    for (final localItem in localCart) {
      final itemId = localItem.item.id;
      if (mergedCart.containsKey(itemId)) {
        // Item exists, merge quantities (cap at stock)
        final existingItem = mergedCart[itemId]!;
        final newQuantity = existingItem.quantity + localItem.quantity;
        final cappedQuantity = newQuantity > existingItem.item.quantity
            ? existingItem.item.quantity
            : newQuantity;
        mergedCart[itemId] = existingItem.copyWith(quantity: cappedQuantity);
      } else {
        // New item from local cart
        mergedCart[itemId] = localItem;
      }
    }

    final finalCart = mergedCart.values.toList();

    // Save merged cart to both locations
    await saveCart(userId, finalCart);

    return finalCart;
  }
}

// Provider for CartService
final cartServiceProvider = Provider<CartService>((ref) {
  return CartService(FirebaseFirestore.instance);
});
