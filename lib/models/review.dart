import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String? id;
  final String userId;
  final String content;
  final int rating;
  final String orderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    this.id,
    required this.userId,
    required this.content,
    required this.rating,
    required this.orderId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      rating: json['rating'],
      orderId: json['orderId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'content': content,
      'rating': rating,
      'orderId': orderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert Firestore document to Review
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      rating: data['rating'] ?? 0,
      orderId: data['orderId'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Convert Review to a Firestore map (use Timestamp for date)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'rating': rating,
      'orderId': orderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
