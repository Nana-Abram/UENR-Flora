// web/push_sw.js
//
// The service worker that actually receives Web Push messages and reacts
// to the resulting notification being clicked — registered directly by
// push.js (navigator.serviceWorker.register('push_sw.js')), independent of
// Flutter's own bootstrap/service-worker loading.
//
// This file used to also `importScripts('flutter_service_worker.js')` so
// Flutter's generated asset-caching install/activate/fetch listeners would
// run inside the same worker. That broke silently: as of this project's
// Flutter SDK version, flutter_service_worker.js is no longer a real
// caching worker — Flutter deprecated that mechanism (see console warning
// "Loading the service worker using Flutter bootstrap is deprecated...",
// https://github.com/flutter/flutter/issues/156910) and now generates a
// stub whose only job is to unregister *itself* on activate, to clean up a
// real caching worker a browser might still have installed from an older
// version of this app. importScripts-ing that stub meant push_sw.js
// inherited that unregister-on-activate behavior too — verified live that
// every registration was destroying itself within moments of activating,
// which is why zero push subscriptions had ever been saved successfully.
// Dropping the importScripts entirely fixes it: this worker now just
// installs, activates, and stays active, with no dependency on whatever
// Flutter's own (possibly-removed-in-the-future) SW bootstrap does.
//
// skipWaiting()/clients.claim(): take over immediately on install/activate
// instead of waiting for every open tab to close first (the normal SW
// update behavior) — there's no cached state here worth being careful
// about, and any device that still has the old (self-destructing) version
// registered from before this fix should replace it as soon as possible
// rather than staying broken until the user happens to close every tab.
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', (event) => {
  let data = { title: 'UENR Flora', body: 'You have a new notification.', url: '/' };
  try {
    if (event.data) data = Object.assign(data, event.data.json());
  } catch (e) {
    // Malformed/non-JSON payload — fall back to the generic message above
    // rather than dropping the notification entirely.
  }
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
      data: { url: data.url || '/' },
    })
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        // Focus and in-page-navigate an already-open tab rather than opening
        // a duplicate one, same as most native push UX.
        if ('focus' in client) {
          client.focus();
          if ('navigate' in client) client.navigate(url);
          return;
        }
      }
      if (clients.openWindow) return clients.openWindow(url);
    })
  );
});
