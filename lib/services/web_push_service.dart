// lib/services/web_push_service.dart
import 'dart:convert';
import 'dart:js_interop';

@JS('uenrPush.isSupported')
external JSBoolean _isSupported();

@JS('uenrPush.permissionState')
external JSString _permissionState();

@JS('uenrPush.requestPermission')
external JSPromise<JSString> _requestPermission();

@JS('uenrPush.subscribe')
external JSPromise<JSString?> _subscribe(JSString vapidPublicKey);

@JS('uenrPush.getExistingSubscription')
external JSPromise<JSString?> _getExistingSubscription();

@JS('uenrPush.unsubscribe')
external JSPromise<JSBoolean> _unsubscribe();

/// Everything the server needs to encrypt and address a push message to one
/// specific browser install — mirrors the shape push.js's toSubscriptionJson
/// returns (as a JSON string, decoded here rather than read off a JS object).
class PushSubscriptionInfo {
  final String endpoint;
  final String p256dh;
  final String auth;
  const PushSubscriptionInfo({required this.endpoint, required this.p256dh, required this.auth});

  factory PushSubscriptionInfo.fromJson(Map<String, dynamic> json) => PushSubscriptionInfo(
        endpoint: json['endpoint'] as String,
        p256dh: json['p256dh'] as String,
        auth: json['auth'] as String,
      );
}

/// Web Push subscribe/unsubscribe bridge — web-only, see web/push.js and
/// web/push_sw.js (the service worker that actually receives push messages
/// and shows the resulting notification).
class WebPushService {
  static bool get isSupported => _isSupported().toDart;

  /// 'granted' | 'denied' | 'default' | 'unsupported'
  static String get permissionState => _permissionState().toDart;

  static Future<String> requestPermission() async => (await _requestPermission().toDart).toDart;

  static Future<PushSubscriptionInfo?> getExistingSubscription() async {
    final result = await _getExistingSubscription().toDart;
    if (result == null) return null;
    return PushSubscriptionInfo.fromJson(jsonDecode(result.toDart) as Map<String, dynamic>);
  }

  /// No-ops (returns the existing subscription) if this browser is already
  /// subscribed — see push.js's subscribe(), which checks before calling
  /// pushManager.subscribe() again.
  static Future<PushSubscriptionInfo?> subscribe(String vapidPublicKey) async {
    final result = await _subscribe(vapidPublicKey.toJS).toDart;
    if (result == null) return null;
    return PushSubscriptionInfo.fromJson(jsonDecode(result.toDart) as Map<String, dynamic>);
  }

  static Future<bool> unsubscribe() async => (await _unsubscribe().toDart).toDart;
}
