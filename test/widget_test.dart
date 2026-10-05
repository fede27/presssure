import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/settings.dart';
import 'package:presssure/screens/celebrate_screen.dart';
import 'package:presssure/screens/entry_screen.dart';
import 'package:presssure/screens/habit_screen.dart';
import 'package:presssure/screens/high_reading_screen.dart';
import 'package:presssure/screens/settings_screen.dart';
import 'package:presssure/screens/welcome_screen.dart';
import 'package:presssure/widgets/common.dart';

import 'helpers.dart';

Finder navItem(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<void> enterReading(
  WidgetTester tester,
  String sys,
  String dia, {
  String? pulse,
}) async {
  final fields = find.descendant(
    of: find.byType(EntryScreen),
    matching: find.byType(TextField),
  );
  await tester.enterText(fields.at(0), sys);
  await tester.enterText(fields.at(1), dia);
  if (pulse != null) await tester.enterText(fields.at(2), pulse);
  await tester.pump();
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch: welcome, habit setup, then home', (tester) async {
    final state = await pumpApp(tester, settings: const AppSettings());

    expect(
      find.text('Il tuo diario della pressione, senza pensieri'),
      findsOneWidget,
    );
    expect(find.textContaining('non è un dispositivo medico'), findsOneWidget);

    await tapAndSettle(tester, find.text('Ho capito, iniziamo'));
    expect(find.text('La tua abitudine'), findsOneWidget);
    expect(find.text('Una volta a settimana'), findsOneWidget);

    await tapAndSettle(tester, find.text('Ogni giorno'));
    await tapAndSettle(tester, find.text('Salva e inizia'));

    expect(state.settings.onboarded, isTrue);
    expect(state.settings.frequency, Frequency.daily);
    expect(find.text('Buongiorno'), findsOneWidget);
    expect(find.text('La tua prima misura ti aspetta'), findsOneWidget);
    expect(find.text('Ancora nessuna misura'), findsOneWidget);
  });

  testWidgets('home shows today, the last reading and the streak', (
    tester,
  ) async {
    await pumpApp(tester, measurements: designReadings());

    expect(find.text('Domenica 27 settembre'), findsOneWidget);
    expect(find.text('Oggi è il giorno della misura'), findsOneWidget);
    expect(
      find.textContaining('5 di fila.', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Oggi chiudi settembre al completo.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Ultima misura · domenica 20 settembre'), findsOneWidget);
    final value = tester.widget<BpValue>(find.byType(BpValue));
    expect((value.systolic, value.diastolic), (126, 82));
    expect(find.text('Intermedia'), findsOneWidget);
    expect(find.text('141/90'), findsOneWidget);
    expect(find.text('−11/−8'), findsOneWidget);
  });

  testWidgets('manual reading: saved, then celebrated', (tester) async {
    final state = await pumpApp(tester, measurements: designReadings());

    await tapAndSettle(tester, find.text('A mano'));
    expect(find.text('Controlla e salva'), findsOneWidget);

    await enterReading(tester, '124', '77', pulse: '68');
    expect(
      find.textContaining('Fascia «intermedia» secondo ESC 2024'),
      findsOneWidget,
    );
    expect(find.textContaining('misura precedente 126/82'), findsOneWidget);
    await tapAndSettle(tester, find.text('Salva misurazione'));

    expect(state.measurements.length, 24);
    expect(state.latest!.systolic, 124);
    expect(find.byType(CelebrateScreen), findsOneWidget);
    expect(find.text('NUOVO BADGE'), findsOneWidget);
    expect(find.text('Sei mesi di diario!'), findsOneWidget);
    expect(find.text('6 misure di fila'), findsOneWidget);
    expect(find.text('Hai un jolly se salti una misura.'), findsOneWidget);
    expect(find.text('124/77, la più bassa da aprile'), findsOneWidget);

    await tapAndSettle(tester, find.text('Fatto'));
    expect(
      find.text('Fatto! Prossima misura domenica 4 ottobre'),
      findsOneWidget,
    );
  });

  testWidgets('a high reading gets the calm screen and keeps the streak', (
    tester,
  ) async {
    await pumpApp(tester, measurements: designReadings());

    await tapAndSettle(tester, find.text('A mano'));
    await enterReading(tester, '152', '96');
    await tapAndSettle(tester, find.text('Salva misurazione'));

    expect(find.byType(HighReadingScreen), findsOneWidget);
    expect(find.text('Oggi è più alta del solito'), findsOneWidget);
    expect(find.text('Serie salva · 6 di fila'), findsOneWidget);
    expect(
      find.textContaining('Di solito sei intorno a 127/80'),
      findsOneWidget,
    );
    expect(find.textContaining('contatta il tuo medico'), findsNothing);
  });

  testWidgets('invalid values are not saved', (tester) async {
    final state = await pumpApp(tester, measurements: designReadings());

    await tapAndSettle(tester, find.text('A mano'));
    await tapAndSettle(tester, find.text('Salva misurazione'));
    expect(find.text('Inserisci la sistolica'), findsOneWidget);
    expect(find.text('Inserisci la diastolica'), findsOneWidget);

    await enterReading(tester, '80', '95');
    await tapAndSettle(tester, find.text('Salva misurazione'));
    expect(find.text('Deve superare la diastolica'), findsOneWidget);
    expect(state.measurements.length, 23);
  });

  testWidgets('diary: months, missed readings and filters', (tester) async {
    await pumpApp(tester, measurements: designReadings(includeToday: true));

    await tapAndSettle(tester, navItem('Diario'));
    expect(find.text('Settembre'), findsOneWidget);
    expect(find.text('4 misure · media 125/80'), findsOneWidget);
    expect(find.text('2 misure saltate'), findsOneWidget);
    expect(find.text('“Dormito poco”'), findsOneWidget);
    expect(find.text('124/77'), findsOneWidget);

    await tapAndSettle(tester, find.text('Con note'));
    expect(find.text('124/77'), findsNothing);
    expect(find.text('126/81'), findsOneWidget);
    expect(find.text('2 misure saltate'), findsNothing);
  });

  testWidgets('diary: edit and delete a reading', (tester) async {
    final state = await pumpApp(
      tester,
      measurements: designReadings(includeToday: true),
    );

    await tapAndSettle(tester, navItem('Diario'));
    await tapAndSettle(tester, find.text('124/77'));
    expect(find.text('Modifica misura'), findsOneWidget);

    await tapAndSettle(tester, find.byTooltip('Elimina misura'));
    await tapAndSettle(tester, find.text('Elimina'));
    expect(state.measurements.length, 23);
    expect(find.text('124/77'), findsNothing);
  });

  testWidgets('trends: averages, quarters and bands', (tester) async {
    await pumpApp(tester, measurements: designReadings(includeToday: true));

    await tapAndSettle(tester, navItem('Andamento'));
    expect(find.text('Ultime 4 misure'), findsOneWidget);
    expect(find.text('24 misure in 6 mesi'), findsOneWidget);
    expect(find.text('Trimestre a confronto'), findsOneWidget);
    expect(find.text('129/81'), findsOneWidget);
    expect(find.text('24 misure su 26 previste'), findsOneWidget);
    expect(find.text('Sopra soglia (135/85)'), findsOneWidget);

    // The thresholds are edited in the settings.
    await tapAndSettle(tester, find.text('Cambia soglie'));
    expect(find.text('Soglie delle fasce'), findsOneWidget);
  });

  testWidgets('share tab: preview numbers and placeholders', (tester) async {
    await pumpApp(tester, measurements: designReadings(includeToday: true));

    await tapAndSettle(tester, navItem('Condividi'));
    expect(find.text('Esporta e condividi'), findsOneWidget);
    expect(find.text('Non hai ancora esportato il diario'), findsOneWidget);
    expect(
      find.text('5 aprile 2026 – 27 settembre 2026 · 24 misure'),
      findsOneWidget,
    );
    expect(find.text('Scarica PDF'), findsOneWidget);

    expect(find.text('Link sicuro o QR'), findsNothing);
    expect(find.text('Esporta i dati in CSV (per Excel)'), findsOneWidget);
  });

  testWidgets('achievements from the home card', (tester) async {
    await pumpApp(tester, measurements: designReadings(includeToday: true));

    await tapAndSettle(tester, find.text('Traguardi'));
    expect(find.text('Jolly: 1 disponibile'), findsOneWidget);
    expect(find.text('prossimo tra 4'), findsOneWidget);
    expect(find.text('Costanza'), findsOneWidget);
    expect(find.text('Sei mesi di diario'), findsOneWidget);
    expect(find.text('NUOVO'), findsWidgets);
    expect(find.text('×5'), findsOneWidget);
    expect(find.text('18 di fila · apr – ago'), findsOneWidget);
    expect(find.text('24 su 26 · 92%'), findsOneWidget);
    expect(find.text('6 mesi su 12'), findsOneWidget);
  });

  group('settings', () {
    testWidgets('open from the home, with the habit and the thresholds', (
      tester,
    ) async {
      await pumpApp(tester, measurements: designReadings());

      await tapAndSettle(tester, find.byTooltip('Impostazioni'));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Ogni domenica · 08:00'), findsOneWidget);
      expect(find.text('Nessun backup finora'), findsOneWidget);
      expect(find.text('Versione'), findsOneWidget);

      await tapAndSettle(tester, find.text('Abitudine e promemoria'));
      expect(find.byType(HabitScreen), findsOneWidget);
      await tapAndSettle(tester, find.byTooltip('Indietro'));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('thresholds are saved when valid, reset to ESC 2024', (
      tester,
    ) async {
      final state = await pumpApp(tester, measurements: designReadings());
      await tapAndSettle(tester, find.byTooltip('Impostazioni'));

      Finder field(String label) => find.bySemanticsLabel(label);
      final semantics = tester.ensureSemantics();
      await tester.enterText(field('Sopra soglia da, sistolica'), '140');
      await tester.pump();
      expect(state.thresholds.highSystolic, 140);
      expect(state.thresholds.isEsc2024, isFalse);

      // Elevated not below the threshold: shown, not saved.
      await tester.enterText(field('Intermedia da, sistolica'), '145');
      await tester.pump();
      expect(
        find.text('La fascia intermedia deve stare sotto la soglia.'),
        findsOneWidget,
      );
      expect(state.thresholds.elevatedSystolic, 120);

      await tapAndSettle(tester, find.text('Ripristina ESC 2024'));
      expect(state.thresholds.isEsc2024, isTrue);
      expect(
        find.text('La fascia intermedia deve stare sotto la soglia.'),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('delete all data goes back to the welcome', (tester) async {
      final state = await pumpApp(tester, measurements: designReadings());
      await tapAndSettle(tester, find.byTooltip('Impostazioni'));

      await tapAndSettle(tester, find.text('Cancella tutti i dati'));
      await tapAndSettle(tester, find.text('Annulla'));
      expect(state.measurements, hasLength(23));

      await tapAndSettle(tester, find.text('Cancella tutti i dati'));
      await tapAndSettle(tester, find.text('Cancella tutto'));
      expect(state.measurements, isEmpty);
      expect(state.settings.onboarded, isFalse);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  group('localization', () {
    testWidgets('US English phone: texts, dates and times in English', (
      tester,
    ) async {
      final state = await pumpApp(
        tester,
        measurements: designReadings(),
        locale: const Locale('en', 'US'),
      );

      expect(state.locale, const Locale('en'));
      expect(state.dateLocale, 'en_US');
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Sunday, September 27'), findsOneWidget);
      expect(find.text('Today is measuring day'), findsOneWidget);
      expect(
        find.textContaining('5 in a row.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Last reading · Sunday, September 20'), findsOneWidget);
      expect(navItem('Diary'), findsOneWidget);

      await tapAndSettle(tester, navItem('Diary'));
      expect(find.text('September'), findsOneWidget);
      expect(find.text('3 readings · average 126/80'), findsOneWidget);
      // 12-hour clock in the US.
      expect(
        find.textContaining(RegExp(r'^8:05\sAM · pulse 66$')),
        findsOneWidget,
      );
    });

    testWidgets('UK English phone: day before month', (tester) async {
      final state = await pumpApp(
        tester,
        measurements: designReadings(),
        locale: const Locale('en', 'GB'),
      );
      expect(state.dateLocale, 'en_GB');
      expect(find.text('Sunday 27 September'), findsOneWidget);
    });

    testWidgets('unsupported language falls back to English', (tester) async {
      await pumpApp(
        tester,
        measurements: designReadings(),
        locale: const Locale('de', 'DE'),
      );
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Sunday, September 27'), findsOneWidget);
    });

    for (final (locale, first, last) in [
      (const Locale('it', 'IT'), 'Lunedì', 'Domenica'),
      (const Locale('en', 'US'), 'Sunday', 'Saturday'),
    ]) {
      testWidgets('the week in the habit screen starts on $first ($locale)', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpApp(tester, settings: const AppSettings(), locale: locale);
        await tapAndSettle(tester, find.byType(FilledButton));

        final firstX = tester.getCenter(find.bySemanticsLabel(first)).dx;
        final lastX = tester.getCenter(find.bySemanticsLabel(last)).dx;
        expect(firstX, lessThan(lastX));
        semantics.dispose();
      });
    }
  });
}
