import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/schedule.dart';
import '../models/life_event.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/event_widgets.dart';

/// "15 · Nuovo / modifica evento".
class EventEditScreen extends StatefulWidget {
  const EventEditScreen({super.key, this.existing});

  final LifeEvent? existing;

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  EventCategory? _category;
  late final TextEditingController _title;
  late final TextEditingController _note;
  late DateTime _day;
  var _showInChart = true;
  var _inReport = true;
  var _submitted = false;
  var _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.category;
    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _showInChart = e?.showInChart ?? true;
    _inReport = e?.inReport ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dayReady) {
      _day = widget.existing?.day ?? dateOnly(AppScope.read(context).now());
      _dayReady = true;
    }
  }

  var _dayReady = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final now = AppScope.read(context).now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      helpText: context.l10n.eventPickDay,
    );
    if (picked != null && mounted) setState(() => _day = dateOnly(picked));
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_category == null || _title.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final state = AppScope.read(context);
    await state.saveEvent(
      LifeEvent(
        id: widget.existing?.id ?? state.newId(),
        day: _day,
        category: _category!,
        title: _title.text.trim(),
        note: _note.text.trim(),
        showInChart: _showInChart,
        inReport: _inReport,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.eventDeleteTitle, style: AppText.display(24)),
              const SizedBox(height: 10),
              Text(
                l.eventDeleteBody,
                style: AppText.body(15, height: 1.45, color: AppColors.ink2),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.high,
                      ),
                      child: Text(l.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final removed = await state.deleteEvent(widget.existing!.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.eventDeleted),
          action: removed == null
              ? null
              : SnackBarAction(
                  label: l.undo,
                  onPressed: () => state.saveEvent(removed),
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final now = AppScope.of(context).now();
    final label = AppText.body(
      14,
      weight: FontWeight.w800,
      color: AppColors.ink2,
    );
    final error = AppText.body(13, color: AppColors.high);
    final dayText = _day == dateOnly(now)
        ? l.eventToday(dates.weekdayDayMonth(_day))
        : capitalize(dates.weekdayFullDate(_day));

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l.eventEdit : l.eventNew),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(l.eventKindQuestion, style: label),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              for (final c in EventCategory.values)
                _CategoryOption(
                  category: c,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
          if (_submitted && _category == null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(l.eventKindRequired, style: error),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(l.eventTitleLabel, style: label),
          ),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            style: AppText.body(16),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l.eventTitleHint,
              errorText: _submitted && _title.text.trim().isEmpty
                  ? l.eventTitleRequired
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(l.eventDateLabel, style: label),
          ),
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _pickDay,
              child: Semantics(
                button: true,
                label: '${l.eventDateLabel}: $dayText',
                excludeSemantics: true,
                child: SizedBox(
                  height: 54,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 22,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(dayText, style: AppText.body(16))),
                      const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text.rich(
              TextSpan(
                text: l.note,
                style: label,
                children: [
                  TextSpan(
                    text: ' ${l.eventNoteOptional}',
                    style: AppText.body(14, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          TextField(
            controller: _note,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            style: AppText.body(15, weight: FontWeight.w500, height: 1.4),
            decoration: InputDecoration(hintText: l.eventNoteHint),
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _switch(
                    l.eventChartSwitch,
                    l.eventChartSwitchSub,
                    _showInChart,
                    (v) => setState(() => _showInChart = v),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _switch(
                    l.eventPdfSwitch,
                    l.eventPdfSwitchSub,
                    _inReport,
                    (v) => setState(() => _inReport = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: Text(_editing ? l.saveChanges : l.eventAddToDiary),
          ),
          if (_editing) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _delete,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.high,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: Text(
                l.eventDelete,
                style: AppText.body(15, weight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: value,
    onChanged: onChanged,
    title: Text(title, style: AppText.body(15, weight: FontWeight.w700)),
    subtitle: Text(subtitle, style: AppText.body(13, color: AppColors.muted)),
  );
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final EventCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFEAF3F3) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.borderStrong,
            width: selected ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            child: Row(
              children: [
                EventTile(category, size: 36),
                const SizedBox(width: 10),
                // One word per kind: smaller rather than broken in two.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      category.label(context.l10n),
                      style: AppText.body(
                        15,
                        weight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
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
