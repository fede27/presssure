/// Italian date helpers. Kept local so the output does not depend on the
/// device locale data being loaded.
library;

const weekdayNames = [
  'lunedì',
  'martedì',
  'mercoledì',
  'giovedì',
  'venerdì',
  'sabato',
  'domenica',
];

const weekdayPlurals = [
  'lunedì',
  'martedì',
  'mercoledì',
  'giovedì',
  'venerdì',
  'sabati',
  'domeniche',
];

const weekdayShort = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];
const weekdayInitials = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

const monthNames = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

const monthShort = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String weekdayName(int weekday) => weekdayNames[weekday - 1];
String weekdayPlural(int weekday) => weekdayPlurals[weekday - 1];
String monthName(int month) => monthNames[month - 1];

String two(int n) => n.toString().padLeft(2, '0');

/// 07:42
String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// 27 settembre
String formatDayMonth(DateTime d) => '${d.day} ${monthName(d.month)}';

/// 27 set
String formatDayMonthShort(DateTime d) => '${d.day} ${monthShort[d.month - 1]}';

/// domenica 27 settembre
String formatWeekdayDayMonth(DateTime d) =>
    '${weekdayName(d.weekday)} ${formatDayMonth(d)}';

/// 27 settembre 2026
String formatFullDate(DateTime d) => '${formatDayMonth(d)} ${d.year}';

/// 27/09/2026
String formatNumericDate(DateTime d) =>
    '${two(d.day)}/${two(d.month)}/${d.year}';

/// 27/09
String formatNumericDayMonth(DateTime d) => '${two(d.day)}/${two(d.month)}';

/// "Oggi, 07:42", "Ieri, 08:10" or "domenica 20 settembre, 08:10".
String formatRelativeDateTime(DateTime d, DateTime now) {
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  final time = formatTime(d);
  if (diff == 0) return 'Oggi, $time';
  if (diff == 1) return 'Ieri, $time';
  return '${capitalize(formatWeekdayDayMonth(d))}, $time';
}

/// "apr – giu"
String formatMonthRange(DateTime from, DateTime to) =>
    '${monthShort[from.month - 1]} – ${monthShort[to.month - 1]}';

String greetingFor(DateTime now) {
  if (now.hour < 13) return 'Buongiorno';
  if (now.hour < 18) return 'Buon pomeriggio';
  return 'Buonasera';
}

String partOfDay(int hour) {
  if (hour < 12) return 'mattina';
  if (hour < 18) return 'pomeriggio';
  return 'sera';
}

/// Signed difference with a real minus sign: "−12", "+3", "0".
String signed(int n) {
  if (n < 0) return '−${-n}';
  if (n > 0) return '+$n';
  return '0';
}
