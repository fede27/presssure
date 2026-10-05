import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

import '../config.dart';
import '../l10n/l10n.dart';
import '../models/settings.dart';
import '../services/backup.dart';
import '../services/data_format.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'flows.dart';
import 'habit_screen.dart';

Future<void> openSettings(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

/// "12 · Impostazioni".
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Bumped when a backup is restored, so the threshold fields reload.
  var _generation = 0;
  var _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showSnack(context, context.l10n.errorGeneric('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveBackup() => _run(() async {
    final state = AppScope.read(context);
    final l = context.l10n;
    final backup = state.createBackup();
    final d = backup.createdAt;
    String two(int n) => n.toString().padLeft(2, '0');
    final saved = await FilePicker.saveFile(
      fileName:
          '${l.backupFileBase}_${d.year}-${two(d.month)}-${two(d.day)}.json',
      bytes: Uint8List.fromList(utf8.encode(backup.encode())),
      mimeType: 'application/json',
    );
    if (saved == null) return;
    await state.recordBackup(backup.createdAt);
    if (mounted) showSnack(context, l.backupSaved);
  });

  Future<void> _restoreBackup() => _run(() async {
    final state = AppScope.read(context);
    final l = context.l10n;
    final dates = context.dates;
    final file = await FilePicker.pickFile();
    if (file == null) return;
    final Backup backup;
    try {
      backup = Backup.decode(utf8.decode(await file.readAsBytes()));
    } on FormatException {
      if (mounted) showSnack(context, l.backupInvalid);
      return;
    } on DataTooNewException {
      if (mounted) showSnack(context, l.backupTooNew);
      return;
    }
    if (!mounted) return;
    final readings = l.readingsCount(backup.measurements.length);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.restoreTitle),
        content: Text(
          l.restoreBody(dates.fullDate(backup.createdAt), readings),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.restoreBackup),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await state.restoreBackup(backup);
    if (!mounted) return;
    setState(() => _generation++);
    showSnack(context, l.restoreDone(readings));
  });

  Future<void> _deleteAll() async {
    final state = AppScope.read(context);
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteAllTitle),
        content: Text(l.deleteAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.high),
            child: Text(l.deleteAllConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Back to the root first: without data it becomes the welcome screen.
    backToHome(context);
    await state.deleteAllData();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final state = AppScope.of(context);
    final settings = state.settings;
    final time = TimeOfDay(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle), titleSpacing: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HabitScreen())),
            child: Row(
              children: [
                const IconTile(
                  icon: Icons.notifications_none_rounded,
                  background: AppColors.orangeSoft,
                  foreground: AppColors.systolicDark,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.habitAndReminders,
                        style: AppText.body(15, weight: FontWeight.w800),
                      ),
                      Text(
                        l.reminderSummary(
                          capitalize(state.schedule.describe(l)),
                          dates.time(
                            DateTime(2000, 1, 1, time.hour, time.minute),
                          ),
                        ),
                        style: AppText.body(13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ThresholdsCard(
            key: ValueKey(_generation),
            initial: settings.thresholds,
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CardHeading(title: l.dataTitle, intro: l.dataIntro),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _saveBackup,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(l.saveBackup),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _restoreBackup,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.upload_rounded, size: 18),
                          label: Text(l.restoreBackup),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.backupReminder,
                  onChanged: (v) => state.updateSettings(
                    settings.copyWith(backupReminder: v),
                  ),
                  title: Text(l.backupReminder, style: AppText.body(15)),
                  subtitle: Text(
                    settings.lastBackup == null
                        ? l.noBackupYet
                        : l.lastBackup(dates.dayMonth(settings.lastBackup!)),
                    style: AppText.body(13, color: AppColors.muted),
                  ),
                ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
          if (state.beta && state.scanLog != null) ...[
            const SizedBox(height: 14),
            const _BetaCard(),
          ],
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l.aboutThresholds,
                    style: AppText.body(15, weight: FontWeight.w700),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l.version,
                    style: AppText.body(15, weight: FontWeight.w700),
                  ),
                  trailing: Text(
                    appVersion,
                    style: AppText.body(15, color: AppColors.muted),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l.privacyPolicy,
                    style: AppText.body(15, weight: FontWeight.w700),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _deleteAll,
              style: TextButton.styleFrom(foregroundColor: AppColors.high),
              child: Text(l.deleteAllData),
            ),
          ),
        ],
      ),
    );
  }
}

