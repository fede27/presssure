import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/event_impact.dart';
import '../models/life_event.dart';
import '../theme.dart';

/// Label, icon and colours of each kind of event, from the design.
extension EventCategoryLook on EventCategory {
  String label(AppLocalizations l) => switch (this) {
    EventCategory.lifeWork => l.eventCategoryLifeWork,
    EventCategory.diet => l.eventCategoryDiet,
    EventCategory.activity => l.eventCategoryActivity,
    EventCategory.other => l.eventCategoryOther,
  };

  IconData get icon => switch (this) {
    EventCategory.lifeWork => Icons.work_outline_rounded,
    EventCategory.diet => Icons.restaurant_rounded,
    EventCategory.activity => Icons.directions_walk_rounded,
    EventCategory.other => Icons.flag_outlined,
  };

  /// Background of the icon tile and of the diary row.
  Color get soft => switch (this) {
    EventCategory.lifeWork => const Color(0xFFD7E8EA),
    EventCategory.diet => const Color(0xFFE2EDD9),
    EventCategory.activity => const Color(0xFFECE2F2),
    EventCategory.other => AppColors.navBar,
  };

  /// The icon on [soft].
  Color get strong => switch (this) {
    EventCategory.lifeWork => AppColors.primary,
    EventCategory.diet => const Color(0xFF3D6B2A),
    EventCategory.activity => const Color(0xFF5E3F78),
    EventCategory.other => AppColors.muted,
  };

  /// Small text on [soft], readable (4.5:1).
  Color get ink => switch (this) {
    EventCategory.lifeWork => AppColors.primaryDark,
    EventCategory.diet => const Color(0xFF2E5320),
    EventCategory.activity => const Color(0xFF4A3260),
    EventCategory.other => AppColors.ink2,
  };
}

/// Numbers of the events in date order (1 = oldest), the same in the chart,
/// the comparison and the PDF.
Map<String, int> eventNumbers(Iterable<LifeEvent> events) => {
  for (final (i, e) in sortedEvents(events).indexed) e.id: i + 1,
};

class EventTile extends StatelessWidget {
  const EventTile(this.category, {super.key, this.size = 44, this.on});

  final EventCategory category;
  final double size;

  /// Tile colour when it sits on a coloured row; [EventCategoryLook.soft]
  /// otherwise.
  final Color? on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: on ?? category.soft,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(category.icon, color: category.strong, size: size * 0.55),
    );
  }
}

/// The event's number in a circle, filled when selected.
class EventNumberDot extends StatelessWidget {
  const EventNumberDot(this.number, {super.key, this.selected = false});

  final int number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 28.0 : 24.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: AppColors.surface, width: 3)
            : Border.all(color: AppColors.ink2, width: 1.5),
      ),
      child: Text(
        '$number',
        style: AppText.body(
          12,
          weight: FontWeight.w800,
          color: selected ? Colors.white : AppColors.ink,
        ),
      ),
    );
  }
}

/// "Mese prima · 4  129/82 → Mese dopo · 4  127/80   −2/−2", a tap opens
/// the comparison.
class BeforeAfterRow extends StatelessWidget {
  const BeforeAfterRow({super.key, required this.impact, this.onTap});

  final EventImpact impact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final before = impact.beforeAvg?.toString() ?? '–';
    final after = impact.afterAvg?.toString() ?? '–';
    final delta = impact.hasBoth
        ? '${signed(impact.deltaSystolic)}/${signed(impact.deltaDiastolic)}'
        : null;
    final small = AppText.body(
      12,
      weight: FontWeight.w700,
      color: AppColors.muted,
    );
    final value = AppText.display(21, tabular: true);
    return Semantics(
      button: onTap != null,
      label: l.impactSemantics(before, after, delta ?? '–'),
      excludeSemantics: true,
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.impactBeforeShort(
                          impact.window.name,
                          impact.before.length,
                        ),
                        style: small,
                      ),
                      Text(before, style: value),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: AppColors.faint,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.impactAfterShort(
                          impact.window.name,
                          impact.after.length,
                        ),
                        style: small,
                      ),
                      Text(after, style: value),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (delta != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      delta,
                      style: AppText.body(
                        13,
                        weight: FontWeight.w800,
                        color: AppColors.ink2,
                        tabular: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small note with an info icon, as in the comparison cards.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.body(12, height: 1.4, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

/// Notes about a comparison: missing readings, other events, period still
/// running, few readings.
List<String> impactNotes(
  EventImpact impact,
  AppLocalizations l,
  Dates dates,
  Map<String, int> numbers,
) {
  String days(List<DateTime> list) => list.map(dates.dayMonth).join(', ');
  return [
    if (impact.after.isEmpty)
      l.impactNoAfter
    else if (impact.before.length < 3 || impact.after.length < 3)
      l.impactFewReadings,
    if (impact.others.isNotEmpty)
      l.impactOthers(
        impact.others
            .map(
              (e) =>
                  '${numbers[e.id]} · ${e.title} (${dates.dayMonthShort(e.day)})',
            )
            .join(', '),
      ),
    if (impact.afterOngoing && !impact.upcoming)
      l.impactOngoing(dates.dayMonth(impact.afterLast)),
    if (impact.missedBefore.isNotEmpty)
      l.impactMissingBefore(
        impact.missedBefore.length,
        days(impact.missedBefore),
      ),
    if (impact.missedAfter.isNotEmpty)
      l.impactMissingAfter(impact.missedAfter.length, days(impact.missedAfter)),
  ];
}

/// Options side by side on a grey track, the chosen one raised in white
/// ("2 settimane | 1 mese | 3 mesi").
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  /// What the options choose, for screen readers.
  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (final (option, text) in options)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: option == value,
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: option == value ? AppColors.surface : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: option == value
                            ? const [
                                BoxShadow(
                                  color: Color(0x1F1A1D21),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          14,
                          weight: option == value
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: option == value
                              ? AppColors.ink
                              : AppColors.ink2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
