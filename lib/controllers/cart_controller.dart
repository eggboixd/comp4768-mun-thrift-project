import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comp4768_mun_thrift/models/cart_item.dart';
import 'package:comp4768_mun_thrift/models/item.dart';
import 'package:comp4768_mun_thrift/services/cart_service.dart';
import 'package:comp4768_mun_thrift/services/auth_service.dart';

class CartController extends StateNotifier<List<CartItem>> {
  final CartService _cartService;
  final String? _userId;
  

  CartController(this._cartService, this._userId) : super([]) {
    _loadCart();
  }

  // Load cart from storage on initialization
  Future<void> _loadCart() async {
    final cart = await _cartService.loadCart(_userId);
    state = cart;
  }

  // Save cart to storage after every change
  Future<void> _saveCart() async {
    await _cartService.saveCart(_userId, state);
  }

  void addToCart(Item item) async {
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
        await _saveCart();
      }
      // If we've reached max quantity, do nothing
    } else {
      // Item doesn't exist, add new cart item
      state = [...state, CartItem(item: item, quantity: 1)];
      await _saveCart();
    }
  }

  void removeFromCart(String itemId) async {
    state = state.where((cartItem) => cartItem.item.id != itemId).toList();
    await _saveCart();
  }

  void updateQuantity(String itemId, int quantity) async {
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
    await _saveCart();
  }

  void clearCart() async {
    state = [];
    await _cartService.clearCart(_userId);
  }

  // Merge local cart with Firestore when user logs in
  Future<void> syncCartOnLogin(String userId) async {
    final mergedCart = await _cartService.mergeAndSyncCarts(userId);
    state = mergedCart;
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
      final cartService = ref.watch(cartServiceProvider);
      final user = ref.watch(currentUserProvider);
      return CartController(cartService, user?.uid);
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
