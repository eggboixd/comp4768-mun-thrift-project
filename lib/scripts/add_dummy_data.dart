import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';

/// Script to add dummy data to Firestore
/// This creates sample items for free, swap, and buy categories
///
/// Usage:
/// 1. User must be signed in (items are associated with current user)
/// 2. Call addDummyItems() to create 15 sample items (4 free, 4 swap, 7 buy)
/// 3. Call clearAllItems() to delete all items from database
///
/// Access via UI: Tap settings icon (⚙️) on item list screen
class DummyDataService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DummyDataService(this._firestore, this._auth);

  Future<void> addDummyItems() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in. Please sign in first.');
    }

    final userId = user.uid;
    final userEmail = user.email ?? 'test@example.com';

    final dummyItems = [
      // Free Items
      Item(
        id: '',
        title: 'Free Textbook - Biology 101',
        description:
            'Gently used biology textbook from first year. No longer needed!',
        type: ItemType.free,
        price: null,
        imageUrls: ['https://picsum.photos/seed/bio/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.good,
        category: 'Books',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Free Winter Coat',
        description:
            'Women\'s winter coat, size M. Moving and can\'t take it with me.',
        type: ItemType.free,
        price: null,
        imageUrls: ['https://picsum.photos/seed/coat/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.likeNew,
        category: 'Clothing',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Free Study Lamp',
        description: 'Desk lamp with adjustable arm. Works perfectly!',
        type: ItemType.free,
        price: null,
        imageUrls: ['https://picsum.photos/seed/lamp/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.good,
        category: 'Furniture',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Free Notebooks (Pack of 5)',
        description:
            'Brand new notebooks, never used. Got extras from bookstore.',
        type: ItemType.free,
        price: null,
        imageUrls: ['https://picsum.photos/seed/notebooks/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.new_,
        category: 'Stationery',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isAvailable: true,
      ),

      // Trade Items
      Item(
        id: '',
        title: 'Trade: Calculus Textbook',
        description:
            'Looking to trade for Chemistry textbook. Excellent condition.',
        type: ItemType.trade,
        price: null,
        imageUrls: ['https://picsum.photos/seed/calculus/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.likeNew,
        category: 'Books',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Trade: Men\'s Sneakers (Size 10)',
        description:
            'Nike sneakers in great condition. Open to trades for similar size.',
        type: ItemType.trade,
        price: 80.0,
        imageUrls: ['https://picsum.photos/seed/sneakers/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.good,
        category: 'Shoes',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        updatedAt: DateTime.now().subtract(const Duration(days: 6)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Trade: Bluetooth Speaker',
        description: 'JBL Flip 5. Looking to trade for headphones or earbuds.',
        type: ItemType.trade,
        price: 60.0,
        imageUrls: ['https://picsum.photos/seed/speaker/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.likeNew,
        category: 'Electronics',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Trade: MUN Hoodie',
        description: 'Size L MUN hoodie. Trade for size M or different design.',
        type: ItemType.trade,
        price: 45.0,
        imageUrls: ['https://picsum.photos/seed/hoodie/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.good,
        category: 'Clothing',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        isAvailable: true,
      ),

      // Buy Items
      Item(
        id: '',
        title: 'Laptop Stand - \$25',
        description: 'Aluminum laptop stand. Adjustable height. Like new!',
        type: ItemType.buy,
        price: 25.0,
        imageUrls: ['https://picsum.photos/seed/laptopstand/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.likeNew,
        category: 'Electronics',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Mini Fridge - \$80',
        description: 'Compact fridge perfect for dorm room. Works perfectly!',
        type: ItemType.buy,
        price: 80.0,
        imageUrls: ['https://picsum.photos/seed/fridge/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.good,
        category: 'Appliances',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Study Desk - \$50',
        description: 'Solid wood desk with drawer. Must pick up.',
        type: ItemType.buy,
        price: 50.0,
        imageUrls: ['https://picsum.photos/seed/desk/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.good,
        category: 'Furniture',
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
        updatedAt: DateTime.now().subtract(const Duration(days: 9)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Gaming Keyboard - \$35',
        description:
            'Mechanical keyboard with RGB lighting. All keys work perfectly.',
        type: ItemType.buy,
        price: 35.0,
        imageUrls: ['https://picsum.photos/seed/keyboard/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.good,
        category: 'Electronics',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Winter Boots - \$40',
        description: 'Women\'s waterproof winter boots, size 8. Barely worn.',
        type: ItemType.buy,
        price: 40.0,
        imageUrls: ['https://picsum.photos/seed/boots/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.likeNew,
        category: 'Shoes',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Coffee Maker - \$20',
        description: 'Single-serve coffee maker. Great for students!',
        type: ItemType.buy,
        price: 20.0,
        imageUrls: ['https://picsum.photos/seed/coffee/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.good,
        category: 'Appliances',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        isAvailable: true,
      ),
      Item(
        id: '',
        title: 'Backpack - \$30',
        description:
            'Durable backpack with laptop compartment. Perfect for classes.',
        type: ItemType.buy,
        price: 30.0,
        imageUrls: ['https://picsum.photos/seed/backpack/600/400'],
        userId: userId,
        userEmail: userEmail,
        condition: ItemCondition.likeNew,
        category: 'Accessories',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        isAvailable: true,
      ),
    ];

    print('Starting to add ${dummyItems.length} dummy items...');

    int successCount = 0;
    int failCount = 0;

    for (var item in dummyItems) {
      try {
        await _firestore.collection('items').add(item.toMap());
        successCount++;
        print('✓ Added: ${item.title}');
      } catch (e) {
        failCount++;
        print('✗ Failed to add ${item.title}: $e');
      }
    }

    print('\n✅ Dummy data added successfully!');
    print('Success: $successCount items');
    print('Failed: $failCount items');
  }

  // Clear all items (useful for testing)
  Future<void> clearAllItems() async {
    print('Clearing all items...');
    final snapshot = await _firestore.collection('items').get();

    int count = 0;
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
      count++;
    }

    print('✅ Cleared $count items from database.');
  }
}
