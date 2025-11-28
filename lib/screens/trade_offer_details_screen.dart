import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comp4768_mun_thrift/models/item.dart';
import 'package:comp4768_mun_thrift/services/auth_service.dart';
import 'package:comp4768_mun_thrift/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TradeOfferDetailsScreen extends ConsumerStatefulWidget {
  final String tradeOfferId;

  const TradeOfferDetailsScreen({super.key, required this.tradeOfferId});

  @override
  ConsumerState<TradeOfferDetailsScreen> createState() =>
      _TradeOfferDetailsScreenState();
}

class _TradeOfferDetailsScreenState
    extends ConsumerState<TradeOfferDetailsScreen> {
  final _responseController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _acceptOffer() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Get trade offer details
      final offerData = await firestoreService.getTradeOfferById(
        widget.tradeOfferId,
      );
      if (offerData == null) {
        throw Exception('Trade offer not found');
      }

      // Update trade offer status
      await firestoreService.updateTradeOfferStatus(
        offerId: widget.tradeOfferId,
        status: 'accepted',
        sellerResponse: _responseController.text.trim().isNotEmpty
            ? _responseController.text.trim()
            : null,
      );

      // Create notification for buyer
      final acceptMessage = _responseController.text.trim().isNotEmpty
          ? _responseController.text.trim()
          : 'Your trade offer has been accepted!';

      await firestoreService.createNotification(
        userId: offerData['buyerId'] as String,
        type: 'tradeAccepted',
        title: 'Trade Offer Accepted',
        message: acceptMessage,
        tradeOfferId: widget.tradeOfferId,
        fromUserId: offerData['sellerId'] as String,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trade offer accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectOffer() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Get trade offer details
      final offerData = await firestoreService.getTradeOfferById(
        widget.tradeOfferId,
      );
      if (offerData == null) {
        throw Exception('Trade offer not found');
      }

      // Update trade offer status
      await firestoreService.updateTradeOfferStatus(
        offerId: widget.tradeOfferId,
        status: 'rejected',
        sellerResponse: _responseController.text.trim().isNotEmpty
            ? _responseController.text.trim()
            : null,
      );

      // Create notification for buyer
      final rejectMessage = _responseController.text.trim().isNotEmpty
          ? _responseController.text.trim()
          : 'Your trade offer has been rejected.';

      await firestoreService.createNotification(
        userId: offerData['buyerId'] as String,
        type: 'tradeRejected',
        title: 'Trade Offer Rejected',
        message: rejectMessage,
        tradeOfferId: widget.tradeOfferId,
        fromUserId: offerData['sellerId'] as String,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trade offer rejected.'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Trade Offer Details')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: ref
            .read(firestoreServiceProvider)
            .getTradeOfferById(widget.tradeOfferId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final offerData = snapshot.data;
          if (offerData == null) {
            return const Center(child: Text('Trade offer not found'));
          }

          // Parse trade offer data
          final status = offerData['status'] as String? ?? 'pending';
          final offeredItemTitle =
              offerData['offeredItemTitle'] as String? ?? '';
          final offeredItemDescription =
              offerData['offeredItemDescription'] as String? ?? '';
          final offeredItemCondition = ItemCondition.values.firstWhere(
            (c) => c.name == offerData['offeredItemCondition'],
            orElse: () => ItemCondition.good,
          );
          final offeredItemImages = List<String>.from(
            offerData['offeredItemImageUrls'] ?? [],
          );
          final meetupLocation = offerData['meetupLocation'] as String? ?? '';
          final buyerName = offerData['buyerName'] as String? ?? '';
          final requestedItemTitle =
              offerData['requestedItemTitle'] as String? ?? '';
          final createdAt = (offerData['createdAt'] as Timestamp?)?.toDate();
          final sellerResponse = offerData['sellerResponse'] as String?;
          final sellerId = offerData['sellerId'] as String? ?? '';

          final isSeller = user != null && user.uid == sellerId;
          final isPending = status == 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'accepted'
                        ? Colors.green
                        : status == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Trade info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From: $buyerName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wants to trade for: $requestedItemTitle',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Submitted: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Offered item details
                const Text(
                  'Offering:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Images
                if (offeredItemImages.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: offeredItemImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              offeredItemImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offeredItemTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Condition: ${offeredItemCondition.displayName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Description:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(offeredItemDescription),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Meetup: $meetupLocation',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Seller response if exists
                if (sellerResponse != null && sellerResponse.isNotEmpty) ...[
                  const Text(
                    'Seller Response:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(sellerResponse),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons for seller if pending
                if (isSeller && isPending) ...[
                  const Text(
                    'Your Response (Optional):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _responseController,
                    decoration: const InputDecoration(
                      hintText: 'Add a message to the buyer...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _acceptOffer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _rejectOffer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
