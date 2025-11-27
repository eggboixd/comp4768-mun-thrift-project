import 'package:comp4768_mun_thrift/controllers/cart_controller.dart';
import 'package:comp4768_mun_thrift/models/order.dart';
import 'package:comp4768_mun_thrift/services/auth_service.dart';
import 'package:comp4768_mun_thrift/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String itemType;

  const CheckoutScreen({super.key, required this.itemType});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final total = ref.watch(cartTotalProvider);
    final user = ref.watch(authStateChangesProvider).value;

    if (cart.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/${widget.itemType}');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isFree = total == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFree ? 'Claim Details' : 'Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter delivery address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...cart.map(
                (cartItem) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${cartItem.item.title} x${cartItem.quantity}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        cartItem.totalPrice == 0
                            ? 'Free'
                            : '\$${cartItem.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    total == 0 ? 'Free' : '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You must be logged in to place an order',
                            ),
                          ),
                        );
                        return;
                      }

                      // Show loading dialog
                      if (!mounted) return;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        // Create order items from cart
                        final orderItems = cart.map((cartItem) {
                          return OrderItem(
                            itemId: cartItem.item.id ?? '',
                            itemTitle: cartItem.item.title,
                            itemImageUrl: cartItem.item.primaryImageUrl,
                            itemPrice: cartItem.item.price ?? 0,
                            quantity: cartItem.quantity,
                            sellerId: cartItem.item.userId,
                          );
                        }).toList();

                        // Create order object
                        final order = Order(
                          buyerId: user.uid,
                          items: orderItems,
                          totalAmount: total,
                          deliveryName: _nameController.text.trim(),
                          deliveryAddress: _addressController.text.trim(),
                          deliveryPhone: _phoneController.text.trim(),
                          notes: _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
                          status: OrderStatus.pending,
                          createdAt: DateTime.now(),
                        );

                        // Save order to Firestore
                        final firestoreService = ref.read(
                          firestoreServiceProvider,
                        );
                        final orderId = await firestoreService.createOrder(
                          order,
                        );

                        // Decrease item quantities based on what was purchased
                        final itemQuantities = <String, int>{};
                        for (final cartItem in cart) {
                          itemQuantities[cartItem.item.id] = cartItem.quantity;
                        }
                        await firestoreService.decreaseMultipleItemQuantities(
                          itemQuantities,
                        );

                        // Clear cart
                        ref.read(cartControllerProvider.notifier).clearCart();

                        // Close loading dialog
                        if (!mounted) return;
                        Navigator.of(context).pop();

                        // Show success dialog
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              isFree ? 'Claim Successful!' : 'Order Placed!',
                            ),
                            content: Text(
                              isFree
                                  ? 'Your items have been claimed. The sellers will contact you soon.\n\nOrder ID: $orderId'
                                  : 'Your order has been placed successfully. Thank you for your purchase!\n\nOrder ID: $orderId',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.go('/${widget.itemType}');
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        // Close loading dialog
                        if (!mounted) return;
                        Navigator.of(context).pop();

                        // Show error dialog
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Error'),
                            content: Text('Failed to place order: $e'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isFree ? 'Confirm Claim' : 'Place Order',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
