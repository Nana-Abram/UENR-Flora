// web/push.js
//
// Web Push subscribe/unsubscribe bridge. Defines window.uenrPush, called
// from lib/services/web_push_service.dart. The actual push message
// handling (the 'push'/'notificationclick' listeners) lives in push_sw.js,
// the service worker — this file only manages the subscription lifecycle
// from the page context.
window.uenrPush = (function () {
  function isSupported() {
    return !!(window.isSecureContext && 'serviceWorker' in navigator && 'PushManager' in window);
  }

  function permissionState() {
    return typeof Notification === 'undefined' ? 'unsupported' : Notification.permission;
  }

  async function requestPermission() {
    if (typeof Notification === 'undefined') return 'unsupported';
    return await Notification.requestPermission();
  }

  // VAPID keys arrive from the server as URL-safe base64; PushManager wants
  // them as a raw Uint8Array.
  function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = atob(base64);
    return Uint8Array.from(Array.prototype.map.call(rawData, (c) => c.charCodeAt(0)));
  }

  // Returned as a JSON *string* rather than a plain JS object — keeps the
  // Dart side to dart:convert's jsonDecode instead of needing a typed
  // js_interop extension class just to read three fields off a JS object.
  function toSubscriptionJson(sub) {
    if (!sub) return null;
    const json = sub.toJSON();
    return JSON.stringify({ endpoint: json.endpoint, p256dh: json.keys.p256dh, auth: json.keys.auth });
  }

  // `navigator.serviceWorker.ready` never resolves or rejects on its own if
  // no service worker ever registers — which is exactly what happens under
  // `flutter run` (debug/dev-server mode never serves a
  // flutter_service_worker.js, so flutter_bootstrap.js deliberately skips
  // serviceWorkerSettings there; see that file's dev-mode note). Without
  // this timeout, tapping the push toggle in dev mode just hangs forever
  // with no error and no visible feedback.
  //
  // 3000ms here used to be the timeout, on the assumption that release
  // builds "register push_sw.js almost immediately" — verified live on the
  // actual Firebase-hosted deploy that this is false: Flutter's own
  // bootstrap logs "prepareServiceWorker took more than 4000ms to resolve"
  // on a real first visit, so the old 3s timeout was guaranteed to fire
  // and misreport a working release build as needing one, every time a
  // user tapped the toggle soon after page load. 15s is still fast enough
  // to fail quickly in dev mode (where there's truly no SW to wait for)
  // while giving a real first-time SW activation room to actually finish
  // instead of racing it. Only paid once per session — `ready` resolves
  // immediately on every call after the SW is first active.
  function swReady() {
    return Promise.race([
      navigator.serviceWorker.ready,
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('sw-unavailable')), 15000)),
    ]);
  }

  async function getExistingSubscription() {
    if (!isSupported()) return null;
    const reg = await swReady();
    return toSubscriptionJson(await reg.pushManager.getSubscription());
  }

  async function subscribe(vapidPublicKey) {
    if (!isSupported()) return null;
    const reg = await swReady();
    const existing = await reg.pushManager.getSubscription();
    if (existing) return toSubscriptionJson(existing);
    const sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(vapidPublicKey),
    });
    return toSubscriptionJson(sub);
  }

  async function unsubscribe() {
    if (!isSupported()) return true;
    const reg = await swReady();
    const sub = await reg.pushManager.getSubscription();
    if (!sub) return true;
    return await sub.unsubscribe();
  }

  return { isSupported, permissionState, requestPermission, getExistingSubscription, subscribe, unsubscribe };
})();
