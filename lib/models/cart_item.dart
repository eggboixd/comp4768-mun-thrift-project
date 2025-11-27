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

  // Convert CartItem to JSON for persistence
  Map<String, dynamic> toJson() {
    return {'item': item.toJson(), 'quantity': quantity};
  }

  // Create CartItem from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      item: Item.fromMap(json['item'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }
}
