import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/bp_category.dart';
import '../theme.dart';

/// White rounded card with the design's hairline border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// "Intermedia", "Alta"... pill.
class CategoryChip extends StatelessWidget {
  const CategoryChip(this.category, {super.key});

  final BpCategory category;

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: category.label(context.l10n),
      background: category.chipBackground,
      foreground: category.chipForeground,
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.fontSize = 12,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 4, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: AppText.body(
                fontSize,
                weight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "126/82" with the muted slash, optionally followed by "mmHg".
class BpValue extends StatelessWidget {
  const BpValue({
    super.key,
    required this.systolic,
    required this.diastolic,
    this.size = 52,
    this.unit = true,
    this.color = AppColors.ink,
  });

  final int systolic;
  final int diastolic;
  final double size;
  final bool unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = AppText.display(
      size,
      color: color,
      height: 1,
      letterSpacing: size * -0.03,
      tabular: true,
    );
    // Scales down instead of overflowing with large system text.
    return Semantics(
      label: context.l10n.bpSemantics(systolic, diastolic),
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(text: '$systolic'),
                  TextSpan(
                    text: '/',
                    style: style.merge(
                      AppText.display(
                        size,
                        weight: FontWeight.w500,
                        color: AppColors.slash,
                      ),
                    ),
                  ),
                  TextSpan(text: '$diastolic'),
                ],
              ),
            ),
            if (unit) ...[
              const SizedBox(width: 10),
              Text(
                'mmHg',
                style: AppText.body(
                  14,
                  weight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped toggle used for filters, periods, arm and posture.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    this.minHeight = 44,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.borderStrong,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected && showCheck) ...[
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        14,
                        weight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded square with an icon, as in the design's list items.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 44,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: foreground, size: size * 0.5),
    );
  }
}

/// Month heading with a summary on the right ("Settembre · 4 misure").
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: AppText.display(20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              trailing ?? '',
              textAlign: TextAlign.right,
              style: AppText.body(
                13,
                weight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// App logo, the same as the launcher icon (presssure-icon/source): a
/// heart with a check on a peach rounded square.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _LogoPainter());
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // The icon is drawn on a 108 grid; launchers show the middle 72, and
    // so does the logo.
    const from = 18.0, span = 72.0;
    final s = size.width / span;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(12 * s)),
      Paint()..color = AppColors.orangeSoft,
    );
    canvas.scale(s);
    canvas.translate(-from, -from);
    final heart = Path()
      ..moveTo(54, 80)
      ..cubicTo(40, 71, 27, 61.5, 27, 47)
      ..cubicTo(27, 38.2, 33.7, 31.5, 42, 31.5)
      ..cubicTo(47.4, 31.5, 51.6, 34.3, 54, 38.5)
      ..cubicTo(56.4, 34.3, 60.6, 31.5, 66, 31.5)
      ..cubicTo(74.3, 31.5, 81, 38.2, 81, 47)
      ..cubicTo(81, 61.5, 68, 71, 54, 80)
      ..close();
    canvas.drawPath(heart, Paint()..color = AppColors.systolic);
    final check = Path()
      ..moveTo(42, 53.5)
      ..lineTo(50.5, 62)
      ..lineTo(66.5, 45);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "PressSure" wordmark with "Sure" in the brand color.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    final style = AppText.display(size, weight: FontWeight.w700);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'Press'),
          TextSpan(
            text: 'Sure',
            style: style.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Rounded rectangle with a dashed outline.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.radius = 10,
    this.strokeWidth = 1.5,
    this.dash = 4,
    this.gap = 3,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color, radius, strokeWidth, dash, gap),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.radius, this.width, this.dash, this.gap);

  final Color color;
  final double radius;
  final double width;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
