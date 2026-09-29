import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/settings.dart';
import 'package:presssure/screens/celebrate_screen.dart';
import 'package:presssure/screens/entry_screen.dart';
import 'package:presssure/screens/high_reading_screen.dart';
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
      find.textContaining('5 domeniche di fila.', findRichText: true),
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
    expect(find.text('Elevata'), findsOneWidget);
    expect(find.text('141/90'), findsOneWidget);
    expect(find.text('−11/−8'), findsOneWidget);
  });

  testWidgets('"Fotografa" is a placeholder for now', (tester) async {
    await pumpApp(tester, measurements: designReadings());

    await tester.tap(find.text('Fotografa'));
    await tester.pump();
    expect(find.textContaining('arriverà presto'), findsOneWidget);
  });

  testWidgets('manual reading: saved, then celebrated', (tester) async {
    final state = await pumpApp(tester, measurements: designReadings());

    await tapAndSettle(tester, find.text('A mano'));
    expect(find.text('Controlla e salva'), findsOneWidget);

    await enterReading(tester, '124', '77', pulse: '68');
    expect(
      find.textContaining('Fascia «elevata» secondo ESC 2024'),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.text('Salva misurazione'));

    expect(state.measurements.length, 24);
    expect(state.latest!.systolic, 124);
    expect(find.byType(CelebrateScreen), findsOneWidget);
    expect(find.text('NUOVO BADGE'), findsOneWidget);
    expect(find.text('Sei mesi di diario!'), findsOneWidget);
    expect(find.text('6 domeniche di fila'), findsOneWidget);
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
    expect(find.text('Serie salva · 6 domeniche'), findsOneWidget);
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

  testWidgets('diary: months, skipped Sundays and filters', (tester) async {
    await pumpApp(tester, measurements: designReadings(includeToday: true));

    await tapAndSettle(tester, navItem('Diario'));
    expect(find.text('Settembre'), findsOneWidget);
    expect(find.text('4 misure · media 125/80'), findsOneWidget);
    expect(find.text('2 domeniche senza misura'), findsOneWidget);
    expect(find.text('“Dormito poco”'), findsOneWidget);
    expect(find.text('124/77'), findsOneWidget);

    await tapAndSettle(tester, find.text('Con note'));
    expect(find.text('124/77'), findsNothing);
    expect(find.text('126/81'), findsOneWidget);
    expect(find.text('2 domeniche senza misura'), findsNothing);
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
    expect(find.text('24 domeniche su 26'), findsOneWidget);
    expect(find.text('Oltre 135/85'), findsOneWidget);

    await tapAndSettle(tester, find.text('Cambia soglie'));
    expect(find.text('Soglie'), findsOneWidget);
    await tapAndSettle(tester, find.text('Annulla'));
  });

  testWidgets('share tab: preview numbers and placeholders', (tester) async {
    await pumpApp(tester, measurements: designReadings(includeToday: true));

    await tapAndSettle(tester, navItem('Condividi'));
    expect(find.text('Esporta e condividi'), findsOneWidget);
    expect(find.text('Non hai ancora condiviso il diario'), findsOneWidget);
    expect(
      find.text('5 aprile 2026 – 27 settembre 2026 · 24 misure'),
      findsOneWidget,
    );
    expect(find.text('Scarica PDF'), findsOneWidget);

    await tapAndSettle(tester, find.text('Link sicuro o QR'));
    expect(find.text('Link sicuro e QR: in arrivo.'), findsOneWidget);
  });

  testWidgets('achievements from the home card', (tester) async {
    await pumpApp(tester, measurements: designReadings(includeToday: true));

    await tapAndSettle(tester, find.text('Traguardi'));
    expect(find.text('Jolly del mese: 1 disponibile'), findsOneWidget);
    expect(find.text('Costanza'), findsOneWidget);
    expect(find.text('Sei mesi di diario'), findsOneWidget);
    expect(find.text('NUOVO'), findsWidgets);
    expect(find.text('×5'), findsOneWidget);
    expect(find.text('18 domeniche · apr – ago'), findsOneWidget);
    expect(find.text('5 su 6'), findsOneWidget);
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
        find.textContaining('5 Sundays in a row.', findRichText: true),
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
