/// Build-wide settings.
library;

/// Shown in "Versione"; keep in step with `version` in pubspec.yaml.
const appVersion = '1.0';

/// Contact and date of the privacy policy. Keep them, and the text of
/// `PrivacyScreen`, in step with `docs/privacy.html` (the page linked from
/// Play Console).
const privacyEmail = 'federico.scarel@gmail.com';
final privacyUpdated = DateTime(2026, 10, 5);

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
