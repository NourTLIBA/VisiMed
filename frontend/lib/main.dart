import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const VisiMedApp());
}

class VisiMedApp extends StatefulWidget {
  const VisiMedApp({super.key});

  @override
  State<VisiMedApp> createState() => _VisiMedAppState();
}

class _VisiMedAppState extends State<VisiMedApp> {
  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisiMed',
      theme: AppTheme.light(),
      home: LoginScreen(state: _state),
      debugShowCheckedModeBanner: false,
    );
  }
}
