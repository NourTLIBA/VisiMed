import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

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
    return ValueListenableBuilder<Locale>(
      valueListenable: _state.currentLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'VisiMed',
          theme: AppTheme.light(),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr'),
            Locale('en'),
            Locale('ar'),
          ],
          home: LoginScreen(state: _state),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
