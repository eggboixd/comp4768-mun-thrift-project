import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

/// Helper class for sending push notifications to users
///
/// Note: For production use, you should implement this logic in Firebase Cloud Functions
/// to avoid exposing your Firebase server key in the client app.
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

  /// Example: Send notification when someone messages you
  /// In production, this should be done via Cloud Functions
  Future<void> notifyNewMessage({
    required String recipientUserId,
    required String senderName,
    required String messagePreview,
    required String chatId,
  }) async {
    // Get recipient's FCM token
    final token = await _firestoreService.getFCMToken(recipientUserId);

    if (token != null) {
      // In production, you would send this to your backend/Cloud Function
      // which then uses Firebase Admin SDK to send the notification
      print('Would send notification to token: $token');
      print('Title: New message from $senderName');
      print('Body: $messagePreview');
      print('Data: chatId=$chatId');
    }
  }

  /// Example: Send notification when item is sold
  Future<void> notifyItemSold({
    required String sellerUserId,
    required String itemTitle,
    required String buyerName,
    required String orderId,
  }) async {
    final token = await _firestoreService.getFCMToken(sellerUserId);

    if (token != null) {
      print('Would send notification to token: $token');
      print('Title: Item Sold!');
      print('Body: $buyerName purchased your $itemTitle');
      print('Data: orderId=$orderId');
    }
  }

  /// Example: Send notification when trade offer is received
  Future<void> notifyTradeOfferReceived({
    required String receiverUserId,
    required String senderName,
    required String itemTitle,
    required String offerId,
  }) async {
    final token = await _firestoreService.getFCMToken(receiverUserId);

    if (token != null) {
      print('Would send notification to token: $token');
      print('Title: New Trade Offer');
      print('Body: $senderName wants to trade for your $itemTitle');
      print('Data: offerId=$offerId');
    }
  }
}

final notificationHelperProvider = Provider<NotificationHelper>((ref) {
  return NotificationHelper(
    ref.watch(firestoreServiceProvider),
    ref.watch(notificationServiceProvider),
  );
});
