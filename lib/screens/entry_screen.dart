import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../logic/bp_category.dart';
import '../models/measurement.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'flows.dart';

/// "04 · Controlla e salva": new reading or edit of an existing one.
///
/// A new reading pops with its [SaveOutcome]; an edit pops with null.
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key, this.existing, this.initialDay});

  final Measurement? existing;

  /// Pre-fills the date, e.g. when filling a skipped day from the diary.
  final DateTime? initialDay;

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

enum _SecondReading { none, waiting, ready }

class _EntryScreenState extends State<EntryScreen> {
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _pulse = TextEditingController();
  final _note = TextEditingController();
  final _sys2 = TextEditingController();
  final _dia2 = TextEditingController();
  final _pulse2 = TextEditingController();

  late DateTime _takenAt;
  Arm _arm = Arm.left;
  Posture _posture = Posture.sitting;
  var _second = _SecondReading.none;
  var _secondsLeft = 60;
  Timer? _timer;
  var _submitted = false;
  var _saving = false;
  var _initialized = false;

  bool get _editing => widget.existing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.read(context);
    final m = widget.existing;
    if (m != null) {
      _takenAt = m.takenAt;
      _sys.text = '${m.systolic}';
      _dia.text = '${m.diastolic}';
      _pulse.text = m.pulse?.toString() ?? '';
      _note.text = m.note;
      _arm = m.arm;
      _posture = m.posture;
    } else {
      final now = state.now();
      final day = widget.initialDay;
      _takenAt = day == null
          ? now
          : DateTime(
              day.year,
              day.month,
              day.day,
              state.settings.reminderHour,
              state.settings.reminderMinute,
            );
      // Same arm and posture as last time: measurements stay comparable.
      final last = state.latest;
      if (last != null) {
        _arm = last.arm;
        _posture = last.posture;
      }
    }
    for (final c in [_sys, _dia, _pulse, _sys2, _dia2, _pulse2]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_sys, _dia, _pulse, _note, _sys2, _dia2, _pulse2]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  String? _sysError(
    AppLocalizations l,
    TextEditingController sys,
    TextEditingController dia,
  ) {
    final v = _int(sys);
    if (v == null) return l.errSysRequired;
    if (v < 60 || v > 260) return l.errRange(60, 260);
    final d = _int(dia);
    if (d != null && v <= d) return l.errSysAboveDia;
    return null;
  }

  String? _diaError(AppLocalizations l, TextEditingController dia) {
    final v = _int(dia);
    if (v == null) return l.errDiaRequired;
    if (v < 30 || v > 160) return l.errRange(30, 160);
    return null;
  }

  String? _pulseError(AppLocalizations l, TextEditingController pulse) {
    if (pulse.text.trim().isEmpty) return null;
    final v = _int(pulse);
    if (v == null || v < 30 || v > 220) return l.errRange(30, 220);
    return null;
  }

  bool get _secondFilled =>
      _second == _SecondReading.ready &&
      (_sys2.text.isNotEmpty || _dia2.text.isNotEmpty);

  bool _secondValid(AppLocalizations l) =>
      _sysError(l, _sys2, _dia2) == null &&
      _diaError(l, _dia2) == null &&
      _pulseError(l, _pulse2) == null;

  bool _firstValid(AppLocalizations l) =>
      _sysError(l, _sys, _dia) == null && _diaError(l, _dia) == null;

  bool _valid(AppLocalizations l) =>
      _firstValid(l) &&
      _pulseError(l, _pulse) == null &&
      (!_secondFilled || _secondValid(l));

  /// Values to store: the average when a valid second reading was entered.
  /// Call only when the first reading is valid.
  ({int sys, int dia, int? pulse}) _values(AppLocalizations l) {
    final s1 = _int(_sys)!;
    final d1 = _int(_dia)!;
    final p1 = _int(_pulse);
    if (!_secondFilled || !_secondValid(l)) {
      return (sys: s1, dia: d1, pulse: p1);
    }
    final s2 = _int(_sys2)!;
    final d2 = _int(_dia2)!;
    final p2 = _int(_pulse2);
    final pulse = p1 == null
        ? p2
        : p2 == null
        ? p1
        : ((p1 + p2) / 2).round();
    return (
      sys: ((s1 + s2) / 2).round(),
      dia: ((d1 + d2) / 2).round(),
      pulse: pulse,
    );
  }

