import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String content;
  final int rating;
  final DateTime createdAt;

  Review({
    required this.userId,
    required this.content,
    required this.rating,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      userId: json['userId'],
      content: json['content'],
      rating: json['rating'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'content': content,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert Firestore document to Review
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      rating: data['rating'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Convert Review to a Firestore map (use Timestamp for date)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
