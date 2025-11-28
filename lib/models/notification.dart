import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderRequest,
  orderAccepted,
  orderRejected,
  orderCompleted,
  tradeRequest,
  tradeAccepted,
  tradeRejected;

  String get displayName {
    switch (this) {
      case NotificationType.orderRequest:
        return 'Order Request';
      case NotificationType.orderAccepted:
        return 'Order Accepted';
      case NotificationType.orderRejected:
        return 'Order Rejected';
      case NotificationType.orderCompleted:
        return 'Order Completed';
      case NotificationType.tradeRequest:
        return 'Trade Request';
      case NotificationType.tradeAccepted:
        return 'Trade Accepted';
      case NotificationType.tradeRejected:
        return 'Trade Rejected';
    }
  }
}

class NotificationModel {
  final String? id;
  final String userId; // User who receives this notification
  final NotificationType type;
  final String title;
  final String message;
  final String? orderId;
  final String? tradeOfferId; // For trade-related notifications
  final String? fromUserId; // User who triggered this notification
  final String? fromUserName;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.orderId,
    this.tradeOfferId,
    this.fromUserId,
    this.fromUserName,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'orderId': orderId,
      'tradeOfferId': tradeOfferId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.orderRequest,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      orderId: data['orderId'],
      tradeOfferId: data['tradeOfferId'],
      fromUserId: data['fromUserId'],
      fromUserName: data['fromUserName'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? orderId,
    String? tradeOfferId,
    String? fromUserId,
    String? fromUserName,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      orderId: orderId ?? this.orderId,
      tradeOfferId: tradeOfferId ?? this.tradeOfferId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
