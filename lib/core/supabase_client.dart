// lib/core/supabase_client.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads credentials from the bundled .env file so they are never committed
/// to source control and `flutter run` needs no extra CLI flags.
class SupabaseConfig {
  static String get url     => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    assert(
      url.isNotEmpty && anonKey.isNotEmpty,
      'SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env. '
      'See .env.example.',
    );
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

/// Shorthand accessor — use `supabase.from(...)` anywhere in the app.
SupabaseClient get supabase => Supabase.instance.client;
