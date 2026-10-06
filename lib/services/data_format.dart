/// Versioning of the saved data, shared by the storage on the phone and by
/// the backup files, so that both can be read after the app changes.
///
/// The data is a JSON document
/// `{"measurements": [...], "events": [...], "settings": {...}}`.
///
/// - Adding an optional field needs nothing: older data lacks it and gets
///   the default, older apps ignore it.
/// - Renaming, removing or changing the meaning of a field needs a new
///   version: bump [dataVersion] and add to [dataMigrations] the step that
///   turns a document of the previous version into the new one.
library;

typedef DataDocument = Map<String, Object?>;
typedef DataMigration = DataDocument Function(DataDocument doc);

/// Version of the data written by this app.
///
/// 2: life events ("events"). A new list, not an optional field: an older
/// app restoring a backup would drop the events without a word, so it has
/// to refuse it as too new instead.
const dataVersion = 2;

/// `dataMigrations[n]` upgrades a document from version n to n + 1.
const dataMigrations = <int, DataMigration>{1: _v1ToV2};

DataDocument _v1ToV2(DataDocument doc) => {
  ...doc,
  'events': doc['events'] ?? <Object?>[],
};

/// The data comes from a newer app, which may have changed its meaning.
class DataTooNewException implements Exception {
  const DataTooNewException(this.version);

  final int version;

  @override
  String toString() => 'Data version $version is newer than $dataVersion';
}

/// Brings [doc], written with version [from], up to [to] one step at a time.
DataDocument migrateData(
  DataDocument doc,
  int from, {
  int to = dataVersion,
  Map<int, DataMigration> migrations = dataMigrations,
}) {
  if (from > to) throw DataTooNewException(from);
  var result = doc;
  for (var v = from; v < to; v++) {
    final step = migrations[v];
    if (step == null) throw StateError('No migration from version $v');
    result = step(result);
  }
  return result;
}
