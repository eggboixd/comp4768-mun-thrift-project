import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart' as order_model;
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'bottom_nav_bar.dart';

final sellerOrdersProvider =
    StreamProvider.family<List<order_model.Order>, String>((ref, sellerId) {
      return ref.watch(firestoreServiceProvider).getOrdersForSeller(sellerId);
    });

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view orders')),
      );
    }

    final ordersAsync = ref.watch(sellerOrdersProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('My Sales')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No sales yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // Filter items that belong to this seller
              final myItems = order.items
                  .where((item) => item.sellerId == user.uid)
                  .toList();

              if (myItems.isEmpty) return const SizedBox.shrink();

              final myTotal = myItems.fold<double>(
                0,
                (sum, item) => sum + (item.itemPrice * item.quantity),
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(order.status),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'Order #${order.id?.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Status: ${order.status.displayName}'),
                      Text('Your items: ${myItems.length}'),
                      Text(
                        'Your total: \$${myTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDateTime(order.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Items:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...myItems.map(
                            (item) => ListTile(
                              leading: Image.network(
                                item.itemImageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                              title: Text(item.itemTitle),
                              subtitle: Text('Quantity: ${item.quantity}'),
                              trailing: Text(
                                '\$${(item.itemPrice * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Delivery Information:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(order.deliveryName),
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(order.deliveryAddress),
                          ),
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: Text(order.deliveryPhone),
                          ),
                          if (order.notes != null &&
                              order.notes!.isNotEmpty) ...[
                            ListTile(
                              leading: const Icon(Icons.note),
                              title: Text(order.notes!),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (order.status ==
                              order_model.OrderStatus.pending) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _acceptOrder(context, ref, order),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Accept'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _rejectOrder(context, ref, order),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Reject'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading orders: $error')),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Future<void> _acceptOrder(
    BuildContext context,
    WidgetRef ref,
    order_model.Order order,
  ) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Decrease item quantities when order is accepted
      final itemQuantities = <String, int>{};
      for (final item in order.items) {
        itemQuantities[item.itemId] = item.quantity;
      }
      await firestoreService.decreaseMultipleItemQuantities(itemQuantities);

      // Update order status and notify buyer
      await firestoreService.updateOrderStatusWithNotification(
        orderId: order.id!,
        newStatus: order_model.OrderStatus.confirmed,
        buyerId: order.buyerId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept order: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(
    BuildContext context,
    WidgetRef ref,
    order_model.Order order,
  ) async {
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateOrderStatusWithNotification(
            orderId: order.id!,
            newStatus: order_model.OrderStatus.cancelled,
            buyerId: order.buyerId,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject order: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _getStatusColor(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return Colors.orange;
      case order_model.OrderStatus.confirmed:
        return Colors.green;
      case order_model.OrderStatus.completed:
        return Colors.blue;
      case order_model.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return Icons.hourglass_empty;
      case order_model.OrderStatus.confirmed:
        return Icons.check_circle;
      case order_model.OrderStatus.completed:
        return Icons.done_all;
      case order_model.OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
