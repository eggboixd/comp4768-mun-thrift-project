import 'package:comp4768_mun_thrift/controllers/cart_controller.dart';
import 'package:comp4768_mun_thrift/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum CartFilter { all, free, paid }

enum CartSort { none, priceAsc, priceDesc }

class CartScreen extends ConsumerStatefulWidget {
  final String itemType;

  const CartScreen({super.key, required this.itemType});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  CartFilter _currentFilter = CartFilter.all;
  CartSort _currentSort = CartSort.none;

  List<CartItem> _getFilteredAndSortedCart(List<CartItem> cart) {
    // Apply filter
    List<CartItem> filtered = cart;

    switch (_currentFilter) {
      case CartFilter.free:
        filtered = cart.where((item) => (item.item.price ?? 0) == 0).toList();
        break;
      case CartFilter.paid:
        filtered = cart.where((item) => (item.item.price ?? 0) > 0).toList();
        break;
      case CartFilter.all:
        filtered = cart;
        break;
    }

    // Apply sort
    switch (_currentSort) {
      case CartSort.priceAsc:
        filtered.sort(
          (a, b) => (a.item.price ?? 0).compareTo(b.item.price ?? 0),
        );
        break;
      case CartSort.priceDesc:
        filtered.sort(
          (a, b) => (b.item.price ?? 0).compareTo(a.item.price ?? 0),
        );
        break;
      case CartSort.none:
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final cartController = ref.read(cartControllerProvider.notifier);
    final total = ref.watch(cartTotalProvider);

    final filteredCart = _getFilteredAndSortedCart(cart);

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart'), centerTitle: true),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/${widget.itemType}');
                    },
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filter and Sort UI
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter dropdown
                      DropdownButtonFormField<CartFilter>(
                        initialValue: _currentFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Filter Items',
                          prefixIcon: const Icon(Icons.filter_list, size: 20),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: CartFilter.all,
                            child: Text('All Items'),
                          ),
                          DropdownMenuItem(
                            value: CartFilter.free,
                            child: Text('Free Only'),
                          ),
                          DropdownMenuItem(
                            value: CartFilter.paid,
                            child: Text('Paid Only'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _currentFilter = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Sort dropdown
                      DropdownButtonFormField<CartSort>(
                        initialValue: _currentSort,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Sort By',
                          prefixIcon: const Icon(Icons.sort, size: 20),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: CartSort.none,
                            child: Text('Default Order'),
                          ),
                          DropdownMenuItem(
                            value: CartSort.priceAsc,
                            child: Text('Price: Low to High'),
                          ),
                          DropdownMenuItem(
                            value: CartSort.priceDesc,
                            child: Text('Price: High to Low'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _currentSort = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Cart items list
                Expanded(
                  child: filteredCart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No items match your filter',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCart.length,
                          itemBuilder: (context, index) {
                            final cartItem = filteredCart[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        cartItem.item.primaryImageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartItem.item.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            (cartItem.item.price ?? 0) == 0
                                                ? 'Free'
                                                : '\$${(cartItem.item.price ?? 0).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Available: ${cartItem.item.quantity}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                ),
                                                onPressed: () {
                                                  cartController.updateQuantity(
                                                    cartItem.item.id,
                                                    cartItem.quantity - 1,
                                                  );
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                child: Text(
                                                  '${cartItem.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                ),
                                                onPressed:
                                                    cartItem.quantity >=
                                                        cartItem.item.quantity
                                                    ? null
                                                    : () {
                                                        cartController
                                                            .updateQuantity(
                                                              cartItem.item.id,
                                                              cartItem.quantity +
                                                                  1,
                                                            );
                                                      },
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        cartController.removeFromCart(
                                          cartItem.item.id,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            total == 0
                                ? 'Free'
                                : '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/checkout/${widget.itemType}');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            total == 0 ? 'Claim Items' : 'Proceed to Checkout',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
