// lib/features/notifications/services/push_subscription_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/web_push_service.dart';

class PushSubscriptionService {
  final SupabaseClient _client;
  PushSubscriptionService(this._client);

  Future<void> save(String deviceId, PushSubscriptionInfo sub) async {
    try {
      await _client.from('push_subscriptions').insert({
        'device_id': deviceId,
        'endpoint': sub.endpoint,
        'p256dh': sub.p256dh,
        'auth': sub.auth,
      });
    } on PostgrestException catch (e) {
      // 23505 = unique_violation on endpoint — this exact browser
      // subscription is already recorded (e.g. a previous save succeeded
      // but the app then re-ran subscribe() on a later launch, which
      // push.js correctly treats as a no-op). Already in the desired
      // state, so this isn't a failure.
      if (e.code != '23505') rethrow;
    }
  }

  Future<void> remove(String deviceId) async {
    await _client.from('push_subscriptions').delete().eq('device_id', deviceId);
  }

  /// Best-effort trigger for today's push send — see
  /// supabase/push_client_trigger.sql for why this exists on the client at
  /// all: the pg_cron job meant to fire this daily doesn't reliably run on
  /// this project, so whichever device happens to open the app after 7am
  /// nudges it instead. Idempotent server-side (per-device, via
  /// get_daily_push_targets()'s last_pushed_at check), so calling this from
  /// many different devices throughout the day is safe.
  Future<void> triggerDailySend() async {
    await _client.rpc('client_trigger_daily_push');
  }
}
