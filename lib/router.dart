import 'package:comp4768_mun_thrift/screens/chat_list_screen.dart';
import 'package:comp4768_mun_thrift/screens/chat_screen.dart';
import 'package:comp4768_mun_thrift/screens/external_profile_screen.dart';
import 'package:comp4768_mun_thrift/screens/product_page.dart';
import 'package:comp4768_mun_thrift/screens/edit_profile_screen.dart';
import 'package:comp4768_mun_thrift/screens/forgot_password_screen.dart';
import 'package:comp4768_mun_thrift/screens/cart_screen.dart';
import 'package:comp4768_mun_thrift/screens/checkout_screen.dart';
import 'package:comp4768_mun_thrift/screens/create_listing_screen.dart';
import 'package:comp4768_mun_thrift/screens/notifications_screen.dart';
import 'package:comp4768_mun_thrift/screens/seller_orders_screen.dart';
import 'package:comp4768_mun_thrift/screens/trade_offer_screen.dart';
import 'package:comp4768_mun_thrift/screens/trade_offer_details_screen.dart';
import 'package:comp4768_mun_thrift/screens/order_history_screen.dart';
import 'package:comp4768_mun_thrift/screens/order_details_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/search_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/item_list_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';

// GoRouter provider with auth redirect logic
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      // If not logged in, force to login page
      if (!isLoggedIn) {
        return isOnAuthPage ? null : '/login';
      }

      // If logged in and on auth pages, redirect to home
      if (isLoggedIn && isOnAuthPage) {
        return '/free';
      }

      // Allow all other navigation
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Trade offer routes (must come before /:type route to avoid conflicts)
      GoRoute(
        path: '/trade-offer/:itemId',
        builder: (context, state) {
          final itemId = state.pathParameters['itemId']!;
          final extra = state.extra as Map<String, dynamic>;
          return TradeOfferScreen(
            requestedItemId: itemId,
            requestedItemTitle: extra['requestedItemTitle'] as String,
            sellerId: extra['sellerId'] as String,
          );
        },
      ),
      GoRoute(
        path: '/trade-offer-details/:offerId',
        builder: (context, state) {
          final offerId = state.pathParameters['offerId']!;
          return TradeOfferDetailsScreen(tradeOfferId: offerId);
        },
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
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/product/:type(free|trade|buy)/:id',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'free';
          final itemId = state.pathParameters['id']!;
          return ProductPage(id: itemId, itemType: type);
        },
      ),
      // Cart routes
      GoRoute(
        path: '/cart/:type(free|trade|buy)',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'free';
          return CartScreen(itemType: type);
        },
      ),
      GoRoute(
        path: '/checkout/:type(free|trade|buy)',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'free';
          return CheckoutScreen(itemType: type);
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
      GoRoute(
        path: '/profile/create-listing',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/profile/create-listing/edit/:itemId',
        builder: (context, state) {
          final itemId = state.pathParameters['itemId']!;
          return CreateListingScreen(editItemId: itemId);
        },
      ),
      GoRoute(
        path: '/profile/external/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ExternalProfileScreen(userId: userId);
        },
      ),
      // Notifications and orders
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/seller-orders',
        builder: (context, state) => const SellerOrdersScreen(),
      ),
      GoRoute(
        path: '/order-history',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/order-details/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailsScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/chat-list',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:otherUserId',
        builder: (context, state) {
          final otherUserId = state.pathParameters['otherUserId']!;
          return ChatScreen(otherUserId: otherUserId);
        },
      ),
    ],
  );
});
