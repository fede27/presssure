import '../models/settings.dart';

/// Home blood-pressure band, as in the ESC 2024 guidelines. Labels are in
/// `lib/l10n/l10n.dart`.
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
