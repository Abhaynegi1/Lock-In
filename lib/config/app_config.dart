/// Application Configuration & Secure Environment Declarations
/// Configurable at build/run time via:
/// `--dart-define=BATTLE_SERVER_URL=...`
/// `--dart-define=SUPABASE_URL=...`
/// `--dart-define=SUPABASE_ANON_KEY=...`
class AppConfig {
  AppConfig._();

  /// Dedicated Node.js WebSocket Battle Server URL
  static const String battleServerUrl = String.fromEnvironment(
    'BATTLE_SERVER_URL',
    defaultValue: 'wss://lock-in-websocket.onrender.com',
  );

  /// Supabase project URL (used for optional Google OAuth & Cloud Backup)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xnnoastptbfeleguojzr.supabase.co',
  );

  /// Supabase public publishable/anon key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_eLVXDDrtl2z9kH5duJFIpQ_-pQvaoES',
  );
}
