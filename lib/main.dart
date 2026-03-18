import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:popgrid/core/services/ad_service.dart';
import 'package:popgrid/core/services/auth_service.dart';
import 'package:popgrid/core/theme/app_theme.dart';
import 'package:popgrid/features/home/screens/home_screen.dart';
import 'package:popgrid/features/online/services/online_game_service.dart';
import 'package:popgrid/firebase_options.dart';

final getIt = GetIt.instance;

void _setupLocator() {
  getIt.registerLazySingleton<AdService>(() => AdService());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<OnlineGameService>(() => OnlineGameService(
        firestore: FirebaseFirestore.instance,
        authService: getIt<AuthService>(),
      ));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  _setupLocator();

  // Initialize services in parallel
  final adService = getIt<AdService>();
  final authService = getIt<AuthService>();

  await Future.wait([
    adService.initialize(),
    authService.initialize(),
  ]);

  // Fire-and-forget preloads
  adService.preloadInterstitial();
  adService.preloadRewarded();

  runApp(const PopGridApp());
}

class PopGridApp extends StatelessWidget {
  const PopGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PopGrid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
