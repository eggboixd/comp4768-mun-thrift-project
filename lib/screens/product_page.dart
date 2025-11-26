import 'package:comp4768_mun_thrift/controllers/item_controller.dart';
import 'package:comp4768_mun_thrift/screens/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductPage extends ConsumerWidget {
  final String id;
  final String itemType;

  const ProductPage({
    Key? key,
    required this.id,
    required this.itemType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdControllerProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text('Product Page')),
      body: itemAsync.when(
        data: (item) => Center(child: Text('Product Title: ${item?.title}')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: itemType == 'free' ? 0 : itemType == 'trade' ? 1 : 2),
    );
  }
}
