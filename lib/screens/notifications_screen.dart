import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'bottom_nav_bar.dart';

final userNotificationsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
      return ref.watch(firestoreServiceProvider).getUserNotifications(userId);
    });

final unreadCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getUnreadNotificationCount(userId);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

    final notificationsAsync = ref.watch(userNotificationsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['isRead'] ?? false;
              final createdAt = (notification['createdAt'] as Timestamp?)
                  ?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: isRead ? null : Colors.blue.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey : Colors.blue,
                    child: Icon(
                      _getIconForType(notification['type'] ?? ''),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification['message'] ?? ''),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () async {
                    // Mark as read
                    if (!isRead) {
                      await ref
                          .read(firestoreServiceProvider)
                          .markNotificationAsRead(notification['id'] as String);
                    }

                    // Navigate based on notification type
                    // ignore: use_build_context_synchronously
                    if (notification['tradeOfferId'] != null) {
                      // Navigate to trade offer details
                      // ignore: use_build_context_synchronously
                      context.push(
                        '/trade-offer-details/${notification['tradeOfferId']}',
                      );
                    } else if (notification['orderId'] != null) {
                      // Navigate to seller orders
                      // ignore: use_build_context_synchronously
                      context.push('/seller-orders');
                    } else if (notification['type'] == 'chatMessage' &&
                        notification['fromUserId'] != null) {
                      // Navigate to chat for messages
                      // ignore: use_build_context_synchronously
                      context.push('/chat/${notification['fromUserId']}');
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading notifications: $error')),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'orderRequest':
        return Icons.shopping_bag;
      case 'orderAccepted':
        return Icons.check_circle;
      case 'orderRejected':
        return Icons.cancel;
      case 'orderCompleted':
        return Icons.done_all;
      case 'tradeRequest':
        return Icons.swap_horiz;
      case 'tradeAccepted':
        return Icons.check_circle_outline;
      case 'tradeRejected':
        return Icons.cancel_outlined;
      case 'chatMessage':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
