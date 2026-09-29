import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/l10n/l10n.dart';
import 'package:presssure/logic/bp_category.dart';
import 'package:presssure/models/settings.dart';

import '../helpers.dart';

void main() {
  const esc = Thresholds.esc2024;

  group('classify (ESC 2024, home)', () {
    test('below 120/70 is not elevated', () {
      expect(classify(119, 69, esc), BpCategory.nonElevated);
    });

    test('120-134 or 70-84 is elevated', () {
      expect(classify(120, 60, esc), BpCategory.elevated);
      expect(classify(110, 70, esc), BpCategory.elevated);
      expect(classify(124, 77, esc), BpCategory.elevated);
      expect(classify(134, 84, esc), BpCategory.elevated);
    });

    test('from 135/85 on either value is high', () {
      expect(classify(135, 70, esc), BpCategory.high);
      expect(classify(120, 85, esc), BpCategory.high);
      expect(classify(152, 96, esc), BpCategory.high);
    });

    test('custom thresholds are respected', () {
      const custom = Thresholds(highSystolic: 140, highDiastolic: 90);
      expect(classify(138, 88, custom), BpCategory.elevated);
      expect(classify(140, 80, custom), BpCategory.high);
      expect(custom.isEsc2024, isFalse);
      expect(esc.isEsc2024, isTrue);
    });
  });

  test('labels in Italian and English follow the thresholds', () {
    expect(BpCategory.high.rangeLabel(itL10n, esc), 'Oltre 135/85');
    expect(
      BpCategory.elevated.rangeLabel(itL10n, esc),
      'Elevata (120–134 / 70–84)',
    );
    expect(
      BpCategory.nonElevated.rangeLabel(itL10n, esc),
      'Non elevata (sotto 120/70)',
    );
    expect(BpCategory.high.rangeLabel(enL10n, esc), 'Above 135/85');
    expect(BpCategory.elevated.label(enL10n), 'Elevated');
    expect(BpCategory.elevated.label(itL10n), 'Elevata');
  });
}
