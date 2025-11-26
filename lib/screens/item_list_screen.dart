import 'package:comp4768_mun_thrift/screens/list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import 'bottom_nav_bar.dart';

const itemCount = 10;

class ItemListScreen extends ConsumerWidget {
  final String itemType;
  const ItemListScreen({super.key, required this.itemType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MUN Thrift'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        // 2 items per row
        // Ceil to handle odd number of items
        itemCount: (itemCount / 2).ceil(),
        itemBuilder: (context, rowIndex) {
          // Calculate indices for the two items in the row
          final firstIndex = rowIndex * 2;
          final secondIndex = firstIndex + 1;
          return Row(
            children: [
              Expanded(
                child: ListItem(
                  image: NetworkImage('https://placehold.co/600x400.png'),
                  itemName: '$itemType Item ${firstIndex + 1}',
                  price: 10.26,
                ),
              ),
              const SizedBox(width: 16),
              if (secondIndex < itemCount)
                Expanded(
                  child: ListItem(
                    image: NetworkImage('https://placehold.co/600x400.png'),
                    itemName: '$itemType Item ${secondIndex + 1}',
                    price: 10.26,
                  ),
                )
              else
                Expanded(child: Container()), // empty space if odd count
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        // Determine current index based on itemType
        currentIndex: itemType == 'free'
            ? 0
            : itemType == 'swap'
            ? 1
            : 2,
      ),
    );
  }
}
