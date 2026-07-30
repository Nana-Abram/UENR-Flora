// web/flutter_bootstrap.js
//
// Flutter's build tool auto-generates this file fresh on every `flutter
// build web` UNLESS a file already exists here in web/ — in which case it
// uses this one verbatim (only substituting the {{...}} tokens below), per
// BuildFlutterBootstrap.build() in the Flutter SDK's
// packages/flutter_tools/lib/src/build_system/targets/web.dart. This is the
// SDK's own supported customization hook, not a hand-patch of a generated
// output file (that would just get overwritten the next build) — same
// mechanism the official docs describe at
// https://docs.flutter.dev/platform-integration/web/initialization.
//
// The one change from Flutter's own default bootstrap (see
// generateDefaultFlutterBootstrapScript in bootstrap.dart): registering
// push_sw.js instead of flutter_service_worker.js directly, so Web Push's
// 'push'/'notificationclick' listeners (see push_sw.js) run in the same
// worker that controls this page. push_sw.js itself does
// `importScripts('flutter_service_worker.js')`, so Flutter's own generated
// asset-caching logic still runs completely unchanged inside it.
//
// Cache-busting note: the service-worker-version template token below
// expands to a *quoted* JS string literal (e.g. "642555256") — NOT a bare
// token — so it can't be pasted directly inside another string literal
// (it would leak literal quote characters into the URL). Assigning it to
// a variable first and
// concatenating avoids that: the resulting registration URL changes on
// every build (new version → new URL → browser treats push_sw.js as a
// changed registration → reinstalls → its importScripts call re-fetches
// the current flutter_service_worker.js), preserving the exact
// stale-main.dart.js-after-redeploy fix verified earlier for the default
// bootstrap.
//
// Dev-mode note: `flutter run` serves this same file (see
// _flutterBootstrapJsContent in web_asset_server.dart) but always
// substitutes {{flutter_service_worker_version}} as the bare `null` —
// `flutter run`'s dev server never generates a flutter_service_worker.js
// at all (there's nothing to cache; assets are served live for hot
// reload), so unconditionally registering push_sw.js here would make it
// try to `importScripts('flutter_service_worker.js')` against a 404 and
// fail to install, breaking `flutter run -d chrome` (blank page) even
// though release builds worked fine. Skipping serviceWorkerSettings
// entirely when the version is null matches Flutter's own default
// bootstrap behavior for `flutter run` (see includeServiceWorkerSettings
// in generateDefaultFlutterBootstrapScript) — no service worker, and
// therefore no Web Push, in debug/dev-server mode; it's still fully wired
// for `flutter build web --release`, which is the only mode this app is
// ever actually deployed in.
{{flutter_js}}
{{flutter_build_config}}
const _uenrSwVersion = {{flutter_service_worker_version}};
_flutter.loader.load(_uenrSwVersion == null ? {} : {
  serviceWorkerSettings: {
    serviceWorkerUrl: 'push_sw.js?v=' + _uenrSwVersion,
    serviceWorkerVersion: _uenrSwVersion
  }
});
