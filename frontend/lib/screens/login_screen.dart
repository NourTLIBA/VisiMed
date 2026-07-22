import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  final _userCtrl = TextEditingController(text: 'medrep1');
  final _passCtrl = TextEditingController(text: 'med123');
  bool _busy = false;
  bool _obscure = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  late final AnimationController _floatCtrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _floatCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await widget.state.login(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeShell(state: widget.state)),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final isAuthError = msg.contains('400') ||
          msg.contains('401') ||
          msg.contains('Invalid') ||
          msg.contains('credentials');
      if (isAuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loginFailed),
            backgroundColor: AppTheme.KOLAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        if (widget.state.user.value != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeShell(state: widget.state)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: $msg'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _loginDemo(AppUser demoUser) {
    widget.state.loginDemo(demoUser);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeShell(state: widget.state)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1C18),
              AppTheme.primary,
              Color(0xFF1A3D30),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative Art Deco background sketch ──────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _ArtDecoBackgroundPainter(),
              ),
            ),

            // ── Corner ornament — top left ─────────────────────────
            Positioned(
              top: 0,
              left: 0,
              child: CustomPaint(
                size: Size(size.width * 0.45, size.height * 0.35),
                painter: _CornerOrnamentPainter(flip: false),
              ),
            ),

            // ── Corner ornament — bottom right ─────────────────────
            Positioned(
              bottom: 0,
              right: 0,
              child: Transform.rotate(
                angle: math.pi,
                child: CustomPaint(
                  size: Size(size.width * 0.45, size.height * 0.35),
                  painter: _CornerOrnamentPainter(flip: true),
                ),
              ),
            ),

            // ── Language selector ──────────────────────────────────
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: ValueListenableBuilder<Locale>(
                  valueListenable: widget.state.currentLocale,
                  builder: (context, _, __) =>
                      LanguageSelector(state: widget.state),
                ),
              ),
            ),

            // ── Main content ───────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ── Hero section ───────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(top: 48, bottom: 24),
                          child: Column(
                            children: [
                              // Floating logo with gold ring
                              AnimatedBuilder(
                                animation: _float,
                                builder: (ctx, child) => Transform.translate(
                                  offset: Offset(0, _float.value),
                                  child: child,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Gold decorative ring
                                    CustomPaint(
                                      size: const Size(130, 130),
                                      painter: _GoldRingPainter(),
                                    ),
                                    // Logo box
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                AppTheme.gold.withAlpha(80),
                                            blurRadius: 28,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 6),
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.black.withAlpha(60),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.local_hospital,
                                            size: 48,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Gold divider line
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoldLine(width: 32),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'VISIMED',
                                    style: TextStyle(
                                      color: AppTheme.gold,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _GoldLine(width: 32),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Field CRM  ·  Medical Intelligence',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Login card ─────────────────────────────
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          decoration: const BoxDecoration(
                            color: AppTheme.ricePaper,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(36),
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Art Deco top border accent
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: CustomPaint(
                                  size: const Size(double.infinity, 36),
                                  painter: _ArtDecoCardTopPainter(),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    28, 40, 28, 28),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Section title with sketch underline
                                    _SectionTitle(
                                      text: 'Welcome back',
                                      subtitle: 'Sign in to continue',
                                    ),
                                    const SizedBox(height: 24),

                                    // Username
                                    _SketchField(
                                      controller: _userCtrl,
                                      label: 'Username',
                                      icon: Icons.person_outline_rounded,
                                      action: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 14),

                                    // Password
                                    _SketchField(
                                      controller: _passCtrl,
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      obscure: _obscure,
                                      action: TextInputAction.done,
                                      onSubmit: _submit,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppTheme.primary
                                              .withAlpha(150),
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                            () => _obscure = !_obscure),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Sign-in button
                                    _ArtDecoButton(
                                      onTap: _busy ? null : _submit,
                                      busy: _busy,
                                      label: AppLocalizations.of(context)!
                                          .signIn,
                                    ),

                                    const SizedBox(height: 28),

                                    // Decorative divider
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Divider(
                                                color: AppTheme.primary
                                                    .withAlpha(30))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            '✦  DEMO ACCESS  ✦',
                                            style: TextStyle(
                                              fontSize: 10,
                                              letterSpacing: 1.5,
                                              color: AppTheme.primary
                                                  .withAlpha(120),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                            child: Divider(
                                                color: AppTheme.primary
                                                    .withAlpha(30))),
                                      ],
                                    ),

                                    const SizedBox(height: 14),

                                    // Demo quick-login
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.gold.withAlpha(80),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primary
                                                .withAlpha(8),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          _DemoButton(
                                            label: AppLocalizations.of(
                                                    context)!
                                                .roleAdmin,
                                            icon: Icons
                                                .admin_panel_settings_outlined,
                                            color: AppTheme.primary,
                                            onTap: () =>
                                                _loginDemo(kDemoAdmin),
                                          ),
                                          const SizedBox(height: 8),
                                          _DemoButton(
                                            label: AppLocalizations.of(
                                                    context)!
                                                .roleMedRep,
                                            icon: Icons
                                                .medical_services_outlined,
                                            color: AppTheme.jade,
                                            onTap: () =>
                                                _loginDemo(kDemoMedRep),
                                          ),
                                          const SizedBox(height: 8),
                                          _DemoButton(
                                            label: AppLocalizations.of(
                                                    context)!
                                                .rolePharmaRep,
                                            icon: Icons
                                                .local_pharmacy_outlined,
                                            color: AppTheme.pharmaceutical,
                                            onTap: () =>
                                                _loginDemo(kDemoPharmaRep),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Art Deco UI sub-widgets ───────────────────────────────────────────────────

class _GoldLine extends StatelessWidget {
  const _GoldLine({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 1.5,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, AppTheme.gold, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, required this.subtitle});
  final String text;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryDark,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primary.withAlpha(140),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.gold.withAlpha(160),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SketchField extends StatelessWidget {
  const _SketchField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.action = TextInputAction.next,
    this.onSubmit,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputAction action;
  final VoidCallback? onSubmit;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
      style: const TextStyle(
        color: AppTheme.primaryDark,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.jade, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.primary.withAlpha(40), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.primary.withAlpha(40), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.gold, width: 1.8),
        ),
        labelStyle: TextStyle(
            color: AppTheme.primary.withAlpha(160),
            fontSize: 14,
            fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(
            color: AppTheme.jade, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _ArtDecoButton extends StatelessWidget {
  const _ArtDecoButton(
      {required this.label, required this.onTap, required this.busy});
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF1E5940)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppTheme.gold, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Corner gold tick marks
            Positioned(
              left: 14,
              top: 8,
              child: _CornerTick(),
            ),
            Positioned(
              right: 14,
              bottom: 8,
              child: Transform.rotate(
                  angle: math.pi, child: _CornerTick()),
            ),
            // Label
            busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.ricePaper,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _CornerTick extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 10),
      painter: _TickPainter(),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color.withAlpha(14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(55), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: color.withAlpha(160)),
          ],
        ),
      ),
    );
  }
}

