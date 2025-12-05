import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';

// Provider for Firestore instance scoped to reviews
final reviewsFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

class ReviewsService {
  final FirebaseFirestore _firestore;
  ReviewsService(this._firestore);

  // Reference to top-level `reviews` collection
  CollectionReference get _reviewsCollection =>
      _firestore.collection('reviews');

  // Get subcollection reference for a single user's reviews
  CollectionReference _userReviewsCollection(String userId) {
    return _reviewsCollection.doc(userId).collection('userReviews');
  }

  // Add a review for a given user (the doc id is set by Firestore)
  Future<String> addReview(String userId, Review review) async {
    try {
      final map = review.toMap();
      // ensure createdAt is server timestamp if not provided
      if (map['createdAt'] == null) {
        map['createdAt'] = FieldValue.serverTimestamp();
      }
      if (map['updatedAt'] == null) {
        map['updatedAt'] = FieldValue.serverTimestamp();
      }
      final docRef = await _userReviewsCollection(userId).add(map);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Get a review by id for a specific user
  Future<Review?> getReviewById(String userId, String reviewId) async {
    try {
      final doc = await _userReviewsCollection(userId).doc(reviewId).get();
      if (doc.exists) {
        return Review.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get review: $e');
    }
  }

  // Get a review by orderId for a specific user
  Future<Review?> getReviewByOrderId(String userId, String orderId) async {
    try {
      final querySnapshot = await _userReviewsCollection(userId)
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return Review.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get review by orderId: $e');
    }
  }

  // Stream of reviews for a user (real-time updates)
  Stream<List<Review>> getReviewsForUser(String userId) {
    return _userReviewsCollection(
      userId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  // Update a review
  Future<void> updateReview(
    String userId,
    String reviewId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Allow updating content, rating, or other fields as needed
      if (updates.containsKey('updatedAt')) {
        final v = updates['updatedAt'];
        if (v is DateTime) {
          updates['updatedAt'] = Timestamp.fromDate(v);
        }
      }
      if (updates.containsKey('createdAt')) {
        updates.remove('createdAt');
      }
      await _userReviewsCollection(userId).doc(reviewId).update(updates);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String userId, String reviewId) async {
    try {
      await _userReviewsCollection(userId).doc(reviewId).delete();
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
}

// Provider for ReviewsService
final reviewsServiceProvider = Provider<ReviewsService>((ref) {
  return ReviewsService(ref.watch(reviewsFirestoreProvider));
});

// Stream provider to watch reviews for a user
final userReviewsProvider = StreamProvider.family<List<Review>, String>((
  ref,
  userId,
) {
  final service = ref.watch(reviewsServiceProvider);
  return service.getReviewsForUser(userId);
});

// Future provider to get a single review by id
final reviewByIdProvider = FutureProvider.family
    .autoDispose<Review?, (String, String)>((ref, params) {
      final service = ref.watch(reviewsServiceProvider);
      final userId = params.$1;
      final reviewId = params.$2;
      return service.getReviewById(userId, reviewId);
    });

final reviewByOrderIdProvider = FutureProvider.family
    .autoDispose<Review?, (String, String)>((ref, params) {
      final service = ref.watch(reviewsServiceProvider);
      final userId = params.$1;
      final orderId = params.$2;
      return service.getReviewByOrderId(userId, orderId);
    });