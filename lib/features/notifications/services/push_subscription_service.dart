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
}
