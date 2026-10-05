/// Build-wide settings.
library;

/// Shown in "Versione"; keep in step with `version` in pubspec.yaml.
const appVersion = '1.0';

/// Beta builds for testers:
/// `flutter build apk --release --dart-define=BETA=true`.
///
/// They can keep the last readings of the display (with the tester's
/// consent) and send them for analysis; public builds never keep photos.
const isBetaBuild = bool.fromEnvironment('BETA');

/// Where beta testers send their readings.
const feedbackEmail = 'federico.scarel@gmail.com';

/// How many readings a beta build keeps, newest first.
const keptScans = 20;
