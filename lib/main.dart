import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:popgrid/core/theme/app_theme.dart';
import 'package:popgrid/features/home/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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
