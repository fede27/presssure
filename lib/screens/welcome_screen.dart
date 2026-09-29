import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'habit_screen.dart';

/// "00 · Primo avvio": the one-time notice, then the habit setup.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 56,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: LogoMark(size: 64),
                    ),
                    const SizedBox(height: 16),
                    const Wordmark(size: 20),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        l.welcomeTitle,
                        style: AppText.display(
                          34,
                          weight: FontWeight.w700,
                          height: 1.08,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _Feature(
                      icon: Icons.photo_camera_outlined,
                      background: AppColors.primarySoft,
                      foreground: AppColors.primary,
                      text: l.welcomeFeaturePhoto,
                    ),
                    const SizedBox(height: 14),
                    _Feature(
                      icon: Icons.notifications_none_rounded,
                      background: AppColors.orangeSoft,
                      foreground: AppColors.systolicDark,
                      text: l.welcomeFeatureReminder,
                    ),
                    const SizedBox(height: 14),
                    _Feature(
                      icon: Icons.share_outlined,
                      background: AppColors.blueSoft,
                      foreground: AppColors.diastolic,
                      text: l.welcomeFeatureExport,
                    ),
                    const SizedBox(height: 14),
                    _Feature(
                      icon: Icons.smartphone_rounded,
                      background: AppColors.greenSoft,
                      foreground: AppColors.green,
                      text: l.welcomeFeatureLocal,
                    ),
                    const Spacer(),
                    const SizedBox(height: 22),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.welcomeNoticeTitle,
                            style: AppText.body(14, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l.welcomeNoticeBody,
                            style: AppText.body(
                              14,
                              weight: FontWeight.w500,
                              height: 1.5,
                              color: AppColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: AppText.body(16, weight: FontWeight.w800),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HabitScreen(onboarding: true),
                        ),
                      ),
                      child: Text(l.welcomeStart),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.text,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconTile(icon: icon, background: background, foreground: foreground),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: AppText.body(15, weight: FontWeight.w700, height: 1.35),
          ),
        ),
      ],
    );
  }
}
