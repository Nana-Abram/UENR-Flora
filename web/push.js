// web/push.js
//
// Web Push subscribe/unsubscribe bridge. Defines window.uenrPush, called
// from lib/services/web_push_service.dart. The actual push message
// handling (the 'push'/'notificationclick' listeners) lives in push_sw.js,
// the service worker — this file manages the subscription lifecycle from
// the page context AND registers push_sw.js itself (see ensureRegistered
// below) — deliberately not relying on Flutter's own bootstrap/service-
// worker loading for this, since that's a moving target Flutter has
// marked deprecated (https://github.com/flutter/flutter/issues/156910)
// and previously broke this feature outright — see push_sw.js's own
// top-of-file comment for the full story.
window.uenrPush = (function () {
  function isSupported() {
    return !!(window.isSecureContext && 'serviceWorker' in navigator && 'PushManager' in window);
  }

  // Registered once per page load, independent of whatever service worker
  // (if any) Flutter's own bootstrap sets up. Safe to call unconditionally
  // and repeatedly — the browser treats re-registering the same URL as a
  // no-op update check, not a fresh install.
  let registerPromise = null;
  function ensureRegistered() {
    if (!isSupported()) return Promise.resolve(null);
    if (!registerPromise) {
      registerPromise = navigator.serviceWorker.register('push_sw.js');
    }
    return registerPromise;
  }
  // Fire immediately on script load (this script itself is `defer`red, so
  // this still runs well before a user could reach the notifications
  // screen) rather than waiting for the first subscribe/getExistingSubscription
  // call, so swReady() below usually has nothing left to wait for.
  ensureRegistered();

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
  // registration never succeeds — the timeout here is what turns that into
  // a real (if generic) error instead of the push toggle hanging forever
  // with no feedback. 15s gives a real first-time registration/activation
  // room to finish (verified live: push_sw.js registering and reaching
  // 'activated' is not instant) while still failing in bounded time if
  // something is genuinely broken. `ready` resolves immediately on every
  // call after the SW is first active, so this cost is paid at most once
  // per session. ensureRegistered() is called first since `ready` alone
  // never triggers a registration — only reflects one that's already in
  // progress or done.
  function swReady() {
    return Promise.race([
      ensureRegistered().then(() => navigator.serviceWorker.ready),
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
