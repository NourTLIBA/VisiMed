import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  VisiMed Art-Deco design system
///
///  A small kit of geometric, symmetric, gold-lined building blocks so every
///  screen reads as one deliberate system instead of ad-hoc per-screen
///  painters (see inconsistencies.md §6.6).
/// ─────────────────────────────────────────────────────────────────────────────

class Deco {
  static const double radius = 14;

  static const LinearGradient forest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1C18), AppTheme.primary, Color(0xFF1A3D30)],
    stops: [0.0, 0.55, 1.0],
  );

  static BoxDecoration panel({Color? color, double? radius}) => BoxDecoration(
        color: color ?? AppTheme.cardBg,
        borderRadius: BorderRadius.circular(radius ?? Deco.radius),
        border: Border.all(color: AppTheme.gold.withAlpha(90), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      );

  static Color potentialColor(String p) {
    switch (p.toUpperCase()) {
      case 'KOL':
        return AppTheme.vermillion;
      case 'A':
        return AppTheme.gold;
      case 'B':
        return AppTheme.jade;
      default:
        return const Color(0xFF7C8B84);
    }
  }

  static Color severityColor(String s) {
    switch (s) {
      case 'high':
        return AppTheme.vermillion;
      case 'medium':
        return AppTheme.gold;
      default:
        return AppTheme.jade;
    }
  }

  static Color orderStatusColor(String s) {
    switch (s) {
      case 'confirmed':
        return AppTheme.jade;
      case 'delivered':
        return AppTheme.primary;
      case 'cancelled':
        return AppTheme.vermillion;
      default:
        return AppTheme.gold;
    }
  }
}

/// Full-bleed dark Art-Deco backdrop with corner sunbursts.
class DecoBackground extends StatelessWidget {
  const DecoBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Deco.forest),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SunburstPainter())),
          child,
        ],
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ray = Paint()
      ..color = AppTheme.gold.withAlpha(12)
      ..strokeWidth = 0.7;
    for (final origin in [Offset.zero, Offset(size.width, size.height)]) {
      final sign = origin == Offset.zero ? 1 : -1;
      for (int i = 0; i <= 9; i++) {
        final a = (math.pi * 0.5 / 9) * i;
        canvas.drawLine(
          origin,
          Offset(origin.dx + sign * math.cos(a) * size.width * 0.7,
              origin.dy + sign * math.sin(a) * size.height * 0.7),
          ray,
        );
      }
    }
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppTheme.gold.withAlpha(16);
    for (int i = 1; i <= 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width, 0), radius: i * 70.0),
        math.pi * 0.5,
        math.pi * 0.5,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Section header: gold tick + spaced caps + trailing gradient rule.
class DecoSectionTitle extends StatelessWidget {
  const DecoSectionTitle(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.gold.withAlpha(28),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.gold.withAlpha(110)),
            ),
            child: Icon(icon ?? Icons.diamond_outlined,
                size: 14, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.gold.withAlpha(150),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Card with a thin gold frame and optional inner-corner ticks.
class DecoCard extends StatelessWidget {
  const DecoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      decoration: Deco.panel(),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _CornerTicksPainter()),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
    if (onTap == null) return body;
    return InkWell(
      borderRadius: BorderRadius.circular(Deco.radius),
      onTap: onTap,
      child: body,
    );
  }
}

class _CornerTicksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.gold.withAlpha(120)
      ..strokeWidth = 1.2;
    const m = 8.0, l = 9.0;
    // four corners
    for (final c in [
      [const Offset(m, m), const Offset(m + l, m), const Offset(m, m + l)],
      [
        Offset(size.width - m, m),
        Offset(size.width - m - l, m),
        Offset(size.width - m, m + l)
      ],
      [
        Offset(m, size.height - m),
        Offset(m + l, size.height - m),
        Offset(m, size.height - m - l)
      ],
      [
        Offset(size.width - m, size.height - m),
        Offset(size.width - m - l, size.height - m),
        Offset(size.width - m, size.height - m - l)
      ],
    ]) {
      canvas.drawLine(c[0], c[1], p);
      canvas.drawLine(c[0], c[2], p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact KPI tile.
class DecoStat extends StatelessWidget {
  const DecoStat({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.icon,
    this.color,
    this.width,
  });
  final String label;
  final String value;
  final String? sub;
  final IconData? icon;
  final Color? color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: Deco.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.withAlpha(22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: c),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: c,
              height: 1,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 3),
            Text(sub!,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }
}

/// Circular gauge (0..1) with a spoked Art-Deco rim.
class DecoGauge extends StatelessWidget {
  const DecoGauge({
    super.key,
    required this.value,
    required this.label,
    this.centerText,
    this.color = AppTheme.gold,
    this.size = 120,
  });
  final double value;
  final String label;
  final String? centerText;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _GaugePainter(v, color),
            child: Center(
              child: Text(
                centerText ?? '${(v * 100).round()}%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.primary.withAlpha(20);
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = color;
    const start = -math.pi / 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), start,
        math.pi * 2, false, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), start,
        math.pi * 2 * value, false, prog);

    final tick = Paint()
      ..color = AppTheme.gold.withAlpha(120)
      ..strokeWidth = 1.4;
    for (int i = 0; i < 24; i++) {
      final a = (math.pi * 2 / 24) * i;
      final r1 = r + 7, r2 = r + (i % 6 == 0 ? 2 : 4);
      canvas.drawLine(
        Offset(center.dx + math.cos(a) * r1, center.dy + math.sin(a) * r1),
        Offset(center.dx + math.cos(a) * r2, center.dy + math.sin(a) * r2),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}

/// Labelled progress row with a framed bar.
class DecoBarRow extends StatelessWidget {
  const DecoBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.total,
    this.color = AppTheme.primary,
    this.valueLabel,
  });
  final String label;
  final num value;
  final num total;
  final Color color;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0).toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, color: color),
              const SizedBox(width: 9),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark)),
              ),
              Text(
                valueLabel ?? '$value',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(width: 4),
              Text('(${(pct * 100).round()}%)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: AppTheme.gold.withAlpha(70)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct == 0 ? 0.001 : pct,
                child: Container(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small framed pill.
class DecoChip extends StatelessWidget {
  const DecoChip(this.label,
      {super.key, this.color = AppTheme.primary, this.filled = false});
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withAlpha(18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(filled ? 255 : 90)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}
