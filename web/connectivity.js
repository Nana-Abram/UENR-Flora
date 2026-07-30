// Thin wrapper around navigator.onLine + the window online/offline events.
// Defines window.uenrConnectivity, called from
// lib/services/connectivity_service.dart.
window.uenrConnectivity = {
  isOnline: () => navigator.onLine,

  // Registers callback(online: bool) to fire on every connectivity change.
  // Only one listener is ever registered in practice (ConnectivityProvider
  // is app-wide), so this doesn't bother tracking/removing old ones.
  onChange: (callback) => {
    window.addEventListener('online', () => callback(true));
    window.addEventListener('offline', () => callback(false));
  },
};
