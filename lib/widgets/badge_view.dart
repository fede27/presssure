import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/achievements.dart';
import '../theme.dart';

IconData badgeIcon(String id) => switch (id) {
  'first_step' => Icons.flag_outlined,
  'two_months' || 'three_months' => Icons.event_repeat_outlined,
  'six_months' => Icons.calendar_month_outlined,
  'month_complete' => Icons.event_available_outlined,
  'comeback' => Icons.replay_rounded,
  'no_pause' => Icons.all_inclusive_rounded,
  'beat_record' => Icons.emoji_events_outlined,
  'year' => Icons.cake_outlined,
  'honest' => Icons.verified_outlined,
  'lynx' => Icons.photo_camera_outlined,
  'first_pdf' => Icons.picture_as_pdf_outlined,
  'notes' => Icons.sticky_note_2_outlined,
  'double' => Icons.looks_two_outlined,
  'month_below' => Icons.south_east_rounded,
  'trend_down' => Icons.trending_down_rounded,
  'quarter_below' => Icons.stacked_line_chart_rounded,
  _ => Icons.star_outline_rounded,
};

Color badgeColor(BadgeGroup group) => switch (group) {
  BadgeGroup.consistency => AppColors.primary,
  BadgeGroup.habits => AppColors.diastolic,
  BadgeGroup.trend => AppColors.green,
};

/// Round medal: full color when unlocked, grey with a progress ring when not.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.badge, this.size = 64});

  final Achievement badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = badgeColor(badge.group);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MedalPainter(
          unlocked: badge.unlocked,
          progress: badge.progress,
          color: color,
        ),
        child: Icon(
          badgeIcon(badge.id),
          size: size * 0.42,
          color: badge.unlocked ? Colors.white : AppColors.faint,
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter({
    required this.unlocked,
    required this.progress,
    required this.color,
  });

  final bool unlocked;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    if (unlocked) {
      canvas.drawCircle(c, r, Paint()..color = color);
      final dash = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      const segments = 28;
      for (var i = 0; i < segments; i++) {
        final a = i / segments * 2 * math.pi;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r - 5),
          a,
          math.pi / segments,
          false,
          dash,
        );
      }
      return;
    }
    canvas.drawCircle(c, r, Paint()..color = AppColors.navBar);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFD9D3C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.unlocked != unlocked || old.progress != progress;
}
