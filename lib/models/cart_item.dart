import 'package:comp4768_mun_thrift/models/item.dart';

class CartItem {
  final Item item;
  final int quantity;

  CartItem({required this.item, this.quantity = 1});

  CartItem copyWith({Item? item, int? quantity}) {
    return CartItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice {
    return (item.price ?? 0) * quantity;
  }
}