  void _startTimer() {
    setState(() {
      _second = _SecondReading.waiting;
      _secondsLeft = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          t.cancel();
          _second = _SecondReading.ready;
        }
      });
    });
  }

  void _skipTimer() {
    _timer?.cancel();
    setState(() => _second = _SecondReading.ready);
  }

  Future<void> _pickDateTime() async {
    final l = context.l10n;
    final now = AppScope.read(context).now();
    final date = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      helpText: l.pickDayHelp,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_takenAt),
      helpText: l.pickTimeHelp,
    );
    if (!mounted) return;
    final t = time ?? TimeOfDay.fromDateTime(_takenAt);
    var picked = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    if (picked.isAfter(now)) picked = now;
    setState(() => _takenAt = picked);
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _submitted = true);
    if (!_valid(l) || _saving) return;
    setState(() => _saving = true);
    final state = AppScope.read(context);
    final v = _values(l);
    final base = widget.existing;
    final m = Measurement(
      id: base?.id ?? state.newId(),
      takenAt: _takenAt,
      systolic: v.sys,
      diastolic: v.dia,
      pulse: v.pulse,
      arm: _arm,
      posture: _posture,
      note: _note.text.trim(),
      source: base?.source ?? ReadingSource.manual,
      doubleReading: _secondFilled || (base?.doubleReading ?? false),
    );
    final outcome = await state.saveMeasurement(m);
    if (!mounted) return;
    Navigator.of(context).pop(_editing ? null : outcome);
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.high),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AppScope.read(context).deleteMeasurement(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = AppScope.of(context);
    final previous = state.measurements
        .where(
          (m) => m.id != widget.existing?.id && m.takenAt.isBefore(_takenAt),
        )
        .lastOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l.entryEditTitle : l.entryNewTitle),
        titleSpacing: 0,
        actions: [
          if (_editing)
            IconButton(
              tooltip: l.deleteReading,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _WhenCard(
            takenAt: _takenAt,
            now: state.now(),
            onChange: _pickDateTime,
            onScan: _editing ? null : () => showScanPlaceholder(context),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BigField(
                  label: l.systolic,
                  unit: 'mmHg',
                  controller: _sys,
                  error: _submitted ? _sysError(l, _sys, _dia) : null,
                  autofocus: !_editing,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BigField(
                  label: l.diastolic,
                  unit: 'mmHg',
                  controller: _dia,
                  error: _submitted ? _diaError(l, _dia) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BigField(
            label: l.pulse,
            unit: 'bpm',
            controller: _pulse,
            error: _submitted ? _pulseError(l, _pulse) : null,
            size: 34,
            hint: l.optional,
          ),
          if (_firstValid(l)) ...[
            const SizedBox(height: 12),
            _CategoryHint(
              category: classify(
                _values(l).sys,
                _values(l).dia,
                state.thresholds,
              ),
              esc: state.thresholds.isEsc2024,
              previous: previous == null
                  ? null
                  : '${previous.systolic}/${previous.diastolic}',
            ),
          ],
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.contextTitle,
                  style: AppText.body(16, weight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _ChoiceGroup<Arm>(
                  label: l.arm,
                  value: _arm,
                  options: {Arm.left: l.armLeft, Arm.right: l.armRight},
                  onChanged: (v) => setState(() => _arm = v),
                ),
                const SizedBox(height: 14),
                _ChoiceGroup<Posture>(
                  label: l.posture,
                  value: _posture,
                  options: {
                    Posture.sitting: l.postureSitting,
                    Posture.standing: l.postureStanding,
                    Posture.lying: l.postureLying,
                  },
                  onChanged: (v) => setState(() => _posture = v),
                ),
                const SizedBox(height: 14),
                Text(
                  l.note,
                  style: AppText.body(
                    13,
                    weight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppText.body(15, weight: FontWeight.w500),
                  decoration: InputDecoration(hintText: l.noteHint),
                ),
              ],
            ),
          ),
          if (!_editing) ...[
            const SizedBox(height: 12),
            _secondReadingSection(l),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: AppText.body(16, weight: FontWeight.w800),
            ),
            icon: const Icon(Icons.check_rounded),
            label: Text(_editing ? l.saveChanges : l.saveReading),
          ),
        ],
      ),
    );
  }

  Widget _secondReadingSection(AppLocalizations l) {
    if (_second == _SecondReading.ready) {
      final avg = _valid(l) && _secondFilled ? _values(l) : null;
      final showErrors = _submitted && _secondFilled;
      return AppCard(
        borderColor: const Color(0xFF9FC3C6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.secondReading,
              style: AppText.body(
                14,
                weight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _BigField(
                    label: l.systolic,
                    unit: 'mmHg',
                    controller: _sys2,
                    size: 30,
                    error: showErrors ? _sysError(l, _sys2, _dia2) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BigField(
                    label: l.diastolic,
                    unit: 'mmHg',
                    controller: _dia2,
                    size: 30,
                    error: showErrors ? _diaError(l, _dia2) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _BigField(
              label: l.pulse,
              unit: 'bpm',
              controller: _pulse2,
              size: 26,
              hint: l.optional,
              error: showErrors ? _pulseError(l, _pulse2) : null,
            ),
            const SizedBox(height: 8),
            Text(
              avg == null
                  ? l.secondAverageInfo
                  : l.secondAverageValue('${avg.sys}/${avg.dia}'),
              style: AppText.body(13, color: AppColors.ink2),
            ),
          ],
        ),
      );
    }
    final waiting = _second == _SecondReading.waiting;
    return DashedBorder(
      color: const Color(0xFF9FC3C6),
      radius: 22,
      dash: 6,
      gap: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    waiting ? l.secondWaitTitle : l.secondOptionalTitle,
                    style: AppText.body(
                      14,
                      weight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    waiting ? l.secondWaitBody : l.secondOptionalBody,
                    style: AppText.body(12, height: 1.4, color: AppColors.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: waiting ? _skipTimer : _startTimer,
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 44),
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: AppText.body(14, weight: FontWeight.w800),
              ),
              child: Text(
                waiting
                    ? l.timerSkip(
                        '0:${_secondsLeft.toString().padLeft(2, '0')}',
                      )
                    : l.timerStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhenCard extends StatelessWidget {
  const _WhenCard({
    required this.takenAt,
    required this.now,
    required this.onChange,
    required this.onScan,
  });

  final DateTime takenAt;
  final DateTime now;
  final VoidCallback onChange;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      child: Row(
        children: [
          const IconTile(
            icon: Icons.edit_calendar_outlined,
            background: AppColors.primarySoft,
            foreground: AppColors.primary,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  onScan == null ? l.whenReading : l.whenManual,
                  style: AppText.body(14, weight: FontWeight.w800),
                ),
                Text(
                  context.dates.relative(takenAt, now, l),
                  style: AppText.body(13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: Text(l.change)),
          if (onScan != null)
            IconButton(
              tooltip: l.scanTooltip,
              onPressed: onScan,
              color: AppColors.primary,
              icon: const Icon(Icons.photo_camera_outlined),
            ),
        ],
      ),
    );
  }
}

/// Large numeric input in a white box, as in the design.
class _BigField extends StatelessWidget {
  const _BigField({
    required this.label,
    required this.unit,
    required this.controller,
    this.error,
    this.size = 44,
    this.hint,
    this.autofocus = false,
  });

  final String label;
  final String unit;
  final TextEditingController controller;
  final String? error;
  final double size;
  final String? hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: hasError ? AppColors.warnBg : AppColors.surface,
        border: Border.all(
          color: hasError ? AppColors.high : AppColors.borderStrong,
          width: hasError ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.body(
              13,
              weight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Semantics(
                  label: context.l10n.fieldSemantics(label, unit),
                  child: TextField(
                    controller: controller,
                    autofocus: autofocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: AppText.display(size, tabular: true),
                    decoration: InputDecoration(
                      hintText: hint ?? '–',
                      hintStyle: AppText.body(
                        size * 0.45,
                        weight: FontWeight.w500,
                        color: AppColors.faint,
                      ),
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: AppText.body(
                  13,
                  weight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          if (hasError)
            Text(
              error!,
              style: AppText.body(
                12,
                weight: FontWeight.w700,
                color: AppColors.high,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryHint extends StatelessWidget {
  const _CategoryHint({
    required this.category,
    required this.esc,
    this.previous,
  });

  final BpCategory category;
  final bool esc;
  final String? previous;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hint = l.categoryHint(
      category.label(l).toLowerCase(),
      esc ? l.hintSourceEsc : l.hintSourceCustom,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: category.chipBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: category.chipForeground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              previous == null ? hint : '$hint · ${l.previousValue(previous!)}',
              style: AppText.body(
                13,
                weight: FontWeight.w700,
                height: 1.4,
                color: category.chipForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.body(
              13,
              weight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in options.entries)
                ChoicePill(
                  label: entry.value,
                  selected: entry.key == value,
                  showCheck: true,
                  onTap: () => onChanged(entry.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
