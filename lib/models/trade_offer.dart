import 'package:cloud_firestore/cloud_firestore.dart';
import 'item.dart';

enum TradeOfferStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  String get displayName {
    switch (this) {
      case TradeOfferStatus.pending:
        return 'Pending';
      case TradeOfferStatus.accepted:
        return 'Accepted';
      case TradeOfferStatus.rejected:
        return 'Rejected';
      case TradeOfferStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class TradeOffer {
  final String id;
  final String requestedItemId; // The item the user wants to trade for
  final String requestedItemTitle;
  final String sellerId; // Owner of the requested item
  final String buyerId; // User making the trade offer
  final String buyerName;
  final String buyerEmail;

  // Offered item details
  final String offeredItemTitle;
  final String offeredItemDescription;
  final ItemCondition offeredItemCondition;
  final List<String> offeredItemImageUrls;

  // Trade details
  final String meetupLocation;
  final TradeOfferStatus status;
  final String?
  sellerResponse; // Optional message from seller when accepting/rejecting

  final DateTime createdAt;
  final DateTime updatedAt;

  TradeOffer({
    required this.id,
    required this.requestedItemId,
    required this.requestedItemTitle,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.offeredItemTitle,
    required this.offeredItemDescription,
    required this.offeredItemCondition,
    required this.offeredItemImageUrls,
    required this.meetupLocation,
    this.status = TradeOfferStatus.pending,
    this.sellerResponse,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'requestedItemId': requestedItemId,
      'requestedItemTitle': requestedItemTitle,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'offeredItemTitle': offeredItemTitle,
      'offeredItemDescription': offeredItemDescription,
      'offeredItemCondition': offeredItemCondition.name,
      'offeredItemImageUrls': offeredItemImageUrls,
      'meetupLocation': meetupLocation,
      'status': status.name,
      'sellerResponse': sellerResponse,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory TradeOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TradeOffer(
      id: doc.id,
      requestedItemId: data['requestedItemId'] ?? '',
      requestedItemTitle: data['requestedItemTitle'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      buyerEmail: data['buyerEmail'] ?? '',
      offeredItemTitle: data['offeredItemTitle'] ?? '',
      offeredItemDescription: data['offeredItemDescription'] ?? '',
      offeredItemCondition: ItemCondition.values.firstWhere(
        (c) => c.name == data['offeredItemCondition'],
        orElse: () => ItemCondition.good,
      ),
      offeredItemImageUrls: List<String>.from(
        data['offeredItemImageUrls'] ?? [],
      ),
      meetupLocation: data['meetupLocation'] ?? '',
      status: TradeOfferStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TradeOfferStatus.pending,
      ),
      sellerResponse: data['sellerResponse'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Helper to get primary image
  String get primaryOfferedItemImageUrl {
    return offeredItemImageUrls.isNotEmpty
        ? offeredItemImageUrls.first
        : 'https://placehold.co/600x400.png';
  }

  // Copy with
  TradeOffer copyWith({
    String? id,
    String? requestedItemId,
    String? requestedItemTitle,
    String? sellerId,
    String? buyerId,
    String? buyerName,
    String? buyerEmail,
    String? offeredItemTitle,
    String? offeredItemDescription,
    ItemCondition? offeredItemCondition,
    List<String>? offeredItemImageUrls,
    String? meetupLocation,
    TradeOfferStatus? status,
    String? sellerResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TradeOffer(
      id: id ?? this.id,
      requestedItemId: requestedItemId ?? this.requestedItemId,
      requestedItemTitle: requestedItemTitle ?? this.requestedItemTitle,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      offeredItemTitle: offeredItemTitle ?? this.offeredItemTitle,
      offeredItemDescription:
          offeredItemDescription ?? this.offeredItemDescription,
      offeredItemCondition: offeredItemCondition ?? this.offeredItemCondition,
      offeredItemImageUrls: offeredItemImageUrls ?? this.offeredItemImageUrls,
      meetupLocation: meetupLocation ?? this.meetupLocation,
      status: status ?? this.status,
      sellerResponse: sellerResponse ?? this.sellerResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
