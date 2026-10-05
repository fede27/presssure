// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'PressSure';

  @override
  String get navToday => 'Oggi';

  @override
  String get navDiary => 'Diario';

  @override
  String get navTrends => 'Andamento';

  @override
  String get navShare => 'Condividi';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get done => 'Fatto';

  @override
  String get close => 'Chiudi';

  @override
  String get delete => 'Elimina';

  @override
  String get change => 'Cambia';

  @override
  String get add => 'Aggiungi';

  @override
  String get back => 'Indietro';

  @override
  String comingSoon(String feature) {
    return '$feature: in arrivo.';
  }

  @override
  String errorGeneric(String error) {
    return 'Non è stato possibile completare: $error';
  }

  @override
  String weekdayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'lunedì',
      'tue': 'martedì',
      'wed': 'mercoledì',
      'thu': 'giovedì',
      'fri': 'venerdì',
      'sat': 'sabato',
      'sun': 'domenica',
      'other': 'giorno',
    });
    return '$_temp0';
  }

  @override
  String weekdayInList(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'lunedì',
      'tue': 'martedì',
      'wed': 'mercoledì',
      'thu': 'giovedì',
      'fri': 'venerdì',
      'sat': 'sabato',
      'sun': 'domenica',
      'other': 'giorno',
    });
    return '$_temp0';
  }

  @override
  String onWeekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'il lunedì',
      'tue': 'il martedì',
      'wed': 'il mercoledì',
      'thu': 'il giovedì',
      'fri': 'il venerdì',
      'sat': 'il sabato',
      'sun': 'la domenica',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String nounReadings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'misure',
      one: 'misura',
    );
    return '$_temp0';
  }

  @override
  String readingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count misure',
      one: '1 misura',
    );
    return '$_temp0';
  }

  @override
  String inARow(int count) {
    return '$count di fila';
  }

  @override
  String readingsInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count misure di fila',
      one: '1 misura di fila',
    );
    return '$_temp0';
  }

  @override
  String progressOf(int value, int target) {
    return '$value su $target';
  }

  @override
  String get scheduleDaily => 'ogni giorno';

  @override
  String scheduleWeekly(String weekday) {
    return 'ogni $weekday';
  }

  @override
  String scheduleBiweekly(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'ogni due lunedì',
      'tue': 'ogni due martedì',
      'wed': 'ogni due mercoledì',
      'thu': 'ogni due giovedì',
      'fri': 'ogni due venerdì',
      'sat': 'ogni due sabati',
      'sun': 'ogni due domeniche',
      'other': 'ogni due settimane',
    });
    return '$_temp0';
  }

  @override
  String scheduleMonthly(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'il primo lunedì del mese',
      'tue': 'il primo martedì del mese',
      'wed': 'il primo mercoledì del mese',
      'thu': 'il primo giovedì del mese',
      'fri': 'il primo venerdì del mese',
      'sat': 'il primo sabato del mese',
      'sun': 'la prima domenica del mese',
      'other': 'una volta al mese',
    });
    return '$_temp0';
  }

  @override
  String scheduleList(String days, String last) {
    return '$days e $last';
  }

  @override
  String get listSeparator => ', ';

  @override
  String partOfDay(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'mattina',
      'afternoon': 'pomeriggio',
      'other': 'sera',
    });
    return '$_temp0';
  }

  @override
  String greeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Buongiorno',
      'afternoon': 'Buon pomeriggio',
      'other': 'Buonasera',
    });
    return '$_temp0';
  }

  @override
  String relativeToday(String time) {
    return 'Oggi, $time';
  }

  @override
  String relativeYesterday(String time) {
    return 'Ieri, $time';
  }

  @override
  String relativeDate(String date, String time) {
    return '$date, $time';
  }

  @override
  String get todayLower => 'oggi';

  @override
  String get todayCapital => 'Oggi';

  @override
  String get latest => 'Ultima';

  @override
  String get categoryNonElevated => 'Ottimale';

  @override
  String get categoryElevated => 'Intermedia';

  @override
  String get categoryHigh => 'Alta';

  @override
  String bandNonElevated(int sys, int dia) {
    return 'Ottimale (sotto $sys/$dia)';
  }

  @override
  String bandElevated(int sysFrom, int sysTo, int diaFrom, int diaTo) {
    return 'Intermedia ($sysFrom–$sysTo / $diaFrom–$diaTo)';
  }

  @override
  String bandHigh(int sys, int dia) {
    return 'Sopra soglia ($sys/$dia)';
  }

  @override
  String get aboveThreshold => 'Sopra soglia';

  @override
  String get welcomeTitle => 'Il tuo diario della pressione, senza pensieri';

  @override
  String get welcomeFeaturePhoto =>
      'Fotografi il display, i valori li scrive l’app';

  @override
  String get welcomeFeaturePhotoCopy =>
      'Fotografi il display e copi i valori: presto li scriverà l’app da sola';

  @override
  String get welcomeFeatureReminder => 'Un promemoria nel giorno che scegli tu';

  @override
  String get welcomeFeatureExport => 'Esporti in PDF o CSV quando ti serve';

  @override
  String get welcomeFeatureLocal =>
      'I dati restano sul tuo telefono: niente account, niente server';

  @override
  String get welcomeNoticeTitle => 'Da sapere, una volta sola';

  @override
  String get welcomeNoticeBody =>
      'PressSure è un diario personale: non è un dispositivo medico e non fa diagnosi. Le fasce predefinite seguono le linee guida europee ESC 2024 e puoi cambiarle. Per dubbi sulla tua salute, rivolgiti al tuo medico.';

  @override
  String get welcomeStart => 'Ho capito, iniziamo';

  @override
  String get habitTitle => 'La tua abitudine';

  @override
  String get habitIntro =>
      'Scegli un ritmo che riesci a mantenere. Promemoria, grafici e report si adattano.';

  @override
  String get habitHowOften => 'Ogni quanto misuri?';

  @override
  String get frequencyDaily => 'Ogni giorno';

  @override
  String get frequencyFewTimesWeek => 'In più giorni della settimana';

  @override
  String get frequencyWeekly => 'Una volta a settimana';

  @override
  String get frequencyBiweekly => 'Ogni due settimane';

  @override
  String get frequencyMonthly => 'Una volta al mese';

  @override
  String get habitWhen => 'Quando';

  @override
  String get habitPickTwoDays => 'Scegli almeno due giorni';

  @override
  String get habitReminderTime => 'Ora del promemoria';

  @override
  String get habitKeepOnTrack => 'Per non perdere il filo';

  @override
  String get habitRemindNextDay => 'Se salto, ricordamelo il giorno dopo';

  @override
  String get habitRemindNextDayHint =>
      'Una sola volta, poi aspetta il prossimo appuntamento';

  @override
  String get habitMonthlySummary => 'Riepilogo a fine mese';

  @override
  String get habitMonthlySummaryHint =>
      'Es. «Settembre: 4 misure, media 125/80»';

  @override
  String habitPreviewHeading(String when, String time) {
    return 'Così arriva $when alle $time';
  }

  @override
  String get habitSaveAndStart => 'Salva e inizia';

  @override
  String habitCardSubtitle(String schedule, String part) {
    return 'La tua abitudine · $schedule $part';
  }

  @override
  String get todayFirstReading => 'La tua prima misura ti aspetta';

  @override
  String get todayDoneDaily => 'Fatto per oggi, ci vediamo domani';

  @override
  String todayDoneNext(String date) {
    return 'Fatto! Prossima misura $date';
  }

  @override
  String get todayIsTheDay => 'Oggi è il giorno della misura';

  @override
  String todayMissing(String date) {
    return 'Manca la misura di $date';
  }

  @override
  String get todayStartStreak => 'Ogni misura conta: inizia una serie.';

  @override
  String todayCompleteMonth(String month) {
    return 'Oggi chiudi $month al completo.';
  }

  @override
  String get achievements => 'Traguardi';

  @override
  String get takePhoto => 'Fotografa';

  @override
  String get byHand => 'A mano';

  @override
  String get habitAndReminders => 'Abitudine e promemoria';

  @override
  String periodDotsLabel(int total, int done, int missed) {
    return 'Ultimi $total appuntamenti: $done fatti, $missed saltati';
  }

  @override
  String lastReadingOn(String date) {
    return 'Ultima misura · $date';
  }

  @override
  String pulseValue(int pulse) {
    return 'Polso $pulse';
  }

  @override
  String pulseLower(int pulse) {
    return 'polso $pulse';
  }

  @override
  String previousValue(String value) {
    return 'la volta prima $value';
  }

  @override
  String previousReading(String value) {
    return 'misura precedente $value';
  }

  @override
  String get bandByEsc => 'fascia secondo le linee guida europee ESC 2024';

  @override
  String get bandByCustom => 'fascia secondo le tue soglie';

  @override
  String get last6Months => 'Ultimi 6 mesi';

  @override
  String get legendSingle => 'Singola misura';

  @override
  String get legendAvg4 => 'Media ultime 4';

  @override
  String get legendThreshold => 'Soglia';

  @override
  String get legendSkipped => 'Misure saltate';

  @override
  String get trendEmpty =>
      'Dopo qualche misura qui vedrai come cambia la tua pressione.';

  @override
  String quarterSide(String range, String readings) {
    return '$range · $readings';
  }

  @override
  String get emptyTitle => 'Ancora nessuna misura';

  @override
  String get emptyBody =>
      'Siediti con la schiena appoggiata, riposa cinque minuti e misura al braccio con il bracciale all’altezza del cuore. Poi segna i valori qui: fascia, grafici e report si costruiscono da soli.';

  @override
  String get scanReadTitle => 'Letto dalla foto';

  @override
  String get photoCopyTitle => 'Copia i valori dal display';

  @override
  String scanPhotoNotSaved(String when) {
    return '$when · la foto non viene salvata';
  }

  @override
  String get scanRetake => 'Rifai';

  @override
  String get scanSure => 'Letto con sicurezza';

  @override
  String get scanUnsure =>
      'Cifra poco nitida nella foto: confronta con il display e correggi se serve.';

  @override
  String get scanMissing => 'Non trovato nella foto: copialo dal display.';

  @override
  String get scanNothingRead =>
      'Non riesco a leggere i valori: riprova evitando i riflessi, oppure inseriscili a mano.';

  @override
  String get scanTitle => 'Fotografa il display';

  @override
  String get scanFlash => 'Luce';

  @override
  String get scanFrameHint => 'Inquadra il display nella cornice';

  @override
  String get scanGlareHint => 'Evita i riflessi: inclina un poco il telefono';

  @override
  String get scanFromGallery => 'Da galleria';

  @override
  String get scanShutter => 'Scatta';

  @override
  String get scanReading => 'Leggo i valori…';

  @override
  String get scanCameraError =>
      'Non riesco ad aprire la fotocamera. Riprova, oppure usa una foto dalla galleria.';

  @override
  String get scanCameraNeeded =>
      'Per fotografare il display PressSure ha bisogno della fotocamera. La foto non viene salvata.';

  @override
  String get scanCameraBlocked =>
      'Il permesso della fotocamera è stato negato. Attivalo nelle impostazioni dell’app, poi torna qui.';

  @override
  String get scanAllow => 'Consenti';

  @override
  String get scanOpenSettings => 'Apri impostazioni';

  @override
  String get betaTitle => 'Programma beta';

  @override
  String get keepScansTitle => 'Aiutami a migliorare la lettura';

  @override
  String keepScansBody(int count, String email) {
    return 'Tiene su questo telefono le ultime $count foto del display, con i valori letti dall’app e quelli che salvi. Non parte nulla da solo: puoi inviarle tu per email a $email. Spegnendo, vengono cancellate.';
  }

  @override
  String keptScansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count letture tenute',
      one: '1 lettura tenuta',
      zero: 'Nessuna lettura tenuta',
    );
    return '$_temp0';
  }

  @override
  String get sendScans => 'Invia per analisi';

  @override
  String get clearScans => 'Cancella';

  @override
  String get scansCleared => 'Letture tenute cancellate';

  @override
  String get keepScansYes => 'Sì, tieni le letture';

  @override
  String get keepScansNo => 'No, grazie';

  @override
  String get noMailApp => 'Nessuna app di posta disponibile per l’invio.';

  @override
  String feedbackSubject(String version) {
    return 'PressSure $version: letture del display';
  }

  @override
  String feedbackBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count letture',
      one: '1 lettura',
    );
    return 'In allegato $_temp0 del display fatte con PressSure: foto, valori letti dall’app e valori salvati.\n\nNote (facoltative):\n';
  }

  @override
  String scanPhotoKept(String when) {
    return '$when · la foto resta sul telefono per l’analisi';
  }

  @override
  String get scanRetry => 'Riprova';

  @override
  String get entryNewTitle => 'Controlla e salva';

  @override
  String get entryEditTitle => 'Modifica misura';

  @override
  String get deleteReading => 'Elimina misura';

  @override
  String get deleteConfirmTitle => 'Eliminare la misura?';

  @override
  String get deleteConfirmBody =>
      'La misura sparisce dal diario, dai grafici e dai report. Non si può annullare.';

  @override
  String get errSysRequired => 'Inserisci la sistolica';

  @override
  String get errDiaRequired => 'Inserisci la diastolica';

  @override
  String errRange(int min, int max) {
    return 'Tra $min e $max';
  }

  @override
  String get errSysAboveDia => 'Deve superare la diastolica';

  @override
  String get systolic => 'Sistolica';

  @override
  String get diastolic => 'Diastolica';

  @override
  String get pulse => 'Polso';

  @override
  String get optional => 'facoltativo';

  @override
  String get pickDayHelp => 'Giorno della misura';

  @override
  String get pickTimeHelp => 'Ora della misura';

  @override
  String get whenReading => 'Misura';

  @override
  String get whenManual => 'Inserita a mano';

  @override
  String get scanTooltip => 'Fotografa il display';

  @override
  String categoryHint(String category, String source) {
    return 'Fascia «$category» $source';
  }

  @override
  String get hintSourceEsc => 'secondo ESC 2024';

  @override
  String get hintSourceCustom => 'secondo le tue soglie';

  @override
  String get contextTitle => 'Contesto';

  @override
  String get arm => 'Braccio';

  @override
  String get armLeft => 'Sinistro';

  @override
  String get armRight => 'Destro';

  @override
  String get posture => 'Posizione';

  @override
  String get postureSitting => 'Seduto';

  @override
  String get postureStanding => 'In piedi';

  @override
  String get postureLying => 'Sdraiato';

  @override
  String get note => 'Nota';

  @override
  String get noteHint => 'Es. caffè mezz’ora prima, dormito poco';

  @override
  String get secondReading => 'Seconda lettura';

  @override
  String get secondAverageInfo =>
      'Il diario salverà la media delle due letture.';

  @override
  String secondAverageValue(String value) {
    return 'Verrà salvata la media: $value';
  }

  @override
  String get secondWaitTitle => 'Rilassati, ancora un attimo';

  @override
  String get secondWaitBody => 'Allo scadere misura di nuovo, stesso braccio.';

  @override
  String get secondOptionalTitle => 'Seconda lettura? Facoltativa';

  @override
  String get secondOptionalBody =>
      'Se la fai dopo un minuto, l’app salva la media.';

  @override
  String timerSkip(String time) {
    return '$time · Salta';
  }

  @override
  String get timerStart => 'Timer 1:00';

  @override
  String get saveReading => 'Salva misurazione';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String fieldSemantics(String label, String unit) {
    return '$label in $unit';
  }

  @override
  String get newBadge => 'NUOVO BADGE';

  @override
  String get readingSaved => 'MISURA SALVATA';

  @override
  String celebrateTitleBadge(String title) {
    return '$title!';
  }

  @override
  String celebrateTitleStreak(String streak) {
    return 'Fatto, $streak';
  }

  @override
  String celebrateInDiary(String value) {
    return '$value è nel diario.';
  }

  @override
  String celebrateSince(String date, String readings, int total) {
    return 'Dal $date $readings su $total previste.';
  }

  @override
  String andMoreBadges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' E altri $count badge.',
      one: ' E un altro badge.',
    );
    return '$_temp0';
  }

  @override
  String jollyLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hai $count jolly se salti una misura.',
      one: 'Hai un jolly se salti una misura.',
      zero: 'Nessun jolly: non saltare la prossima.',
    );
    return '$_temp0';
  }

  @override
  String lowestSince(String value, String month) {
    return '$value, la più bassa da $month';
  }

  @override
  String readingStored(String value) {
    return '$value salvata';
  }

  @override
  String avgOfLast(int count, String value) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Media delle ultime $count misure: $value.',
      one: 'Ultima misura: $value.',
    );
    return '$_temp0';
  }

  @override
  String almostBadge(String title) {
    return 'Quasi «$title»';
  }

  @override
  String streakRecordSemantics(int current) {
    return 'Serie record: $current';
  }

  @override
  String streakToBeat(int current, int target, int record) {
    return '$current su $target per battere il record di $record';
  }

  @override
  String streakNow(int count) {
    return '$count ora';
  }

  @override
  String get newRecord => 'nuovo record!';

  @override
  String recordValue(int count) {
    return 'record $count';
  }

  @override
  String savedAt(String when) {
    return 'Misura salvata · $when';
  }

  @override
  String get higherThanUsual => 'Oggi è più alta del solito';

  @override
  String get aboveThresholdToday => 'Oggi è sopra la soglia';

  @override
  String usuallyAround(String value) {
    return 'Di solito sei intorno a $value. ';
  }

  @override
  String get remeasureHint =>
      'Se vuoi, puoi rimisurare dopo qualche minuto di riposo: il diario le tiene tutte e due.';

  @override
  String get veryHighWarning =>
      'Valori così alti vanno ricontrollati. Se si confermano o se non ti senti bene, contatta il tuo medico o il 112.';

  @override
  String get remeasure => 'Rimisura';

  @override
  String get addNote => 'Aggiungi nota';

  @override
  String badgeNamed(String title) {
    return 'Badge «$title»';
  }

  @override
  String get honestBody => 'Anche i giorni no fanno parte del diario.';

  @override
  String streakSafe(String streak) {
    return 'Serie salva · $streak';
  }

  @override
  String diarySubtitle(String readings, String month, String schedule) {
    return '$readings da $month · $schedule';
  }

  @override
  String get searchDiary => 'Cerca nel diario';

  @override
  String get closeSearch => 'Chiudi ricerca';

  @override
  String get searchHint => 'Cerca nelle note';

  @override
  String get filterAll => 'Tutte';

  @override
  String get filterNotes => 'Con note';

  @override
  String get noMatch => 'Nessuna misura corrisponde.';

  @override
  String monthSummary(String readings, String avg) {
    return '$readings · media $avg';
  }

  @override
  String get averageOfTwo => 'media di 2';

  @override
  String get readFromPhoto => 'Letto da foto';

  @override
  String gapLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count misure saltate',
      one: '1 misura saltata',
    );
    return '$_temp0';
  }

  @override
  String get newReading => 'Nuova misura';

  @override
  String get diaryEmptyTitle => 'Il diario è vuoto';

  @override
  String get diaryEmptyBody =>
      'Ogni misura che salvi finisce qui, raggruppata per mese.';

  @override
  String get diaryAddFirst => 'Aggiungi la prima misura';

  @override
  String get range3m => '3 mesi';

  @override
  String get range6m => '6 mesi';

  @override
  String get range1y => '1 anno';

  @override
  String get rangeAll => 'Tutto';

  @override
  String get exportAndShare => 'Esporta e condividi';

  @override
  String get trendsEmpty =>
      'Nessuna misura in questo periodo. Il grafico si riempie con le prossime.';

  @override
  String lastNReadings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ultime $count misure',
      one: 'Ultima misura',
    );
    return '$_temp0';
  }

  @override
  String readingsInRange(String readings, String range) {
    return '$readings in $range';
  }

  @override
  String avgPulse(int pulse) {
    return 'Polso medio $pulse';
  }

  @override
  String get yourReadings => 'Le tue misure';

  @override
  String get sysShort => 'Sist.';

  @override
  String get diaShort => 'Diast.';

  @override
  String get quarterCompare => 'Trimestre a confronto';

  @override
  String quarterNeedTwo(String first, String second) {
    return 'Servono misure in due trimestri: $first e $second.';
  }

  @override
  String get regularity => 'Regolarità';

  @override
  String regularityCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done misure su $total previste',
      one: '1 misura su $total previste',
    );
    return '$_temp0';
  }

  @override
  String regularityLabel(int done, int total) {
    return '$done misurate su $total';
  }

  @override
  String get bandsTitle => 'Misure per fascia';

  @override
  String bandsRecent(String month, int below, int total, int sys, int dia) {
    return 'Da $month $below misure su $total sono sotto $sys/$dia.';
  }

  @override
  String get bandsDefaultEsc =>
      'Fasce predefinite: linee guida europee ESC 2024, misurazione a domicilio.';

  @override
  String get bandsCustom =>
      'Soglie personalizzate. Le linee guida ESC 2024 per la misura a domicilio usano 135/85.';

  @override
  String get changeThresholds => 'Cambia soglie';

  @override
  String get restoreEsc => 'Ripristina ESC 2024';

  @override
  String get thresholdsDoctorNote => 'Cambiale solo se te lo indica il medico.';

  @override
  String get thresholdsErrRange => 'Inserisci valori tra 40 e 250.';

  @override
  String get thresholdsErrOrder =>
      'La fascia intermedia deve stare sotto la soglia.';

  @override
  String get reportScreenSubtitle =>
      'Il tuo diario in PDF o CSV, quando ti serve';

  @override
  String get previewTitle => 'Anteprima report';

  @override
  String get neverExported => 'Non hai ancora esportato il diario';

  @override
  String lastExported(String date) {
    return 'Ultima esportazione: $date';
  }

  @override
  String newSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count misure nuove da allora',
      one: '1 misura nuova da allora',
    );
    return '$_temp0';
  }

  @override
  String get rangeSinceLast => 'Solo le nuove';

  @override
  String get noReadingsInPeriod => 'Nessuna misura nel periodo';

  @override
  String rangeLabel(String from, String to, String readings) {
    return '$from – $to · $readings';
  }

  @override
  String get includeTitle => 'Cosa includere';

  @override
  String get includeChart => 'Grafico dell’andamento';

  @override
  String get includeTable => 'Tabella di tutte le misurazioni';

  @override
  String get includeNotes => 'Note';

  @override
  String get downloadPdf => 'Scarica PDF';

  @override
  String get share => 'Condividi';

  @override
  String get exportCsv => 'Esporta i dati in CSV (per Excel)';

  @override
  String get pdfA4 => 'PDF A4';

  @override
  String get previewReadings => 'Misure';

  @override
  String get previewAverage => 'Media';

  @override
  String get previewLast4 => 'Ultime 4';

  @override
  String get openPreview => 'Apri anteprima';

  @override
  String get openPreviewSemantics => 'Apri l’anteprima del PDF';

  @override
  String get csvSubject => 'Diario della pressione (CSV)';

  @override
  String get fileNameBase => 'PressSure_diario';

  @override
  String get notYetExported => 'Non hai ancora esportato il diario.';

  @override
  String get inARowStat => 'misure di fila';

  @override
  String get recordInARow => 'record di fila';

  @override
  String get totalReadings => 'misure totali';

  @override
  String jollyAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jolly: $count disponibili',
      one: 'Jolly: 1 disponibile',
      zero: 'Jolly: nessuno disponibile',
    );
    return '$_temp0';
  }

  @override
  String jollyNext(int count) {
    return 'prossimo tra $count';
  }

  @override
  String jollyNextSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prossimo jolly tra $count misure',
      one: 'Prossimo jolly tra 1 misura',
    );
    return '$_temp0';
  }

  @override
  String get jollyFull => 'massimo raggiunto';

  @override
  String jollyBody(int every, int max) {
    return 'Salti una misura? Il jolly tiene viva la serie. Ne guadagni uno ogni $every misure previste, fino a $max.';
  }

  @override
  String get groupConsistency => 'Costanza';

  @override
  String get groupHabits => 'Buone abitudini';

  @override
  String get groupTrend => 'Andamento';

  @override
  String trendGroupNote(int sys, int dia) {
    return 'soglia $sys/$dia, sulle medie mensili';
  }

  @override
  String get personalRecords => 'Record personali';

  @override
  String get longestStreak => 'Serie più lunga';

  @override
  String get lowestMonth => 'Mese con la media più bassa';

  @override
  String get onSchedule => 'Misure fatte nei giorni previsti';

  @override
  String onScheduleValue(int done, int total, String percent) {
    return '$done su $total · $percent';
  }

  @override
  String badgeSemantics(String title, String state, String detail) {
    return '$title, $state, $detail';
  }

  @override
  String get badgeUnlocked => 'sbloccato';

  @override
  String get badgeLocked => 'da sbloccare';

  @override
  String get newTag => 'NUOVO';

  @override
  String get badgeFirstStep => 'Primo passo';

  @override
  String get badgeTwoMonths => 'Due mesi di fila';

  @override
  String get badgeThreeMonths => 'Tre mesi di fila';

  @override
  String get badgeSixMonths => 'Sei mesi di diario';

  @override
  String get badgeMonthComplete => 'Mese completo';

  @override
  String get badgeComeback => 'Ripartenza';

  @override
  String get badgeNoPause => 'Mezzo anno senza pause';

  @override
  String get badgeBeatRecord => 'Batti il record';

  @override
  String get badgeYear => 'Un anno di diario';

  @override
  String monthsProgress(int value, int target) {
    return '$value mesi su $target';
  }

  @override
  String get badgeHonest => 'Diario sincero';

  @override
  String get badgeLynx => 'Occhio di lince';

  @override
  String get badgeFirstPdf => 'Primo PDF condiviso';

  @override
  String get badgeNotes => 'Note che aiutano';

  @override
  String get badgeDouble => 'Doppia lettura';

  @override
  String get badgeMonthBelow => 'Mese sotto soglia';

  @override
  String get badgeTrendDown => 'Tendenza in calo';

  @override
  String get badgeQuarterBelow => 'Trimestre sotto soglia';

  @override
  String monthCompleteDetail(String month, int count) {
    return '$month, $count su $count';
  }

  @override
  String get monthCompleteHint => 'tutte le misure di un mese';

  @override
  String comebackDetail(String when) {
    return '$when, dopo la pausa';
  }

  @override
  String get comebackHint => 'riprendi dopo una pausa';

  @override
  String get beatRecordHint => 'dopo la prima serie';

  @override
  String get honestDetail => 'registri anche i giorni no';

  @override
  String get firstPdfHint => 'esporta il diario';

  @override
  String monthAverage(String month, String value) {
    return '$month $value';
  }

  @override
  String monthBelowHint(int sys, int dia) {
    return 'media del mese sotto $sys/$dia';
  }

  @override
  String trendDetail(String delta) {
    return '$delta tra trimestri';
  }

  @override
  String get trendHint => 'servono due trimestri';

  @override
  String sinceDate(String date) {
    return 'da $date';
  }

  @override
  String unlocksOn(String date) {
    return 'si sblocca il $date';
  }

  @override
  String chartDescription(
    String from,
    String to,
    int sys1,
    int sys2,
    int dia1,
    int dia2,
  ) {
    return 'Misure da $from a $to: sistolica da $sys1 a $sys2, diastolica da $dia1 a $dia2 mmHg';
  }

  @override
  String bpSemantics(int sys, int dia) {
    return '$sys su $dia millimetri di mercurio';
  }

  @override
  String get reminderChannel => 'Promemoria';

  @override
  String get reminderChannelDescription =>
      'Promemoria per misurare la pressione';

  @override
  String get reminderTitleDaily => 'È ora: 2 minuti per la pressione';

  @override
  String reminderTitleDay(String weekday) {
    return 'È $weekday: 2 minuti per la pressione';
  }

  @override
  String get reminderBodyFirst =>
      'Siediti, rilassati e registra la tua prima misura.';

  @override
  String reminderBody(String value) {
    return 'L’ultima volta $value. Misura e segna i valori: hai finito.';
  }

  @override
  String nudgeTitle(String weekday) {
    return 'Ieri era $weekday';
  }

  @override
  String get nudgeBody => 'Nessun problema: misura oggi e la serie continua.';

  @override
  String summaryTitle(String month) {
    return 'Il tuo $month';
  }

  @override
  String summaryEmpty(String month) {
    return '$month: nessuna misura. Il mese nuovo è un buon inizio.';
  }

  @override
  String summaryBody(String month, int count, String avg) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count misure',
      one: '1 misura',
    );
    return '$month: $_temp0, media $avg.';
  }

  @override
  String get reportTitle => 'Diario della pressione';

  @override
  String reportSubtitle(String schedule, String from, String to) {
    return 'Misure a domicilio, $schedule · $from – $to';
  }

  @override
  String generatedOn(String date) {
    return 'Generato il $date';
  }

  @override
  String get averagePulse => 'Polso medio';

  @override
  String get reportChart => 'Andamento';

  @override
  String get reportNotes => 'Note';

  @override
  String get reportAllReadings => 'Tutte le misure ';

  @override
  String reportBoldNote(int sys, int dia) {
    return '· in grassetto quelle sopra soglia ($sys/$dia)';
  }

  @override
  String get colDate => 'Data';

  @override
  String get colTime => 'Ora';

  @override
  String get noReading => 'nessuna misura';

  @override
  String reportFooter(int sys, int dia, String source) {
    return '* con nota. Fasce e soglia $sys/$dia mmHg: $source. Valori inseriti dall\'utente, a mano o dalla foto del display. PressSure è un diario personale, non un dispositivo medico.';
  }

  @override
  String get footerSourceEsc =>
      'linee guida europee ESC 2024 per la misurazione a domicilio';

  @override
  String get footerSourceCustom => 'soglie personalizzate';

  @override
  String pageOf(int page, int total) {
    return 'Pagina $page di $total';
  }

  @override
  String get csvSource => 'Origine';

  @override
  String get csvDouble => 'Doppia lettura';

  @override
  String get csvPhoto => 'foto';

  @override
  String get csvManual => 'manuale';

  @override
  String get yes => 'sì';

  @override
  String get no => 'no';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String reminderSummary(String schedule, String time) {
    return '$schedule · $time';
  }

  @override
  String get thresholdsSection => 'Soglie delle fasce';

  @override
  String get thresholdsIntro =>
      'Predefinite: linee guida europee ESC 2024, misura a domicilio. Valgono per grafici, diario, traguardi ed esportazioni.';

  @override
  String get elevatedFrom => 'Intermedia da';

  @override
  String get aboveThresholdFrom => 'Sopra soglia da';

  @override
  String thresholdFieldLabel(String band, String value) {
    return '$band, $value';
  }

  @override
  String get dataTitle => 'I tuoi dati';

  @override
  String get dataIntro =>
      'Restano solo su questo telefono. Per cambiare telefono o non perderli, salva un file di backup dove preferisci.';

  @override
  String get saveBackup => 'Salva backup';

  @override
  String get restoreBackup => 'Ripristina';

  @override
  String get backupReminder => 'Ricordami un backup ogni mese';

  @override
  String lastBackup(String date) {
    return 'Ultimo backup: $date';
  }

  @override
  String get noBackupYet => 'Nessun backup finora';

  @override
  String get backupSaved => 'Backup salvato';

  @override
  String get backupFileBase => 'PressSure_backup';

  @override
  String get restoreTitle => 'Ripristinare il backup?';

  @override
  String restoreBody(String date, String readings) {
    return 'Diario, abitudine, promemoria e soglie su questo telefono vengono sostituiti da quelli del backup del $date ($readings). Non si può annullare.';
  }

  @override
  String restoreDone(String readings) {
    return 'Diario ripristinato: $readings';
  }

  @override
  String get backupInvalid => 'Il file scelto non è un backup di PressSure.';

  @override
  String get backupTooNew =>
      'Questo backup viene da una versione più recente di PressSure: aggiorna l’app e riprova.';

  @override
  String get aboutThresholds => 'Avvertenza e fonti delle soglie';

  @override
  String get aboutDisclaimer => 'Avvertenza';

  @override
  String get aboutSources => 'Fonti delle soglie';

  @override
  String aboutBands(int elevSys, int elevDia, int highSys, int highDia) {
    return 'Fasce predefinite per la misura a domicilio: ottimale sotto $elevSys/$elevDia, intermedia da $elevSys/$elevDia (nelle linee guida «elevata»), sopra soglia da $highSys/$highDia mmHg.';
  }

  @override
  String get aboutSource =>
      'Fonte: 2024 ESC Guidelines for the management of elevated blood pressure and hypertension, European Heart Journal, 2024.';

  @override
  String get aboutCredits => 'Riconoscimenti';

  @override
  String get aboutModel =>
      'La lettura del display usa un modello addestrato sul dataset «Blood-Pressure-monitor-digit-reader» di naphop (Roboflow Universe), licenza CC BY 4.0.';

  @override
  String get version => 'Versione';

  @override
  String get deleteAllData => 'Cancella tutti i dati';

  @override
  String get deleteAllTitle => 'Cancellare tutti i dati?';

  @override
  String get deleteAllBody =>
      'Misure, abitudine e impostazioni vengono eliminate da questo telefono. Senza un backup non si possono recuperare.';

  @override
  String get deleteAllConfirm => 'Cancella tutto';

  @override
  String get backupReminderTitle => 'È ora di un backup';

  @override
  String get backupReminderBody =>
      'Salva una copia del diario dove preferisci: Impostazioni › I tuoi dati.';
}