// ── Custom Painters ───────────────────────────────────────────────────────────

class _ArtDecoBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gold.withAlpha(14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Concentric arcs — top right
    for (int i = 1; i <= 5; i++) {
      final r = i * 55.0;
      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width, 0), radius: r),
        math.pi * 0.5,
        math.pi * 0.5,
        false,
        paint,
      );
    }

    // Fan lines from bottom left
    final fanPaint = Paint()
      ..color = AppTheme.gold.withAlpha(10)
      ..strokeWidth = 0.6;
    const origin = Offset(0, 0);
    for (int i = 0; i <= 8; i++) {
      final angle = (math.pi * 0.6 / 8) * i;
      final end = Offset(
        origin.dx + math.cos(angle) * size.width * 0.8,
        origin.dy + math.sin(angle) * size.height * 0.6,
      );
      canvas.drawLine(origin, end, fanPaint);
    }

    // Horizontal sketch lines bottom region
    final sketchPaint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 12; i++) {
      final y = size.height * 0.65 + i * 12.0;
      canvas.drawLine(
          Offset(size.width * 0.1, y), Offset(size.width * 0.9, y), sketchPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CornerOrnamentPainter extends CustomPainter {
  _CornerOrnamentPainter({required this.flip});
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gold.withAlpha(35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Art deco fan from corner
    final origin = Offset(0, 0);
    for (int i = 0; i <= 6; i++) {
      final angle = (math.pi * 0.45 / 6) * i;
      final len = size.width * (0.3 + i * 0.04);
      final end = Offset(
        origin.dx + math.cos(angle) * len,
        origin.dy + math.sin(angle) * len,
      );
      canvas.drawLine(origin, end, paint);
    }

    // Nested quarter circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: i * 38.0),
        0,
        math.pi * 0.45,
        false,
        paint..color = AppTheme.gold.withAlpha(25 - i * 6),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _GoldRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppTheme.gold.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, size.width / 2 - 2, paint);

    // Tick marks around ring
    final tickPaint = Paint()
      ..color = AppTheme.gold.withAlpha(120)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 12; i++) {
      final angle = (math.pi * 2 / 12) * i;
      final r1 = size.width / 2 - 2;
      final r2 = size.width / 2 - 8;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * r1,
            center.dy + math.sin(angle) * r1),
        Offset(center.dx + math.cos(angle) * r2,
            center.dy + math.sin(angle) * r2),
        tickPaint,
      );
    }

    // Inner dashed ring
    final dashPaint = Paint()
      ..color = AppTheme.gold.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, size.width / 2 - 14, dashPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ArtDecoCardTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gold.withAlpha(90)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Center diamond ornament
    final cx = size.width / 2;
    final cy = size.height * 0.5;
    final path = Path()
      ..moveTo(cx, cy - 7)
      ..lineTo(cx + 6, cy)
      ..lineTo(cx, cy + 7)
      ..lineTo(cx - 6, cy)
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill..color = AppTheme.gold.withAlpha(60));
    canvas.drawPath(path, paint..style = PaintingStyle.stroke..color = AppTheme.gold);

    // Lines from diamond outwards
    final linePaint = Paint()
      ..color = AppTheme.gold.withAlpha(60)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx - 60, cy), linePaint);
    canvas.drawLine(Offset(cx + 10, cy), Offset(cx + 60, cy), linePaint);
    canvas.drawLine(Offset(cx - 70, cy), Offset(20, cy), linePaint);
    canvas.drawLine(Offset(cx + 70, cy), Offset(size.width - 20, cy), linePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gold.withAlpha(200)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
