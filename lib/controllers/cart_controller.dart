import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comp4768_mun_thrift/models/cart_item.dart';
import 'package:comp4768_mun_thrift/models/item.dart';

class CartController extends StateNotifier<List<CartItem>> {
  CartController() : super([]);

  void addToCart(Item item) {
    // Don't add if item is sold out
    if (item.isSoldOut) {
      return;
    }

    // Check if item already exists in cart
    final existingIndex = state.indexWhere(
      (cartItem) => cartItem.item.id == item.id,
    );

    if (existingIndex >= 0) {
      // Item exists, check if we can increase quantity
      final currentQuantity = state[existingIndex].quantity;
      if (currentQuantity < item.quantity) {
        final updatedCart = [...state];
        updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
          quantity: currentQuantity + 1,
        );
        state = updatedCart;
      }
      // If we've reached max quantity, do nothing
    } else {
      // Item doesn't exist, add new cart item
      state = [...state, CartItem(item: item, quantity: 1)];
    }
  }

  void removeFromCart(String itemId) {
    state = state.where((cartItem) => cartItem.item.id != itemId).toList();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    final updatedCart = state.map((cartItem) {
      if (cartItem.item.id == itemId) {
        // Cap quantity at available stock
        final cappedQuantity = quantity > cartItem.item.quantity
            ? cartItem.item.quantity
            : quantity;
        return cartItem.copyWith(quantity: cappedQuantity);
      }
      return cartItem;
    }).toList();

    state = updatedCart;
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0.0, (sum, cartItem) => sum + cartItem.totalPrice);
  }

  int get itemCount {
    return state.fold(0, (sum, cartItem) => sum + cartItem.quantity);
  }

  bool isInCart(String itemId) {
    return state.any((cartItem) => cartItem.item.id == itemId);
  }
}

final cartControllerProvider =
    StateNotifierProvider<CartController, List<CartItem>>((ref) {
      return CartController();
    });

// Provider for total amount
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartControllerProvider);
  return cart.fold(0.0, (sum, cartItem) => sum + cartItem.totalPrice);
});

// Provider for item count
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartControllerProvider);
  return cart.fold(0, (sum, cartItem) => sum + cartItem.quantity);
});
