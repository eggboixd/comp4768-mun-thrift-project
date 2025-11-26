import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/item_list_screen.dart';
import 'screens/add_dummy_data_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';

// GoRouter provider with auth redirect logic
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

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

      // If logged in and on login/signup pages, redirect to home
      if (isLoggedIn && isLoggingIn) {
        return '/free';
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
      // Dummy data management screen
      GoRoute(
        path: '/add-dummy-data',
        builder: (context, state) => const AddDummyDataScreen(),
      ),
      // Profile screen
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
