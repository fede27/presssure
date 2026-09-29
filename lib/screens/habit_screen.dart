import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/reminder_plan.dart';
import '../logic/schedule.dart';
import '../models/settings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'flows.dart';

/// "02 · La tua abitudine e promemoria".
class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key, this.onboarding = false});

  /// First launch: saving completes the onboarding.
  final bool onboarding;

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  late Frequency _frequency;
  late Set<int> _weekdays;
  late TimeOfDay _time;
  late bool _remindNextDay;
  late bool _monthlySummary;
  var _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final s = AppScope.read(context).settings;
    _frequency = s.frequency;
    _weekdays = {...s.weekdays};
    _time = TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute);
    _remindNextDay = s.remindNextDay;
    _monthlySummary = s.monthlySummary;
    _initialized = true;
  }

  bool get _multiDay => _frequency == Frequency.fewTimesWeek;

  String _label(AppLocalizations l, Frequency f) => switch (f) {
    Frequency.daily => l.frequencyDaily,
    Frequency.fewTimesWeek => l.frequencyFewTimesWeek,
    Frequency.weekly => l.frequencyWeekly,
    Frequency.biweekly => l.frequencyBiweekly,
    Frequency.monthly => l.frequencyMonthly,
  };

  /// Weekdays in the order of the local calendar (Monday or Sunday first).
  List<int> _weekOrder(BuildContext context) {
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final start = first == 0 ? DateTime.sunday : first;
    return [for (var i = 0; i < 7; i++) (start - 1 + i) % 7 + 1];
  }

  void _setFrequency(Frequency f) {
    setState(() {
      _frequency = f;
      if (f == Frequency.fewTimesWeek && _weekdays.length < 2) {
        _weekdays = {DateTime.monday, DateTime.thursday};
      } else if (f != Frequency.fewTimesWeek && _weekdays.length > 1) {
        _weekdays = {DateTime.sunday};
      }
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (!_multiDay) {
        _weekdays = {day};
      } else if (_weekdays.contains(day)) {
        if (_weekdays.length > 2) _weekdays.remove(day);
      } else {
        _weekdays.add(day);
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: context.l10n.habitReminderTime,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final state = AppScope.read(context);
    final s = state.settings;
    final changedRhythm =
        s.frequency != _frequency || s.weekdays.join() != _weekdays.join();
    await state.updateSettings(
      s.copyWith(
        onboarded: true,
        frequency: _frequency,
        weekdays: _weekdays,
        reminderHour: _time.hour,
        reminderMinute: _time.minute,
        remindNextDay: _remindNextDay,
        monthlySummary: _monthlySummary,
        anchor: s.anchor == null || changedRhythm ? state.now() : s.anchor,
      ),
    );
    await state.requestReminderPermission();
    if (!mounted) return;
    if (widget.onboarding) {
      backToHome(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = AppScope.of(context);
    final schedule = Schedule(
      frequency: _frequency,
      weekdays: _weekdays,
      anchor: state.now(),
    );
    final nextDue = schedule.isDue(state.now())
        ? dateOnly(state.now())
        : schedule.nextDueAfter(state.now());
    final preview = reminderText(l, schedule, nextDue, state.latest);
    final showNextDay =
        _frequency != Frequency.daily && _frequency != Frequency.fewTimesWeek;
    final time = _time.format(context);
    final when = _frequency == Frequency.daily
        ? l.scheduleDaily
        : l.onWeekday(weekdayKey(nextDue.weekday));

    return Scaffold(
      appBar: AppBar(title: Text(l.habitTitle), titleSpacing: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l.habitIntro,
              style: AppText.body(14, height: 1.5, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CardTitle(l.habitHowOften),
                RadioGroup<Frequency>(
                  groupValue: _frequency,
                  onChanged: (f) => _setFrequency(f!),
                  child: Column(
                    children: [
                      for (final f in Frequency.values)
                        RadioListTile<Frequency>(
                          value: f,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.trailing,
                          title: Text(
                            _label(l, f),
                            style: AppText.body(
                              15,
                              weight: f == _frequency
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: f == _frequency
                                  ? AppColors.primary
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CardTitle(l.habitWhen),
                if (_frequency != Frequency.daily) ...[
                  const SizedBox(height: 8),
                  Text(
                    _multiDay ? l.habitPickTwoDays : schedule.describe(l),
                    style: AppText.body(13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final (i, d) in _weekOrder(context).indexed)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                            child: _DayButton(
                              day: d,
                              selected: _weekdays.contains(d),
                              onTap: () => _toggleDay(d),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(l.habitReminderTime, style: AppText.body(15)),
                    ),
                    OutlinedButton(
                      onPressed: _pickTime,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        side: const BorderSide(
                          color: AppColors.borderStrong,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: AppColors.ink,
                        textStyle: AppText.body(16, weight: FontWeight.w800),
                      ),
                      child: Text(
                        time,
                        semanticsLabel: '${l.habitReminderTime} $time',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CardTitle(l.habitKeepOnTrack),
                if (showNextDay)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _remindNextDay,
                    onChanged: (v) => setState(() => _remindNextDay = v),
                    title: Text(l.habitRemindNextDay, style: AppText.body(15)),
                    subtitle: Text(
                      l.habitRemindNextDayHint,
                      style: AppText.body(
                        13,
                        weight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _monthlySummary,
                  onChanged: (v) => setState(() => _monthlySummary = v),
                  title: Text(l.habitMonthlySummary, style: AppText.body(15)),
                  subtitle: Text(
                    l.habitMonthlySummaryHint,
                    style: AppText.body(
                      13,
                      weight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l.habitPreviewHeading(when, time).toUpperCase(),
              style: AppText.body(
                13,
                weight: FontWeight.w800,
                color: AppColors.muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _NotificationPreview(
            title: preview.title,
            body: preview.body,
            time: time,
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: AppText.body(16, weight: FontWeight.w800),
            ),
            child: Text(widget.onboarding ? l.habitSaveAndStart : l.save),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: AppText.body(15, weight: FontWeight.w800)),
  );
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dates = context.dates;
    return Semantics(
      label: capitalize(dates.weekdayLong(day)),
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.borderStrong,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                dates.weekdayNarrow(day).toUpperCase(),
                style: AppText.body(
                  14,
                  weight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({
    required this.title,
    required this.body,
    required this.time,
  });

  final String title;
  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1A1D21),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LogoMark(size: 22),
                const SizedBox(width: 8),
                Text(
                  '${context.l10n.appTitle} · $time',
                  style: AppText.body(12, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: AppText.body(15, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              body,
              style: AppText.body(
                14,
                weight: FontWeight.w500,
                height: 1.4,
                color: AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
