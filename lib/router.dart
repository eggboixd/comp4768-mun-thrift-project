import 'package:comp4768_mun_thrift/screens/product_page.dart';
import 'package:comp4768_mun_thrift/screens/edit_profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/item_list_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'controllers/user_info_controller.dart';

// GoRouter provider with auth redirect logic
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  // Watch user info for the current user if logged in
  final userId = authState.value?.uid;
  final userInfoAsync = userId != null
      ? ref.watch(userInfoControllerProvider(userId))
      : null;

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // If not logged in and not on login/signup pages, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login/signup pages, check user info
      if (isLoggedIn && isLoggingIn) {
        // If user info is not loaded or missing required fields, redirect to /profile/edit
        final userInfo = userInfoAsync?.value;
        final needsSetup =
            userInfo == null ||
            userInfo.name.isEmpty ||
            userInfo.address.isEmpty;
        if (needsSetup) {
          return '/profile/edit';
        }
        return '/free';
      }

      // If logged in and user info not set up, force to /profile/edit
      if (isLoggedIn && state.matchedLocation != '/profile/edit') {
        final userInfo = userInfoAsync?.value;
        final needsSetup =
            userInfo == null ||
            userInfo.name.isEmpty ||
            userInfo.address.isEmpty;
        if (needsSetup) {
          return '/profile/edit';
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      // Main item list routes
      // Matched routes for /free, /trade, /buy and passes itemType to ItemListScreen
      GoRoute(
        path: '/:type(free|trade|buy)',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'free';
          return ItemListScreen(itemType: type);
        },
      ),
      GoRoute(
        path: '/product/:type(free|trade|buy)/:id',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'free';
          final itemId = state.pathParameters['id']!;
          return ProductPage(id: itemId, itemType: type);
        },
      ),
      // Profile screen
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
});
