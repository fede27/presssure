import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

class PressSureApp extends StatefulWidget {
  const PressSureApp({super.key, required this.state});

  final AppState state;

  @override
  State<PressSureApp> createState() => _PressSureAppState();
}

class _PressSureAppState extends State<PressSureApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The day may have changed while the app was in background.
    if (state == AppLifecycleState.resumed) widget.state.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // No fixed locale: the phone's language is used when supported,
        // English otherwise.
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) {
          final locale = Localizations.localeOf(context);
          widget.state.updateLocale(
            locale,
            dateLocaleFor(
              locale,
              WidgetsBinding.instance.platformDispatcher.locales,
            ),
          );
          return child!;
        },
        home: const _Root(),
      ),
    );
  }
}

/// First launch shows the welcome, then the main tabs.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final onboarded = AppScope.of(context).settings.onboarded;
    return onboarded ? const HomeShell() : const WelcomeScreen();
  }
}
