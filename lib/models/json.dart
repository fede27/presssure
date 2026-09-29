/// The enum value called [name], or [fallback] when it is missing or unknown
/// (e.g. a value added by a newer version of the app).
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
