/// Compile-time configuration. Secrets are injected via `--dart-define`
/// and never committed to source or bundles as literals in code reviews.
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String appName = 'KSMS';

  static bool get isConfigured =>
      supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty;

  static String get missingConfigMessage =>
      'SUPABASE_URL / SUPABASE_ANON_KEY were not provided. '
      'Run the app with --dart-define=SUPABASE_URL=... '
      '--dart-define=SUPABASE_ANON_KEY=...';
}
