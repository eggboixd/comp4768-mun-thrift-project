import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_info.dart';
import '../services/firestore_service.dart';

// Hive box name for caching user info
const String userInfoBoxName = 'user_info_cache';

// Provider for Hive box
final userInfoBoxProvider = FutureProvider<Box<Map>>((ref) async {
	return await Hive.openBox<Map>(userInfoBoxName);
});

// UserInfo Controller class
class UserInfoController extends StateNotifier<AsyncValue<UserInfo?>> {
	final FirestoreService _firestoreService;
	final Box<Map>? _cacheBox;

	UserInfoController(this._firestoreService, this._cacheBox)
			: super(const AsyncValue.loading());

	// Load user info with caching
	Future<void> loadUserInfo(String userId) async {
		state = const AsyncValue.loading();

		try {
			// Try to load from cache first
			if (_cacheBox != null) {
				final cachedData = _cacheBox.get('user_$userId');
				if (cachedData != null) {
					final cachedUser = UserInfo(
						id: userId,
						name: cachedData['name'] ?? '',
						address: cachedData['address'] ?? '',
						about: cachedData['about'],
						profileImageUrl: cachedData['profileImageUrl'] ?? '',
					);
					state = AsyncValue.data(cachedUser);
				}
			}

			// Load from Firestore
			final userInfo = await _firestoreService.getUserInfo(userId);
			state = AsyncValue.data(userInfo);

			// Cache the data
			if (_cacheBox != null && userInfo != null) {
				_cacheBox.put('user_$userId', {
					'name': userInfo.name,
					'address': userInfo.address,
					'about': userInfo.about,
					'profileImageUrl': userInfo.profileImageUrl,
					'timestamp': DateTime.now().toIso8601String(),
				});
			}
		} catch (error, stackTrace) {
			state = AsyncValue.error(error, stackTrace);
		}
	}

	// Update user info
	Future<void> updateUserInfo(String userId, UserInfo updates) async {
		state = const AsyncValue.loading();
		try {
			await _firestoreService.updateUserInfo(userId, updates);
			await loadUserInfo(userId); // Refresh state and cache
		} catch (error, stackTrace) {
			state = AsyncValue.error(error, stackTrace);
		}
	}

	// Save user info (create or merge)
	Future<void> saveUserInfo(String userId, UserInfo userInfo) async {
		state = const AsyncValue.loading();
		try {
			await _firestoreService.saveUserInfo(userId, userInfo);
			await loadUserInfo(userId); // Refresh state and cache
		} catch (error, stackTrace) {
			state = AsyncValue.error(error, stackTrace);
		}
	}

	// Clear cache
	Future<void> clearCache() async {
		await _cacheBox?.clear();
	}
}

// Provider for UserInfoController
final userInfoControllerProvider = StateNotifierProvider.family<
		UserInfoController,
		AsyncValue<UserInfo?>,
		String>((ref, userId) {
	final firestoreService = ref.watch(firestoreServiceProvider);
	final cacheBoxAsync = ref.watch(userInfoBoxProvider);
	final cacheBox = cacheBoxAsync.value;

	final controller = UserInfoController(firestoreService, cacheBox);
	controller.loadUserInfo(userId);
	return controller;
});