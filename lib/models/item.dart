import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemType {
  free,
  trade,
  buy;

  String get displayName {
    switch (this) {
      case ItemType.free:
        return 'Free';
      case ItemType.trade:
        return 'Trade';
      case ItemType.buy:
        return 'Buy';
    }
  }

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => ItemType.free,
    );
  }
}

enum ItemCondition {
  new_,
  likeNew,
  good,
  fair,
  poor;

  String get displayName {
    switch (this) {
      case ItemCondition.new_:
        return 'New';
      case ItemCondition.likeNew:
        return 'Like New';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
    }
  }
}

class Item {
  final String id;
  final String title;
  final String description;
  final ItemType type;
  final double? price; // null for free items, optional for swap
  final List<String> imageUrls;
  final String userId; // owner of the item
  final String userEmail;
  final ItemCondition condition;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.price,
    required this.imageUrls,
    required this.userId,
    required this.userEmail,
    required this.condition,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable = true,
  });

  // Convert Item to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'price': price,
      'imageUrls': imageUrls,
      'userId': userId,
      'userEmail': userEmail,
      'condition': condition.name,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isAvailable': isAvailable,
    };
  }

  // Create Item from Firestore document
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ItemType.fromString(data['type'] ?? 'free'),
      price: data['price']?.toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      condition: ItemCondition.values.firstWhere(
        (c) => c.name == data['condition'],
        orElse: () => ItemCondition.good,
      ),
      category: data['category'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  // Helper to get the first image or placeholder
  String get primaryImageUrl {
    return imageUrls.isNotEmpty
        ? imageUrls.first
        : 'https://placehold.co/600x400.png';
  }

  // Create a copy with some fields changed
  Item copyWith({
    String? id,
    String? title,
    String? description,
    ItemType? type,
    double? price,
    List<String>? imageUrls,
    String? userId,
    String? userEmail,
    ItemCondition? condition,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
