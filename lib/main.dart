import 'package:flutter/material.dart';

import 'package:pakiti_app/screens/account/start_screen.dart';
import 'package:pakiti_app/theme/app_theme.dart';

void main() {
  runApp(const PakitiApp());
}

class PakitiApp extends StatelessWidget {
  const PakitiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pakiti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const StartScreen(),
    );
  }
}
