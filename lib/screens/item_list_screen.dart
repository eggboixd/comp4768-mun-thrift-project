import 'package:comp4768_mun_thrift/controllers/cart_controller.dart';
import 'package:comp4768_mun_thrift/screens/list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'bottom_nav_bar.dart';

class ItemListScreen extends ConsumerWidget {
  final String itemType;
  const ItemListScreen({super.key, required this.itemType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsByTypeStringProvider(itemType));
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MUN Thrift'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              context.push('/search');
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Cart',
                onPressed: () {
                  context.push('/cart/$itemType');
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No $itemType items yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to add one!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: (items.length / 2).ceil(),
            itemBuilder: (context, rowIndex) {
              final firstIndex = rowIndex * 2;
              final secondIndex = firstIndex + 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListItem(
                      image: NetworkImage(items[firstIndex].primaryImageUrl),
                      itemName: items[firstIndex].title,
                      onTap: () {
                        context.push(
                          '/product/$itemType/${items[firstIndex].id}',
                        );
                      },
                      price: items[firstIndex].price,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (secondIndex < items.length)
                    Expanded(
                      child: ListItem(
                        image: NetworkImage(items[secondIndex].primaryImageUrl),
                        itemName: items[secondIndex].title,
                        onTap: () {
                          context.push(
                            '/product/$itemType/${items[secondIndex].id}',
                          );
                        },
                        price: items[secondIndex].price,
                      ),
                    )
                  else
                    Expanded(child: Container()),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          final errorMsg = error.toString();
          final isIndexError =
              errorMsg.contains('requires an index') ||
              errorMsg.contains('failed-precondition');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isIndexError ? Icons.hourglass_empty : Icons.error_outline,
                    size: 64,
                    color: isIndexError ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isIndexError
                        ? 'Building Database Indexes'
                        : 'Error loading items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isIndexError) ...[
                    Text(
                      'Firestore indexes are being created.\nThis usually takes 2-5 minutes.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Force refresh by invalidating the provider
                        ref.invalidate(itemsByTypeStringProvider(itemType));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        errorMsg,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/profile/create-listing');
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: itemType == 'free'
            ? 0
            : itemType == 'trade'
            ? 1
            : 2,
      ),
    );
  }
}
