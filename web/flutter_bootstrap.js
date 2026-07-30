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
// generateDefaultFlutterBootstrapScript in bootstrap.dart): calling
// `_flutter.loader.load()` with NO serviceWorkerSettings, so Flutter never
// registers its own service worker at all.
//
// Why: this project used to have push_sw.js registered here instead of
// Flutter's default flutter_service_worker.js, specifically so Web Push's
// 'push'/'notificationclick' listeners ran in the same worker that
// controls the page. That broke on this Flutter SDK version — Flutter
// deprecated flutter_service_worker.js as a real caching worker (see
// https://github.com/flutter/flutter/issues/156910) and now generates a
// stub whose only job is unregistering itself, so push_sw.js
// importScripts-ing it inherited that self-destruct behavior. push_sw.js
// now drops the importScripts and registers itself directly from push.js
// instead (see that file's comment) — decoupled from this bootstrap
// entirely. But Flutter's *default* bootstrap still unconditionally
// registers flutter_service_worker.js at the same scope ('/') push_sw.js
// needs, and verified live that the two fight over that scope — whichever
// registers second evicts the first as that scope's controller, so
// `navigator.serviceWorker.ready` could resolve to either one depending on
// timing. Since Flutter's own service worker no longer does anything
// useful (a self-unregistering stub, not a cache), the fix is to stop
// asking Flutter to register one at all, leaving push_sw.js as the only
// service worker at this scope.
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load();
