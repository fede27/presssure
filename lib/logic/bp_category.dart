import '../models/settings.dart';

/// Home blood-pressure band, as in the ESC 2024 guidelines.
enum BpCategory { nonElevated, elevated, high }

BpCategory classify(int systolic, int diastolic, Thresholds t) {
  if (systolic >= t.highSystolic || diastolic >= t.highDiastolic) {
    return BpCategory.high;
  }
  if (systolic >= t.elevatedSystolic || diastolic >= t.elevatedDiastolic) {
    return BpCategory.elevated;
  }
  return BpCategory.nonElevated;
}

extension BpCategoryText on BpCategory {
  /// Short label for chips.
  String get label => switch (this) {
    BpCategory.nonElevated => 'Non elevata',
    BpCategory.elevated => 'Elevata',
    BpCategory.high => 'Alta',
  };

  /// Label with the band limits, for legends.
  String rangeLabel(Thresholds t) => switch (this) {
    BpCategory.nonElevated =>
      'Non elevata (sotto ${t.elevatedSystolic}/${t.elevatedDiastolic})',
    BpCategory.elevated =>
      'Elevata (${t.elevatedSystolic}–${t.highSystolic - 1} / '
          '${t.elevatedDiastolic}–${t.highDiastolic - 1})',
    BpCategory.high => 'Oltre ${t.highSystolic}/${t.highDiastolic}',
  };
}
