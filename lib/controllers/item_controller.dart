import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';

// Hive box name for caching items
const String itemsBoxName = 'items_cache';

// Provider for Hive box
final itemsBoxProvider = FutureProvider<Box<Map>>((ref) async {
  return await Hive.openBox<Map>(itemsBoxName);
});

// Item Controller class
class ItemController extends StateNotifier<AsyncValue<List<Item>>> {
  final FirestoreService _firestoreService;
  final Box<Map>? _cacheBox;

  ItemController(this._firestoreService, this._cacheBox)
    : super(const AsyncValue.loading());

  // Load items by type with caching
  Future<void> loadItemsByType(ItemType type) async {
    state = const AsyncValue.loading();

    try {
      // Try to load from cache first
      if (_cacheBox != null) {
        final cachedData = _cacheBox.get('items_${type.name}');
        if (cachedData != null) {
          final cachedItems = (cachedData['items'] as List)
              .map(
                (itemMap) => Item.fromFirestore(
                  _createMockDocumentSnapshot(
                    itemMap['id'],
                    Map<String, dynamic>.from(itemMap),
                  ),
                ),
              )
              .toList();
          state = AsyncValue.data(cachedItems);
        }
      }

      // Listen to Firestore stream
      _firestoreService
          .getItemsByType(type)
          .listen(
            (items) {
              state = AsyncValue.data(items);

              // Cache the data
              if (_cacheBox != null) {
                _cacheBox.put('items_${type.name}', {
                  'items': items
                      .map((item) => {'id': item.id, ...item.toMap()})
                      .toList(),
                  'timestamp': DateTime.now().toIso8601String(),
                });
              }
            },
            onError: (error, stackTrace) {
              state = AsyncValue.error(error, stackTrace);
            },
          );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Load all items
  Future<void> loadAllItems() async {
    state = const AsyncValue.loading();

    try {
      // Try to load from cache first
      if (_cacheBox != null) {
        final cachedData = _cacheBox.get('items_all');
        if (cachedData != null) {
          final cachedItems = (cachedData['items'] as List)
              .map(
                (itemMap) => Item.fromFirestore(
                  _createMockDocumentSnapshot(
                    itemMap['id'],
                    Map<String, dynamic>.from(itemMap),
                  ),
                ),
              )
              .toList();
          state = AsyncValue.data(cachedItems);
        }
      }

      // Listen to Firestore stream
      _firestoreService.getAllItems().listen(
        (items) {
          state = AsyncValue.data(items);

          // Cache the data
          if (_cacheBox != null) {
            _cacheBox.put('items_all', {
              'items': items
                  .map((item) => {'id': item.id, ...item.toMap()})
                  .toList(),
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        },
        onError: (error, stackTrace) {
          state = AsyncValue.error(error, stackTrace);
        },
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    await _cacheBox?.clear();
  }

  // Helper to create a mock DocumentSnapshot for cached items
  dynamic _createMockDocumentSnapshot(String id, Map<String, dynamic> data) {
    return _MockDocumentSnapshot(id, data);
  }
}

// Mock DocumentSnapshot for cached data
class _MockDocumentSnapshot {
  final String id;
  final Map<String, dynamic> _data;

  _MockDocumentSnapshot(this.id, this._data);

  Map<String, dynamic>? data() => _data;
  bool get exists => true;
}

// Provider for ItemController by type
final itemControllerProvider =
    StateNotifierProvider.family<
      ItemController,
      AsyncValue<List<Item>>,
      ItemType
    >((ref, type) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      final cacheBoxAsync = ref.watch(itemsBoxProvider);
      final cacheBox = cacheBoxAsync.value;

      final controller = ItemController(firestoreService, cacheBox);
      controller.loadItemsByType(type);
      return controller;
    });

// Provider for all items controller
final allItemsControllerProvider =
    StateNotifierProvider<ItemController, AsyncValue<List<Item>>>((ref) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      final cacheBoxAsync = ref.watch(itemsBoxProvider);
      final cacheBox = cacheBoxAsync.value;

      final controller = ItemController(firestoreService, cacheBox);
      controller.loadAllItems();
      return controller;
    });

// Controller for single item by ID
class ItemByIdController extends StateNotifier<AsyncValue<Item?>> {
  final FirestoreService _firestoreService;

  ItemByIdController(this._firestoreService)
    : super(const AsyncValue.loading());

  Future<void> loadItemById(String itemId) async {
    state = const AsyncValue.loading();
    try {
      final item = await _firestoreService.getItemById(itemId);
      state = AsyncValue.data(item);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Provider for single item by ID
final itemByIdControllerProvider =
    StateNotifierProvider.family<ItemByIdController, AsyncValue<Item?>, String>(
      (ref, itemId) {
        final firestoreService = ref.watch(firestoreServiceProvider);
        final controller = ItemByIdController(firestoreService);
        controller.loadItemById(itemId);
        return controller;
      },
    );
