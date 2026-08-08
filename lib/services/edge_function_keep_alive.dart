// lib/services/edge_function_keep_alive.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Edge Functions (Deno isolates) cold-start on their own
/// schedule, separate from the database pause [SupabaseKeepAlive] guards
/// against. Pings `background-identify` with a trivial `{ping: true}`
/// body — handled before any candidate/image work in that function (see
/// its own comment) — so this never calls the Claude API or burns any
/// quota; it only keeps the isolate warm for the next real call.
class EdgeFunctionKeepAlive {
  final SupabaseClient _client;
  Timer? _timer;

  EdgeFunctionKeepAlive(this._client);

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
      await _client.functions
          .invoke('background-identify', body: {'ping': true});
    } catch (_) {
      // Best-effort — a failed ping just means the next real call might
      // pay a cold-start cost; nothing here for the user to act on.
    }
  }
}
