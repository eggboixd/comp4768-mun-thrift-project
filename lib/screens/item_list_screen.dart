import 'package:comp4768_mun_thrift/screens/list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import 'bottom_nav_bar.dart';

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
        itemCount: 10, // Example count
        itemBuilder: (context, index) {
          return ListItem(
            image: NetworkImage('https://placehold.co/600x400.png'), // ImageProvider<Object>
            itemName: '$itemType Item ${index + 1}',
            price: 10.26,
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
