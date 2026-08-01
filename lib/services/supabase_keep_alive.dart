// lib/services/supabase_keep_alive.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Free-tier Supabase projects pause after a period of inactivity, so
/// whichever request happens to arrive first after a pause eats a multi-
/// second cold-start penalty. Pinging a tiny table periodically for as long
/// as the app is open keeps the project warm so real queries don't pay that
/// cost.
class SupabaseKeepAlive {
  final SupabaseClient _client;
  Timer? _timer;

  SupabaseKeepAlive(this._client);

  void start() {
    _timer?.cancel();
    unawaited(_ping());
    _timer = Timer.periodic(const Duration(minutes: 4), (_) => _ping());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _ping() async {
    try {
      await _client.from('plant_families').select('id').limit(1);
    } catch (_) {
      // Best-effort — a failed ping just means the next real query might
      // hit a cold start; nothing here for the user to act on.
    }
  }
}