/// Beta builds: consent to keep the last readings, and sending them.
class _BetaCard extends StatefulWidget {
  const _BetaCard();

  @override
  State<_BetaCard> createState() => _BetaCardState();
}

class _BetaCardState extends State<_BetaCard> {
  late Future<int> _count = _load();
  var _sending = false;

  Future<int> _load() => AppScope.read(context).scanLog!.count();

  void _reload() => setState(() {
    _count = _load();
  });

  Future<void> _toggle(bool keep) async {
    final l = context.l10n;
    final hadScans = await _count > 0;
    if (!mounted) return;
    await AppScope.read(context).setKeepScans(keep);
    if (!mounted) return;
    _reload();
    if (!keep && hadScans) showSnack(context, l.scansCleared);
  }

  Future<void> _clear() async {
    final l = context.l10n;
    await AppScope.read(context).scanLog!.clear();
    if (!mounted) return;
    _reload();
    showSnack(context, l.scansCleared);
  }

  Future<void> _send() async {
    final l = context.l10n;
    setState(() => _sending = true);
    try {
      await AppScope.read(context).sendKeptScans();
    } on FlutterEmailSenderNotAvailableException {
      if (mounted) showSnack(context, l.noMailApp);
    } catch (e) {
      if (mounted) showSnack(context, l.errorGeneric('$e'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = AppScope.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CardHeading(
              title: l.betaTitle,
              intro: l.keepScansBody(keptScans, feedbackEmail),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: state.keepsScans,
            onChanged: _toggle,
            title: Text(l.keepScansTitle, style: AppText.body(15)),
          ),
          FutureBuilder<int>(
            future: _count,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.keptScansCount(count),
                      style: AppText.body(13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (count > 0)
                          TextButton(
                            onPressed: _sending ? null : _clear,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.high,
                            ),
                            child: Text(l.clearScans),
                          ),
                        FilledButton.icon(
                          onPressed: count == 0 || _sending ? null : _send,
                          icon: const Icon(
                            Icons.mail_outline_rounded,
                            size: 18,
                          ),
                          label: Text(l.sendScans),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.title, required this.intro});

  final String title;
  final String intro;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppText.body(16, weight: FontWeight.w800)),
        ),
        const SizedBox(height: 2),
        Text(
          intro,
          style: AppText.body(13, height: 1.4, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// The band limits, saved as soon as the four values make sense.
class _ThresholdsCard extends StatefulWidget {
  const _ThresholdsCard({super.key, required this.initial});

  final Thresholds initial;

  @override
  State<_ThresholdsCard> createState() => _ThresholdsCardState();
}

class _ThresholdsCardState extends State<_ThresholdsCard> {
  late final _elevSys = TextEditingController();
  late final _elevDia = TextEditingController();
  late final _highSys = TextEditingController();
  late final _highDia = TextEditingController();
  ThresholdsProblem? _problem;

  @override
  void initState() {
    super.initState();
    _fill(widget.initial);
  }

  @override
  void dispose() {
    for (final c in [_elevSys, _elevDia, _highSys, _highDia]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Thresholds t) {
    _elevSys.text = '${t.elevatedSystolic}';
    _elevDia.text = '${t.elevatedDiastolic}';
    _highSys.text = '${t.highSystolic}';
    _highDia.text = '${t.highDiastolic}';
  }

  void _changed() {
    int value(TextEditingController c) => int.tryParse(c.text) ?? 0;
    final t = Thresholds(
      elevatedSystolic: value(_elevSys),
      elevatedDiastolic: value(_elevDia),
      highSystolic: value(_highSys),
      highDiastolic: value(_highDia),
    );
    setState(() => _problem = t.problem);
    if (_problem == null) AppScope.read(context).updateThresholds(t);
  }

  void _reset() {
    _fill(Thresholds.esc2024);
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final header = AppText.body(
      12,
      weight: FontWeight.w700,
      color: AppColors.muted,
    );

    // Screen readers hear "Intermedia da, sistolica".
    Widget field(String band, String kind, TextEditingController c) => SizedBox(
      width: 72,
      child: Semantics(
        label: l.thresholdFieldLabel(band, kind),
        child: TextField(
          controller: c,
          onChanged: (_) => _changed(),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          style: AppText.body(16, weight: FontWeight.w800, tabular: true),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );

    Widget row(
      Color color,
      String band,
      TextEditingController sys,
      TextEditingController dia,
    ) {
      return Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(band, style: AppText.body(14, weight: FontWeight.w700)),
          ),
          field(band, l.systolic.toLowerCase(), sys),
          const SizedBox(width: 10),
          field(band, l.diastolic.toLowerCase(), dia),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeading(title: l.thresholdsSection, intro: l.thresholdsIntro),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: 72,
                  child: Text(
                    l.systolic,
                    textAlign: TextAlign.center,
                    style: header,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 72,
                  child: Text(
                    l.diastolic,
                    textAlign: TextAlign.center,
                    style: header,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          row(AppColors.gold, l.elevatedFrom, _elevSys, _elevDia),
          const SizedBox(height: 8),
          row(AppColors.high, l.aboveThresholdFrom, _highSys, _highDia),
          if (_problem != null) ...[
            const SizedBox(height: 8),
            Text(
              switch (_problem!) {
                ThresholdsProblem.range => l.thresholdsErrRange,
                ThresholdsProblem.order => l.thresholdsErrOrder,
              },
              style: AppText.body(
                13,
                weight: FontWeight.w700,
                color: AppColors.high,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _reset,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navBar,
                foregroundColor: AppColors.ink,
                minimumSize: const Size(44, 44),
                textStyle: AppText.body(14, weight: FontWeight.w700),
              ),
              child: Text(l.restoreEsc),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Avvertenza e fonti delle soglie".
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const e = Thresholds.esc2024;
    final body = AppText.body(15, height: 1.5, color: AppColors.ink2);
    Widget heading(String text) => Semantics(
      header: true,
      child: Text(text, style: AppText.body(16, weight: FontWeight.w800)),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.aboutThresholds), titleSpacing: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(l.aboutDisclaimer),
                const SizedBox(height: 6),
                Text(l.welcomeNoticeBody, style: body),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(l.aboutSources),
                const SizedBox(height: 6),
                Text(
                  l.aboutBands(
                    e.elevatedSystolic,
                    e.elevatedDiastolic,
                    e.highSystolic,
                    e.highDiastolic,
                  ),
                  style: body,
                ),
                const SizedBox(height: 8),
                Text(l.aboutSource, style: body),
                const SizedBox(height: 8),
                Text(l.thresholdsDoctorNote, style: body),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(l.aboutCredits),
                const SizedBox(height: 6),
                Text(l.aboutModel, style: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Informativa privacy". Same text as `docs/privacy.html`.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final body = AppText.body(15, height: 1.5, color: AppColors.ink2);
    final sections = [
      (l.privacyDataTitle, l.privacyData),
      (l.privacyCameraTitle, l.privacyCamera),
      (l.privacyOfflineTitle, l.privacyOffline),
      (l.privacySharingTitle, l.privacySharing),
      (l.privacyDeleteTitle, l.privacyDelete),
      (l.privacyChildrenTitle, l.privacyChildren),
      (l.privacyContactTitle, l.privacyContact(privacyEmail)),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.privacyPolicy), titleSpacing: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppCard(child: Text(l.privacyIntro, style: body)),
          for (final (title, text) in sections) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: AppText.body(16, weight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(text, style: body),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: Text(
              l.privacyUpdated(context.dates.fullDate(privacyUpdated)),
              style: AppText.body(13, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
