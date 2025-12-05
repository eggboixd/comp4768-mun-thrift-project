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

  // Stream single item by ID (real-time updates)
  Stream<Item?> getItemStream(String itemId) {
    return _itemsCollection.doc(itemId).snapshots().map((doc) {
      if (doc.exists) {
        return Item.fromFirestore(doc);
      }
      return null;
    });
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
  Future<List<Item>> searchItems(
    String query, {
    ItemType? type,
    String? category,
  }) async {
    try {
      Query q = _itemsCollection.where('isAvailable', isEqualTo: true);

      if (type != null) {
        q = q.where('type', isEqualTo: type.name);
      }

      if (category != null) {
        q = q.where('category', isEqualTo: category);
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

  // Save FCM token for push notifications
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _userInfoCollection.doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Get FCM token for a user
  Future<String?> getFCMToken(String userId) async {
    try {
      final doc = await _userInfoCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
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
        .where('sellerIds', arrayContains: sellerId)
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

  // Update order status with progress tracking
  Future<void> updateOrderStatusWithProgress(
    String orderId,
    order_model.OrderStatus newStatus, {
    String? note,
  }) async {
    try {
      // Get current order
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = order_model.Order.fromFirestore(orderDoc);

      // Create new progress entry
      final newProgress = order_model.OrderProgress(
        status: newStatus,
        timestamp: DateTime.now(),
        note: note,
      );

      // Add to progress history
      final updatedHistory = [...order.progressHistory, newProgress];

      // Update order
      await _ordersCollection.doc(orderId).update({
        'status': newStatus.name,
        'progressHistory': updatedHistory.map((p) => p.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      // Create notification for buyer about status update
      String title = '';
      String message = note ?? '';

      switch (newStatus) {
        case order_model.OrderStatus.preparing:
          title = 'Order Preparing';
          message = message.isEmpty
              ? 'The seller is preparing your order.'
              : message;
          break;
        case order_model.OrderStatus.shipped:
          title = 'Order Shipped';
          message = message.isEmpty ? 'Your order has been shipped!' : message;
          break;
        case order_model.OrderStatus.inDelivery:
          title = 'Order In Delivery';
          message = message.isEmpty
              ? 'Your order is on the way to you.'
              : message;
          break;
        case order_model.OrderStatus.completed:
          title = 'Order Completed';
          message = message.isEmpty
              ? 'Your order has been delivered. Enjoy!'
              : message;
          break;
        default:
          // Don't send notifications for other status changes
          return;
      }

      // Create notification for the buyer
      await createNotification(
        userId: order.buyerId,
        type: 'orderUpdate',
        title: title,
        message: message,
        orderId: orderId,
      );
    } catch (e) {
      throw Exception('Failed to update order status with progress: $e');
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

  // Trade offer methods
  CollectionReference get _tradeOffersCollection =>
      _firestore.collection('trade-offers');

  // Create trade offer
  Future<String> createTradeOffer(dynamic tradeOffer) async {
    try {
      final docRef = await _tradeOffersCollection.add(tradeOffer.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create trade offer: $e');
    }
  }

  // Get trade offers for seller
  Stream<List<Map<String, dynamic>>> getTradeOffersForSeller(String sellerId) {
    return _tradeOffersCollection
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();
        });
  }

  // Get trade offer by ID
  Future<Map<String, dynamic>?> getTradeOfferById(String offerId) async {
    try {
      final doc = await _tradeOffersCollection.doc(offerId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get trade offer: $e');
    }
  }

  // Update trade offer status
  Future<void> updateTradeOfferStatus({
    required String offerId,
    required String status,
    String? sellerResponse,
  }) async {
    try {
      final updates = {'status': status, 'updatedAt': Timestamp.now()};
      if (sellerResponse != null) {
        updates['sellerResponse'] = sellerResponse;
      }
      await _tradeOffersCollection.doc(offerId).update(updates);
    } catch (e) {
      throw Exception('Failed to update trade offer status: $e');
    }
  }

  // Notification methods
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  // Create a notification
  Future<String> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? orderId,
    String? tradeOfferId,
    String? fromUserId,
    String? fromUserName,
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'orderId': orderId,
        'tradeOfferId': tradeOfferId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'isRead': false,
        'createdAt': Timestamp.now(),
      };

      final docRef = await _notificationsCollection.add(notificationData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Update order status and create notification
  Future<void> updateOrderStatusWithNotification({
    required String orderId,
    required order_model.OrderStatus newStatus,
    required String buyerId,
    String? sellerMessage,
  }) async {
    try {
      // Update order status
      await _ordersCollection.doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      });

      // Create notification for buyer
      String title = '';
      String message = '';

      switch (newStatus) {
        case order_model.OrderStatus.confirmed:
          title = 'Order Accepted';
          message =
              sellerMessage ??
              'Your order has been accepted by the seller and will be prepared for delivery.';
          break;
        case order_model.OrderStatus.cancelled:
          title = 'Order Rejected';
          message =
              sellerMessage ??
              'Your order has been rejected by the seller. Please contact them for more information.';
          break;
        case order_model.OrderStatus.completed:
          title = 'Order Completed';
          message = 'Your order has been marked as completed.';
          break;
        default:
          return;
      }

      await createNotification(
        userId: buyerId,
        type: newStatus == order_model.OrderStatus.confirmed
            ? 'orderAccepted'
            : newStatus == order_model.OrderStatus.cancelled
            ? 'orderRejected'
            : 'orderCompleted',
        title: title,
        message: message,
        orderId: orderId,
      );
    } catch (e) {
      throw Exception('Failed to update order status: $e');
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
