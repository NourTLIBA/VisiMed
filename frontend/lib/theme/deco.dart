import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  VisiMed shared UI kit
///
///  A small set of soft, quiet building blocks so every screen reads as one
///  system: white panels on warm ivory, a single diffuse shadow, no outlines,
///  full-pill chips, sentence-case section headers. Class names are kept stable
///  so screens need no structural change to adopt the refreshed look.
/// ─────────────────────────────────────────────────────────────────────────────

class Deco {
  static const double radius = AppTheme.rCard;

  /// Gentle brand gradient — used only behind the login hero.
  static const LinearGradient forest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppTheme.primary, AppTheme.primaryDark],
  );

  /// Soft white surface: rounded, one diffuse shadow, no border.
  static BoxDecoration panel({Color? color, double? radius}) => BoxDecoration(
        color: color ?? AppTheme.cardBg,
        borderRadius: BorderRadius.circular(radius ?? Deco.radius),
        boxShadow: AppTheme.softShadow,
      );

  /// Flat tinted surface (no shadow) — for inset rows / steppers.
  static BoxDecoration soft({Color? color, double? radius}) => BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(radius ?? AppTheme.rTile),
      );

  static Color potentialColor(String p) {
    switch (p.toUpperCase()) {
      case 'KOL':
        return AppTheme.danger;
      case 'A':
        return AppTheme.gold;
      case 'B':
        return AppTheme.jade;
      default:
        return AppTheme.inkFaint;
    }
  }

  static Color severityColor(String s) {
    switch (s) {
      case 'high':
        return AppTheme.danger;
      case 'medium':
        return AppTheme.warning;
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
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }
}

/// Section header: quiet label with an optional leading glyph and trailing slot.
class DecoSectionTitle extends StatelessWidget {
  const DecoSectionTitle(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: AppTheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Soft white card.
class DecoCard extends StatelessWidget {
  const DecoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      decoration: Deco.panel(),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Deco.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: body),
    );
  }
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
      padding: const EdgeInsets.all(16),
      decoration: Deco.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: c.withAlpha(28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 15, color: c),
                ),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.inkMuted,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: c,
              height: 1,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.inkFaint)),
          ],
        ],
      ),
    );
  }
}

/// Circular progress gauge (0..1) — clean ring, no ornament.
class DecoGauge extends StatelessWidget {
  const DecoGauge({
    super.key,
    required this.value,
    required this.label,
    this.centerText,
    this.color = AppTheme.primary,
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
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.inkMuted,
            height: 1.3,
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
    final r = size.width / 2 - 6;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.primary.withAlpha(20);
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = color;
    const start = -math.pi / 2;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: r), start, math.pi * 2, false, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), start,
        math.pi * 2 * value, false, prog);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}

/// Labelled progress row with a rounded track.
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.ink)),
              ),
              Text(
                valueLabel ?? '$value',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(width: 6),
              Text('${(pct * 100).round()}%',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.inkFaint)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.rPill),
            child: Container(
              height: 8,
              color: AppTheme.surfaceAlt,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct == 0 ? 0.0001 : pct,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppTheme.rPill),
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
}

/// Full-pill tag.
class DecoChip extends StatelessWidget {
  const DecoChip(this.label,
      {super.key, this.color = AppTheme.primary, this.filled = false, this.icon});
  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 10 : 11, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round monogram avatar (initials) — used across directories & lists.
class DecoAvatar extends StatelessWidget {
  const DecoAvatar(this.text, {super.key, this.color = AppTheme.primary, this.size = 44});
  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = text.trim().isEmpty
        ? '?'
        : text
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0])
            .join()
            .toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// Simple centred empty / placeholder state.
class DecoEmpty extends StatelessWidget {
  const DecoEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });
  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppTheme.primary),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppTheme.inkFaint)),
            ],
          ],
        ),
      ),
    );
  }
}
