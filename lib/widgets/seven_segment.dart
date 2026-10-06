import 'package:flutter/material.dart';

/// Lit segments of each digit: a top, b top right, c bottom right, d bottom,
/// e bottom left, f top left, g middle.
const _segments = {
  '0': 'abcdef',
  '1': 'bc',
  '2': 'abdeg',
  '3': 'abcdg',
  '4': 'bcfg',
  '5': 'acdfg',
  '6': 'acdefg',
  '7': 'abc',
  '8': 'abcdefg',
  '9': 'abcdfg',
};

/// The values read, drawn like the monitor's display: a reminder of what
/// was read, in the "Letto dalla foto" card ("04 · Controlla e salva").
class MiniDisplay extends StatelessWidget {
  const MiniDisplay({
    super.key,
    required this.systolic,
    required this.diastolic,
    this.size = 56,
  });

  final int systolic;
  final int diastolic;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.21),
        child: CustomPaint(
          size: Size.square(size),
          painter: _MiniDisplayPainter('$systolic', '$diastolic'),
        ),
      ),
    );
  }
}

class _MiniDisplayPainter extends CustomPainter {
  _MiniDisplayPainter(this.top, this.bottom);

  final String top;
  final String bottom;

  static const _case = Color(0xFFE7E3DC);
  static const _lcd = Color(0xFFA9B6A0);
  static const _ink = Color(0xFF1F291E);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 56;
    canvas.drawRect(Offset.zero & size, Paint()..color = _case);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6 * s, 6 * s, 44 * s, 44 * s),
        Radius.circular(6 * s),
      ),
      Paint()..color = _lcd,
    );
    // Right-aligned like on a monitor; three places, unused ones faint.
    _number(canvas, top, right: 47 * s, top: 11 * s, height: 14 * s);
    _number(canvas, bottom, right: 47 * s, top: 30 * s, height: 11 * s);
  }

  void _number(
    Canvas canvas,
    String text, {
    required double right,
    required double top,
    required double height,
  }) {
    final width = height * 0.52;
    final gap = height * 0.16;
    final digits = text.padLeft(3).split('');
    var x = right - digits.length * width - (digits.length - 1) * gap;
    for (final d in digits) {
      _digit(canvas, Rect.fromLTWH(x, top, width, height), _segments[d] ?? '');
      x += width + gap;
    }
  }

  void _digit(Canvas canvas, Rect r, String lit) {
    final t = r.height * 0.13;
    final midY = r.top + r.height / 2;
    final shapes = {
      'a': Rect.fromLTWH(r.left + t * 0.6, r.top, r.width - t * 1.2, t),
      'g': Rect.fromLTWH(r.left + t * 0.6, midY - t / 2, r.width - t * 1.2, t),
      'd': Rect.fromLTWH(r.left + t * 0.6, r.bottom - t, r.width - t * 1.2, t),
      'f': Rect.fromLTWH(r.left, r.top + t * 0.6, t, r.height / 2 - t * 0.9),
      'b': Rect.fromLTWH(
        r.right - t,
        r.top + t * 0.6,
        t,
        r.height / 2 - t * 0.9,
      ),
      'e': Rect.fromLTWH(r.left, midY + t * 0.3, t, r.height / 2 - t * 0.9),
      'c': Rect.fromLTWH(
        r.right - t,
        midY + t * 0.3,
        t,
        r.height / 2 - t * 0.9,
      ),
    };
    for (final MapEntry(key: name, value: rect) in shapes.entries) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(t / 2)),
        Paint()..color = _ink.withValues(alpha: lit.contains(name) ? 1 : 0.07),
      );
    }
  }

  @override
  bool shouldRepaint(_MiniDisplayPainter old) =>
      old.top != top || old.bottom != bottom;
}
