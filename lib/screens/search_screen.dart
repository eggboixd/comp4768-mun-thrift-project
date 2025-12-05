import 'dart:async';

import 'package:comp4768_mun_thrift/models/item.dart';
import 'package:comp4768_mun_thrift/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'list_item.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  String _query = '';
  ItemType? _selectedType;
  String? _selectedCategory;
  List<Item> _results = [];

  // Predefined categories (matching create_listing_screen)
  static const List<String> _categories = [
    'Clothing',
    'Electronics',
    'Books',
    'Furniture',
    'Sports & Outdoors',
    'Home & Garden',
    'Toys & Games',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        _isLoading = true;
      });
      try {
        final fs = ref.read(firestoreServiceProvider);
        final items = await fs.searchItems(
          query,
          type: _selectedType,
          category: _selectedCategory,
        );
        setState(() {
          _results = items;
        });
      } catch (e) {
        setState(() {
          _results = [];
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _query = value;
                _performSearch(value);
              },
              onSubmitted: (value) => _performSearch(value),
              decoration: InputDecoration(
                hintText: 'Search by title, description, or category',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = [];
                            _query = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ItemType?>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    isDense: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(
                        value: ItemType.free,
                        child: Text(ItemType.free.displayName),
                      ),
                      DropdownMenuItem(
                        value: ItemType.trade,
                        child: Text(ItemType.trade.displayName),
                      ),
                      DropdownMenuItem(
                        value: ItemType.buy,
                        child: Text(ItemType.buy.displayName),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val;
                      });
                      if (_controller.text.trim().isNotEmpty) {
                        _performSearch(_controller.text.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    isDense: true,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All', overflow: TextOverflow.ellipsis),
                      ),
                      ..._categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                      if (_controller.text.trim().isNotEmpty) {
                        _performSearch(_controller.text.trim());
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _query.trim().isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          const Text('Search for items'),
                        ],
                      ),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          const Text('No items found matching your search'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: (_results.length / 2).ceil(),
                      itemBuilder: (context, rowIndex) {
                        final firstIndex = rowIndex * 2;
                        final secondIndex = firstIndex + 1;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListItem(
                                image: NetworkImage(
                                  _results[firstIndex].primaryImageUrl,
                                ),
                                itemName: _results[firstIndex].title,
                                price: _results[firstIndex].price,
                                onTap: () {
                                  final type = _results[firstIndex].type.name;
                                  context.push(
                                    '/product/$type/${_results[firstIndex].id}',
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (secondIndex < _results.length)
                              Expanded(
                                child: ListItem(
                                  image: NetworkImage(
                                    _results[secondIndex].primaryImageUrl,
                                  ),
                                  itemName: _results[secondIndex].title,
                                  price: _results[secondIndex].price,
                                  onTap: () {
                                    final type =
                                        _results[secondIndex].type.name;
                                    context.push(
                                      '/product/$type/${_results[secondIndex].id}',
                                    );
                                  },
                                ),
                              )
                            else
                              const Expanded(child: SizedBox()),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
