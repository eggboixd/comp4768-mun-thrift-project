import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

/// Helper class for sending push notifications to users
/// 
/// Push notifications are handled by Firebase Cloud Functions that:
/// 1. Listen for new documents in the 'notifications' collection
/// 2. Fetch the user's FCM token from Firestore
/// 3. Send the push notification via Firebase Cloud Messaging
/// 
/// This ensures the Firebase Admin SDK is used securely on the server side.
class NotificationHelper {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;

  NotificationHelper(this._firestoreService, this._notificationService);

  /// Send a local notification (shown immediately on this device)
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationService.showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Send notification when a buyer creates an order (seller receives it)
  /// The actual push notification is sent by Cloud Functions
  Future<void> notifyNewOrder({
    required String sellerUserId,
    required String buyerName,
    required String orderId,
    bool isFree = false,
  }) async {
    await _firestoreService.createNotification(
      userId: sellerUserId,
      type: 'orderRequest',
      title: 'New Order Request',
      message: '$buyerName wants to ${isFree ? "claim" : "buy"} your items. '
          'Please review the order.',
      orderId: orderId,
    );
  }

  /// Send notification when seller updates order status (buyer receives it)
  /// The actual push notification is sent by Cloud Functions
  Future<void> notifyOrderStatusUpdate({
    required String buyerUserId,
    required String orderId,
    required String status,
    String? customMessage,
  }) async {
    String title = '';
    String message = customMessage ?? '';

    switch (status) {
      case 'confirmed':
        title = 'Order Confirmed';
        message = message.isEmpty
            ? 'Your order has been confirmed and is being prepared.'
            : message;
        break;
      case 'preparing':
        title = 'Order Preparing';
        message = message.isEmpty
            ? 'The seller is preparing your order.'
            : message;
        break;
      case 'shipped':
        title = 'Order Shipped';
        message = message.isEmpty
            ? 'Your order has been shipped!'
            : message;
        break;
      case 'inDelivery':
        title = 'Order In Delivery';
        message = message.isEmpty
            ? 'Your order is on the way to you.'
            : message;
        break;
      case 'completed':
        title = 'Order Completed';
        message = message.isEmpty
            ? 'Your order has been delivered. Enjoy!'
            : message;
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        message = message.isEmpty
            ? 'Your order has been cancelled.'
            : message;
        break;
      default:
        return;
    }

    await _firestoreService.createNotification(
      userId: buyerUserId,
      type: 'orderUpdate',
      title: title,
      message: message,
      orderId: orderId,
    );
  }

  /// Send notification when trade offer is received (seller receives it)
  /// The actual push notification is sent by Cloud Functions
  Future<void> notifyTradeOfferReceived({
    required String sellerUserId,
    required String buyerName,
    required String itemTitle,
    required String tradeOfferId,
  }) async {
    await _firestoreService.createNotification(
      userId: sellerUserId,
      type: 'tradeRequest',
      title: 'New Trade Offer',
      message: '$buyerName wants to trade for "$itemTitle"',
      tradeOfferId: tradeOfferId,
    );
  }

  /// Send notification when trade offer status changes (buyer receives it)
  /// The actual push notification is sent by Cloud Functions
  Future<void> notifyTradeOfferStatusUpdate({
    required String buyerUserId,
    required String tradeOfferId,
    required String status,
    required String itemTitle,
    String? sellerResponse,
  }) async {
    String title = '';
    String message = '';

    switch (status) {
      case 'accepted':
        title = 'Trade Offer Accepted!';
        message = 'Your trade offer for "$itemTitle" has been accepted!';
        if (sellerResponse != null && sellerResponse.isNotEmpty) {
          message += ' Message: $sellerResponse';
        }
        break;
      case 'rejected':
        title = 'Trade Offer Declined';
        message = 'Your trade offer for "$itemTitle" has been declined.';
        if (sellerResponse != null && sellerResponse.isNotEmpty) {
          message += ' Reason: $sellerResponse';
        }
        break;
      default:
        return;
    }

    await _firestoreService.createNotification(
      userId: buyerUserId,
      type: 'tradeOfferUpdate',
      title: title,
      message: message,
      tradeOfferId: tradeOfferId,
    );
  }
}

final notificationHelperProvider = Provider<NotificationHelper>((ref) {
  return NotificationHelper(
    ref.watch(firestoreServiceProvider),
    ref.watch(notificationServiceProvider),
  );
});
