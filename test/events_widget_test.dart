import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/life_event.dart';
import 'package:presssure/screens/event_edit_screen.dart';
import 'package:presssure/screens/event_impact_screen.dart';
import 'package:presssure/services/report.dart';
import 'package:presssure/services/report_pdf.dart';

import 'helpers.dart';
import 'widget_test.dart' show navItem, tapAndSettle;

void main() {
  group('diary', () {
    testWidgets('events among the readings, with their month', (tester) async {
      await pumpApp(
        tester,
        measurements: designReadings(includeToday: true),
        events: designEvents(),
      );
      await tapAndSettle(tester, navItem('Diario'));

      expect(find.textContaining('3 eventi da aprile'), findsOneWidget);
      // August is the second month, open by default.
      expect(find.text('3 misure · media 128/81 · 1 evento'), findsOneWidget);
      expect(find.text('Camminata ogni giorno'), findsOneWidget);
      expect(find.text('Evento · Attività fisica'), findsOneWidget);
      // The readings are all still there.
      expect(find.text('4 misure · media 125/80'), findsOneWidget);
      expect(find.text('2 misure saltate'), findsOneWidget);
    });

    testWidgets('only events: before and after each one', (tester) async {
      await pumpApp(
        tester,
        measurements: designReadings(includeToday: true),
        events: designEvents(),
      );
      await tapAndSettle(tester, navItem('Diario'));
      await tapAndSettle(tester, find.text('Eventi 3'));

      expect(
        find.text('Media delle misure prima e dopo ogni evento'),
        findsOneWidget,
      );
      expect(find.text('124/77'), findsNothing);
      expect(find.text('−7/−5'), findsOneWidget);
      expect(
        find.text('“Niente più due ore di auto al giorno.”'),
        findsOneWidget,
      );
      expect(
        find.text('Nel periodo prima mancano 2 misure (9 agosto, 16 agosto).'),
        findsOneWidget,
      );

      await tapAndSettle(tester, find.text('3 mesi'));
      expect(find.text('3 mesi prima · 13'), findsOneWidget);

      // The row opens the comparison, with the same period.
      await tapAndSettle(tester, find.text('3 mesi prima · 13'));
      expect(find.byType(EventImpactScreen), findsOneWidget);
      expect(
        find.text(
          'Il periodo dopo è ancora in corso: si chiude il 30 settembre.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no events yet: how to add one', (tester) async {
      await pumpApp(tester, measurements: designReadings(includeToday: true));
      await tapAndSettle(tester, navItem('Diario'));
      await tapAndSettle(tester, find.text('Eventi 0'));
      expect(find.text('Nessun evento, per ora'), findsOneWidget);
    });
  });

  group('edit', () {
    testWidgets('a new event needs a kind and a title', (tester) async {
      final state = await pumpApp(
        tester,
        measurements: designReadings(includeToday: true),
      );
      await tapAndSettle(tester, navItem('Diario'));
      await tapAndSettle(tester, find.widgetWithText(OutlinedButton, 'Evento'));
      expect(find.byType(EventEditScreen), findsOneWidget);
      expect(find.text('Nuovo evento'), findsOneWidget);
      expect(find.text('Oggi · domenica 27 settembre'), findsOneWidget);

      await tapAndSettle(tester, find.text('Aggiungi al diario'));
      expect(find.text('Scegli il tipo di cambiamento.'), findsOneWidget);
      expect(
        find.text('Scrivi in poche parole cosa è cambiato.'),
        findsOneWidget,
      );
      expect(state.events, isEmpty);

      await tapAndSettle(tester, find.text('Alimentazione'));
      await tester.enterText(find.byType(TextField).first, 'Meno sale');
      await tapAndSettle(tester, find.text('Aggiungi al diario'));

      expect(find.byType(EventEditScreen), findsNothing);
      final e = state.events.single;
      expect(e.title, 'Meno sale');
      expect(e.category, EventCategory.diet);
      expect(e.day, DateTime(2026, 9, 27));
      expect(e.showInChart && e.inReport, isTrue);
      expect(find.text('Evento · Alimentazione'), findsOneWidget);
    });

    testWidgets('edit, delete and undo', (tester) async {
      final state = await pumpApp(
        tester,
        measurements: designReadings(includeToday: true),
        events: designEvents(),
      );
      await tapAndSettle(tester, navItem('Diario'));
      await tapAndSettle(tester, find.text('Camminata ogni giorno'));
      expect(find.text('Modifica evento'), findsOneWidget);
      expect(find.text('Lunedì 24 agosto 2026'), findsOneWidget);

      await tapAndSettle(tester, find.text('Elimina evento'));
      expect(find.text('Eliminare questo evento?'), findsOneWidget);
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Elimina'));

      expect(find.byType(EventEditScreen), findsNothing);
      expect(state.events.map((e) => e.id), ['e1', 'e2']);
      expect(find.text('Evento eliminato'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.widgetWithText(SnackBarAction, 'Annulla'),
      );
      expect(state.events.map((e) => e.id), ['e1', 'e2', 'e3']);
      expect(find.text('Camminata ogni giorno'), findsOneWidget);
    });
  });

  group('trends', () {
    testWidgets('events off by default, then remembered', (tester) async {
      final state = await pumpApp(
        tester,
        measurements: designReadings(includeToday: true),
        events: designEvents(),
      );
      await tapAndSettle(tester, navItem('Andamento'));
      expect(find.text('Eventi nel periodo'), findsNothing);
      expect(
        find.text('Evento 1: Meno sale a tavola, 18 maggio'),
        findsNothing,
      );
      // The rest of the screen is unchanged.
      expect(find.text('Trimestre a confronto'), findsOneWidget);
      expect(find.text('3 eventi'), findsOneWidget);

      await tapAndSettle(tester, find.widgetWithText(Material, 'Eventi').first);
      expect(state.settings.eventsInChart, isTrue);
      expect(find.text('Eventi nel periodo'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Evento 3: Camminata ogni giorno, 24 agosto'),
        findsWidgets,
      );
      // The latest event is selected.
      expect(find.text('127/80'), findsOneWidget);

      // Another event from its chip.
      await tapAndSettle(tester, find.text('1 lug'));
      expect(find.text('Nuovo lavoro vicino a casa'), findsOneWidget);
      expect(find.text('−7/−5'), findsOneWidget);

      await tapAndSettle(tester, find.text('Confronta prima e dopo'));
      expect(find.text('Prima e dopo'), findsOneWidget);
      expect(find.text('−7/−5 mmHg'), findsOneWidget);
      expect(find.text('141 → 134'), findsOneWidget);
      expect(find.text('4 su 4 → 3 su 4'), findsOneWidget);
    });

    testWidgets('an event without a chart line is not drawn', (tester) async {
      final events = designEvents();
      await pumpApp(
        tester,
        measurements: designReadings(includeToday: true),
        events: [events[0], events[1], events[2].copyWith(showInChart: false)],
        settings: onboardedSettings.copyWith(eventsInChart: true),
      );
      await tapAndSettle(tester, navItem('Andamento'));
      expect(find.text('Eventi nel periodo'), findsOneWidget);
      expect(find.text('24 ago'), findsNothing);
      // The latest event with a line is selected.
      expect(find.text('Nuovo lavoro vicino a casa'), findsOneWidget);
    });
  });

  group('share', () {
    testWidgets('events in the export and the PDF', (tester) async {
      final events = designEvents();
      await pumpApp(
        tester,
        measurements: designReadings(includeToday: true),
        events: [events[0], events[1].copyWith(inReport: false), events[2]],
      );
      await tapAndSettle(tester, navItem('Condividi'));
      expect(
        find.text('5 aprile 2026 – 27 settembre 2026 · 24 misure · 2 eventi'),
        findsOneWidget,
      );
      expect(find.text('Eventi annotati (2)'), findsOneWidget);
      // Still there next to the events.
      expect(find.text('Sopra soglia'), findsOneWidget);
    });

    test('the PDF builds with and without events', () async {
      final data = ReportData.build(
        measurements: designReadings(includeToday: true),
        events: designEvents(),
        settings: onboardedSettings,
        range: ReportRange.all,
        now: designNow,
      );
      expect(data.events.map((e) => '${e.beforeAvg}→${e.afterAvg}'), [
        '141/91→140/90',
        '141/89→134/84',
        '129/82→127/80',
      ]);
      for (final events in [true, false]) {
        final bytes = await buildReportPdf(
          data,
          ReportOptions(events: events),
          itL10n,
          itDates,
        );
        expect(bytes, isNotEmpty);
      }
    });
  });
}
