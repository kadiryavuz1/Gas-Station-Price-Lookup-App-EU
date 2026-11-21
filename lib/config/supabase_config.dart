/// Supabase connection settings.
///
/// Values are injected at build/run time via `--dart-define` (or
/// `--dart-define-from-file`) so that no backend credentials are ever
/// committed to source control.
///
/// Example:
/// ```
/// flutter run --dart-define-from-file=dart_define.json
/// ```
///
/// See `dart_define.json.example` and README.md for details.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');

  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether both values were supplied at build time.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
