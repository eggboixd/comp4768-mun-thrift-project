import 'package:comp4768_mun_thrift/controllers/cart_controller.dart';
import 'package:comp4768_mun_thrift/controllers/item_controller.dart';
import 'package:comp4768_mun_thrift/controllers/user_info_controller.dart';
import 'package:comp4768_mun_thrift/screens/bottom_nav_bar.dart';
import 'package:comp4768_mun_thrift/services/auth_service.dart';
import 'package:comp4768_mun_thrift/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductPage extends ConsumerWidget {
  final String id;
  final String itemType;

  const ProductPage({super.key, required this.id, required this.itemType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdControllerProvider(id));
    final currentUser = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text('Product Page')),
      body: itemAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Error: Item not found.'));
          }

          // Check if current user is the owner
          final isOwner = currentUser != null && currentUser.uid == item.userId;

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: Image.network(
                    item.primaryImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 36),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Condition: ${item.condition.displayName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Quantity: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 14,
                              color: item.isSoldOut
                                  ? Colors.red
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.isSoldOut) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 36),
                      Consumer(
                        builder: (context, ref, _) {
                          final sellerInfoAsync = ref.watch(
                            userInfoControllerProvider(item.userId),
                          );
                          return sellerInfoAsync.when(
                            data: (sellerInfo) {
                              final displayName =
                                  sellerInfo?.name ?? item.userId;
                              final profileImage =
                                  sellerInfo?.profileImageUrl ?? '';
                              return InkWell(
                                onTap: () => context.push(
                                  '/profile/external/${item.userId}',
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (profileImage.isNotEmpty) ...[
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundImage: NetworkImage(
                                          profileImage,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (e, st) => Text(item.userId),
                          );
                        },
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 400,
                          color: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Text(
                            item.description,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Show different UI based on ownership
                      if (isOwner) ...[
                        // Owner UI - Edit and Delete buttons
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Navigate to edit screen when implemented
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Edit functionality coming soon!',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.edit),
                                SizedBox(width: 12),
                                Text('Edit Listing'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Listing'),
                                  content: Text(
                                    'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ref
                                      .read(firestoreServiceProvider)
                                      .permanentlyDeleteItem(item.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Listing deleted successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    context.go('/profile');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to delete listing: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.delete),
                                SizedBox(width: 12),
                                Text('Delete Listing'),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Regular user UI - Add to cart and Chat buttons
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: item.isSoldOut
                                ? null
                                : () {
                                    if (itemType == 'trade') {
                                      // Navigate to trade offer screen
                                      context.push(
                                        '/trade-offer/${item.id}',
                                        extra: {
                                          'requestedItemTitle': item.title,
                                          'sellerId': item.userId,
                                        },
                                      );
                                    } else {
                                      // Add to cart for free/buy items
                                      final cartController = ref.read(
                                        cartControllerProvider.notifier,
                                      );
                                      cartController.addToCart(item);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${item.title} added to cart',
                                          ),
                                          duration: const Duration(seconds: 2),
                                          action: SnackBarAction(
                                            label: 'View Cart',
                                            onPressed: () {
                                              context.push('/cart/$itemType');
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.isSoldOut
                                      ? Icons.block
                                      : itemType == 'free'
                                      ? Icons.add_shopping_cart
                                      : itemType == 'trade'
                                      ? Icons.swap_horiz
                                      : Icons.add_shopping_cart,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  item.isSoldOut
                                      ? 'Sold Out'
                                      : itemType == 'free'
                                      ? 'Add to Cart'
                                      : itemType == 'trade'
                                      ? 'Trade'
                                      : 'Add to Cart',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              context.push('/chat/${item.userId}');
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.message),
                                SizedBox(width: 12),
                                Text('Chat Seller'),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
