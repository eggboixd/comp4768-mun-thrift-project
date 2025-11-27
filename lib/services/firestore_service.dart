import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comp4768_mun_thrift/models/order.dart' as order_model;
import 'package:comp4768_mun_thrift/models/user_info.dart';
import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';

// Provider for FirebaseFirestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Firestore service class
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  // Collection reference
  CollectionReference get _itemsCollection => _firestore.collection('items');
  CollectionReference get _userInfoCollection =>
      _firestore.collection('user-info');
  CollectionReference get _ordersCollection => _firestore.collection('orders');

  // Stream of items by type
  Stream<List<Item>> getItemsByType(ItemType type) {
    return _itemsCollection
        .where('type', isEqualTo: type.name)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
        });
  }

  // Stream of all items
  Stream<List<Item>> getAllItems() {
    return _itemsCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
        });
  }

  // Get items by user
  Stream<List<Item>> getItemsByUser(String userId) {
    return _itemsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
        });
  }

  // Get single item by ID
  Future<Item?> getItemById(String itemId) async {
    try {
      final doc = await _itemsCollection.doc(itemId).get();
      if (doc.exists) {
        return Item.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get item: $e');
    }
  }

  // Add new item
  Future<String> addItem(Item item) async {
    try {
      final docRef = await _itemsCollection.add(item.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  // Update item
  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _itemsCollection.doc(itemId).update(updates);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  // Delete item (soft delete by marking as unavailable)
  Future<void> deleteItem(String itemId) async {
    try {
      await _itemsCollection.doc(itemId).update({
        'isAvailable': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Hard delete item (permanently remove)
  Future<void> permanentlyDeleteItem(String itemId) async {
    try {
      await _itemsCollection.doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to permanently delete item: $e');
    }
  }

  // Search items by title or description
  Future<List<Item>> searchItems(String query, {ItemType? type}) async {
    try {
      Query q = _itemsCollection.where('isAvailable', isEqualTo: true);

      if (type != null) {
        q = q.where('type', isEqualTo: type.name);
      }

      final snapshot = await q.get();
      final items = snapshot.docs
          .map((doc) => Item.fromFirestore(doc))
          .toList();

      // Filter by query (Firestore doesn't support full-text search natively)
      final lowerQuery = query.toLowerCase();
      return items.where((item) {
        return item.title.toLowerCase().contains(lowerQuery) ||
            item.description.toLowerCase().contains(lowerQuery) ||
            (item.category?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search items: $e');
    }
  }

  // Save user info
  Future<void> saveUserInfo(
    String userId,
    Map<String, dynamic> userInfo,
  ) async {
    try {
      await _userInfoCollection
          .doc(userId)
          .set(userInfo, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user info: $e');
    }
  }

  // Get user info
  Future<UserInfo?> getUserInfo(String userId) async {
    try {
      final doc = await _userInfoCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserInfo(
          id: userId,
          name: data['name'] ?? '',
          address: data['address'] ?? '',
          about: data['about'],
          profileImageUrl: data['profileImageUrl'] ?? '',
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user info: $e');
    }
  }

  // Update user info
  Future<void> updateUserInfo(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      throw Exception('Unauthorized: You can only update your own info.');
    }
    try {
      await _userInfoCollection.doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user info: $e');
    }
  }

  // Create order
  Future<String> createOrder(order_model.Order order) async {
    try {
      final docRef = await _ordersCollection.add(order.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get order by ID
  Future<order_model.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (doc.exists) {
        return order_model.Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Get orders by buyer
  Stream<List<order_model.Order>> getOrdersByBuyer(String buyerId) {
    return _ordersCollection
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => order_model.Order.fromFirestore(doc))
              .toList();
        });
  }

  // Get orders containing items from a specific seller
  Stream<List<order_model.Order>> getOrdersForSeller(String sellerId) {
    return _ordersCollection
        .where('items', arrayContains: {'sellerId': sellerId})
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => order_model.Order.fromFirestore(doc))
              .toList();
        });
  }

  // Update order status
  Future<void> updateOrderStatus(
    String orderId,
    order_model.OrderStatus status,
  ) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Decrease item quantity when purchased/claimed
  Future<void> decreaseItemQuantity(
    String itemId,
    int quantityPurchased,
  ) async {
    try {
      final doc = await _itemsCollection.doc(itemId).get();
      if (!doc.exists) {
        throw Exception('Item not found');
      }

      final currentQuantity =
          (doc.data() as Map<String, dynamic>)['quantity'] ?? 1;
      final newQuantity = currentQuantity - quantityPurchased;

      await _itemsCollection.doc(itemId).update({
        'quantity': newQuantity > 0 ? newQuantity : 0,
        'isAvailable': newQuantity > 0,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to decrease item quantity: $e');
    }
  }

  // Mark items as sold/claimed (legacy - now use decreaseItemQuantity)
  Future<void> markItemsAsSold(List<String> itemIds) async {
    try {
      final batch = _firestore.batch();
      for (final itemId in itemIds) {
        batch.update(_itemsCollection.doc(itemId), {
          'isAvailable': false,
          'updatedAt': Timestamp.now(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark items as sold: $e');
    }
  }

  // Batch decrease quantities for multiple items
  Future<void> decreaseMultipleItemQuantities(
    Map<String, int> itemQuantities,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final entry in itemQuantities.entries) {
        final itemId = entry.key;
        final quantityPurchased = entry.value;

        final doc = await _itemsCollection.doc(itemId).get();
        if (doc.exists) {
          final currentQuantity =
              (doc.data() as Map<String, dynamic>)['quantity'] ?? 1;
          final newQuantity = currentQuantity - quantityPurchased;

          batch.update(_itemsCollection.doc(itemId), {
            'quantity': newQuantity > 0 ? newQuantity : 0,
            'isAvailable': newQuantity > 0,
            'updatedAt': Timestamp.now(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to decrease item quantities: $e');
    }
  }
}

// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.watch(firestoreProvider));
});

// Provider for items by type
final itemsByTypeProvider = StreamProvider.family<List<Item>, ItemType>((
  ref,
  type,
) {
  return ref.watch(firestoreServiceProvider).getItemsByType(type);
});

// Provider for items by type using string
final itemsByTypeStringProvider = StreamProvider.family<List<Item>, String>((
  ref,
  typeString,
) {
  final type = ItemType.fromString(typeString);
  return ref.watch(firestoreServiceProvider).getItemsByType(type);
});

// Provider for all items
final allItemsProvider = StreamProvider<List<Item>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllItems();
});

// Provider for user's items
final userItemsProvider = StreamProvider.family<List<Item>, String>((
  ref,
  userId,
) {
  return ref.watch(firestoreServiceProvider).getItemsByUser(userId);
});
