import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../data/demo_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/language_selector.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.state});
  final AppState state;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController(text: 'medrep1');
  final _passCtrl = TextEditingController(text: 'med123');
  bool _busy = false;
  bool _obscure = true;

  late final AnimationController _introCtrl;
  late final Animation<double> _intro;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _intro = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic);
    _introCtrl.forward();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _goHome() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeShell(state: widget.state)));

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await widget.state.login(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      _goHome();
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final isAuthError = msg.contains('400') ||
          msg.contains('401') ||
          msg.contains('Invalid') ||
          msg.contains('credentials');
      if (!isAuthError && widget.state.user.value != null) {
        _goHome();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAuthError
              ? AppLocalizations.of(context)!.loginFailed
              : 'Connexion impossible : $msg'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _loginDemo(AppUser demoUser) {
    widget.state.loginDemo(demoUser);
    if (mounted) _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          // Warm ivory sheet occupying the lower two-thirds.
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.72,
              widthFactor: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(34)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: ValueListenableBuilder<Locale>(
                valueListenable: widget.state.currentLocale,
                builder: (_, __, ___) => LanguageSelector(state: widget.state),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: FadeTransition(
                    opacity: _intro,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _hero(),
                        const SizedBox(height: 34),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 28),
                              child: _card(l),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital,
                  size: 40, color: AppTheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'VisiMed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Suivi de la visite médicale',
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _card(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.rCard),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Bon retour',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink)),
          const SizedBox(height: 4),
          const Text('Connectez-vous pour continuer',
              style: TextStyle(fontSize: 13.5, color: AppTheme.inkMuted)),
          const SizedBox(height: 22),
          TextField(
            controller: _userCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: "Nom d'utilisateur",
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppTheme.inkFaint,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(l.signIn),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: Divider(color: AppTheme.hairline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Accès démo',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.inkFaint,
                        fontWeight: FontWeight.w500)),
              ),
              const Expanded(child: Divider(color: AppTheme.hairline)),
            ],
          ),
          const SizedBox(height: 14),
          _DemoButton(
            label: l.roleAdmin,
            icon: Icons.admin_panel_settings_outlined,
            color: AppTheme.primary,
            onTap: () => _loginDemo(kDemoAdmin),
          ),
          const SizedBox(height: 8),
          _DemoButton(
            label: l.roleMedRep,
            icon: Icons.medical_services_outlined,
            color: AppTheme.jade,
            onTap: () => _loginDemo(kDemoMedRep),
          ),
          const SizedBox(height: 8),
          _DemoButton(
            label: l.rolePharmaRep,
            icon: Icons.local_pharmacy_outlined,
            color: AppTheme.accent,
            onTap: () => _loginDemo(kDemoPharmaRep),
          ),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(16),
      borderRadius: BorderRadius.circular(AppTheme.rTile),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: color)),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded,
                  size: 15, color: color.withAlpha(150)),
            ],
          ),
        ),
      ),
    );
  }
}
