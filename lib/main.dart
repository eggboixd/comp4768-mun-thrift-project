import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes and save FCM token when user logs in
    _setupFCMTokenSaving();
  }

  void _setupFCMTokenSaving() {
    ref.listenManual(
      authStateChangesProvider,
      (previous, next) async {
        final user = next.value;
        if (user != null) {
          // User is logged in, save FCM token
          try {
            final notificationService = ref.read(notificationServiceProvider);
            final firestoreService = ref.read(firestoreServiceProvider);
            
            final token = await notificationService.getToken();
            if (token != null) {
              await firestoreService.saveFCMToken(user.uid, token);
              print('FCM Token saved for user ${user.uid}');
            }
          } catch (e) {
            print('Error saving FCM token: $e');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MUN Thrift',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF860134),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
