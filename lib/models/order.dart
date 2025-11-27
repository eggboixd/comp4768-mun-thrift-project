import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderItem {
  final String itemId;
  final String itemTitle;
  final String itemImageUrl;
  final double itemPrice;
  final int quantity;
  final String sellerId;

  OrderItem({
    required this.itemId,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.itemPrice,
    required this.quantity,
    required this.sellerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemTitle': itemTitle,
      'itemImageUrl': itemImageUrl,
      'itemPrice': itemPrice,
      'quantity': quantity,
      'sellerId': sellerId,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemId: map['itemId'] ?? '',
      itemTitle: map['itemTitle'] ?? '',
      itemImageUrl: map['itemImageUrl'] ?? '',
      itemPrice: (map['itemPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      sellerId: map['sellerId'] ?? '',
    );
  }
}

class Order {
  final String? id;
  final String buyerId;
  final List<OrderItem> items;
  final List<String> sellerIds;
  final double totalAmount;
  final String deliveryName;
  final String deliveryAddress;
  final String deliveryPhone;
  final String? notes;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    this.id,
    required this.buyerId,
    required this.items,
    required this.sellerIds,
    required this.totalAmount,
    required this.deliveryName,
    required this.deliveryAddress,
    required this.deliveryPhone,
    this.notes,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'items': items.map((item) => item.toMap()).toList(),
      'sellerIds': sellerIds,
      'totalAmount': totalAmount,
      'deliveryName': deliveryName,
      'deliveryAddress': deliveryAddress,
      'deliveryPhone': deliveryPhone,
      'notes': notes,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      sellerIds:
          (data['sellerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryName: data['deliveryName'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryPhone: data['deliveryPhone'] ?? '',
      notes: data['notes'],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Order copyWith({
    String? id,
    String? buyerId,
    List<OrderItem>? items,
    List<String>? sellerIds,
    double? totalAmount,
    String? deliveryName,
    String? deliveryAddress,
    String? deliveryPhone,
    String? notes,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      items: items ?? this.items,
      sellerIds: sellerIds ?? this.sellerIds,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryName: deliveryName ?? this.deliveryName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
