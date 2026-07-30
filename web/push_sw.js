// web/push_sw.js
//
// Wraps Flutter's own generated service worker (flutter_service_worker.js)
// via importScripts so its asset-caching install/activate/fetch listeners
// still run exactly as Flutter generates them on every build — this file
// only adds the two listeners Flutter's generated file has no hook for:
// receiving a Web Push message and reacting to the resulting notification
// being clicked. See web/push.js for the subscribe-side half of this
// feature, and index.html for why this file (not flutter_service_worker.js
// directly) is what actually gets registered as the controlling worker.
importScripts('flutter_service_worker.js');

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
