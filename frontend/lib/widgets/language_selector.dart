import 'package:flutter/material.dart';
import '../state/app_state.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, required this.state, this.color = Colors.white});

  final AppState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Locale>(
        value: state.currentLocale.value,
        icon: Icon(Icons.language, color: color, size: 20),
        dropdownColor: Theme.of(context).cardColor,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
        selectedItemBuilder: (context) {
          return const [
            Locale('fr'),
            Locale('en'),
            Locale('ar'),
          ].map((Locale locale) {
            return Center(
              child: Text(
                _getLanguageName(locale.languageCode),
                style: TextStyle(color: color),
              ),
            );
          }).toList();
        },
        items: const [
          DropdownMenuItem(
            value: Locale('fr'),
            child: Text('Français', style: TextStyle(color: Colors.black87)),
          ),
          DropdownMenuItem(
            value: Locale('en'),
            child: Text('English', style: TextStyle(color: Colors.black87)),
          ),
          DropdownMenuItem(
            value: Locale('ar'),
            child: Text('العربية', style: TextStyle(color: Colors.black87)),
          ),
        ],
        onChanged: (Locale? newLocale) {
          if (newLocale != null) {
            state.currentLocale.value = newLocale;
          }
        },
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr': return 'FR';
      case 'en': return 'EN';
      case 'ar': return 'AR';
      default: return code.toUpperCase();
    }
  }
}
