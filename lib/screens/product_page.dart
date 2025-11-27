import 'package:comp4768_mun_thrift/controllers/cart_controller.dart';
import 'package:comp4768_mun_thrift/controllers/item_controller.dart';
import 'package:comp4768_mun_thrift/screens/bottom_nav_bar.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text('Product Page')),
      body: itemAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Error: Item not found.'));
          }
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
                      const SizedBox(height: 36),
                      Text(
                        // TODO: Change to user display name when available and add profile picture
                        item.userId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
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
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            final cartController = ref.read(
                              cartControllerProvider.notifier,
                            );
                            cartController.addToCart(item);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.title} added to cart'),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  onPressed: () {
                                    context.push('/cart/$itemType');
                                  },
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
                            children: [
                              Icon(
                                itemType == 'free'
                                    ? Icons.add_shopping_cart
                                    : itemType == 'trade'
                                    ? Icons.swap_horiz
                                    : Icons.add_shopping_cart,
                              ),
                              SizedBox(width: 12),
                              Text(
                                itemType == 'free'
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
                            // TODO: Add logic
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
                              Text('Chat'),
                            ],
                          ),
                        ),
                      ),
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
