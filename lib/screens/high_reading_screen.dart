import 'package:flutter/material.dart';

import '../logic/formatting.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/badge_view.dart';
import '../widgets/common.dart';
import 'entry_screen.dart';
import 'flows.dart';

/// "10 · Dopo il salvataggio: misura alta". Calm tone, no alarms, and the
/// streak is kept: a high reading still counts.
class HighReadingScreen extends StatelessWidget {
  const HighReadingScreen({super.key, required this.outcome});

  final SaveOutcome outcome;

  /// Values where the ESC guidelines suggest prompt medical contact.
  static bool isVeryHigh(int sys, int dia) => sys >= 180 || dia >= 110;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final m = outcome.measurement;
    final usual = outcome.usualAverage;
    final streak = state.tracker.currentStreak;
    final schedule = state.schedule;
    final honest = outcome.newBadges.where((b) => b.id == 'honest').firstOrNull;
    final aboveUsual = usual != null && usual.isBelow(state.thresholds);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Chiudi',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => backToHome(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if (streak > 0) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Pill(
                label:
                    'Serie salva · $streak '
                    '${streak == 1 ? schedule.occasionSingular : schedule.occasionPlural}',
                background: AppColors.primarySoft,
                foreground: AppColors.primary,
                icon: Icons.check_rounded,
                fontSize: 13,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Misura salvata · '
                  '${formatRelativeDateTime(m.takenAt, state.now()).toLowerCase()}',
                  style: AppText.body(
                    14,
                    weight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(
                    aboveUsual
                        ? 'Oggi è più alta del solito'
                        : 'Oggi è sopra la soglia',
                    style: AppText.display(28, height: 1.15),
                  ),
                ),
                const SizedBox(height: 12),
                BpValue(systolic: m.systolic, diastolic: m.diastolic, size: 64),
                const SizedBox(height: 8),
                Text(
                  '${usual == null ? '' : 'Di solito sei intorno a $usual. '}'
                  'Se vuoi, puoi rimisurare dopo qualche minuto di riposo: '
                  'il diario le tiene tutte e due.',
                  style: AppText.body(
                    14,
                    weight: FontWeight.w500,
                    height: 1.45,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          if (isVeryHigh(m.systolic, m.diastolic)) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.highSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.highInk,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Valori così alti vanno ricontrollati. Se si confermano '
                      'o se non ti senti bene, contatta il tuo medico o il '
                      '112.',
                      style: AppText.body(
                        13,
                        weight: FontWeight.w700,
                        height: 1.4,
                        color: AppColors.highInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _remeasure(context),
                  child: const Text('Rimisura'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EntryScreen(existing: m)),
                  ),
                  child: const Text('Aggiungi nota'),
                ),
              ),
            ],
          ),
          if (honest != null) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Row(
                children: [
                  BadgeMedal(badge: honest, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Badge «${honest.title}»',
                          style: AppText.body(15, weight: FontWeight.w800),
                        ),
                        Text(
                          'Anche i giorni no fanno parte del diario.',
                          style: AppText.body(
                            13,
                            height: 1.4,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => backToHome(context),
              style: TextButton.styleFrom(
                textStyle: AppText.body(15, weight: FontWeight.w800),
              ),
              child: const Text('Fatto'),
            ),
          ),
        ],
      ),
    );
  }

  void _remeasure(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    openNewMeasurement(navigator.context);
  }
}
