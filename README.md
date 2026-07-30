# plantid_app

A new Flutter project.

## Building for web

Always build — and run locally — with:

```
flutter build web --release --no-web-resources-cdn
flutter run -d chrome --no-web-resources-cdn
```

`--no-web-resources-cdn` is required, not optional, for **both** commands —
without it, Flutter fetches the CanvasKit renderer from
`https://www.gstatic.com` at runtime instead of using the copy it already
bundles locally under `build/web/canvaskit/`. That external dependency is a
real single point of failure: on a slow, blocked, or otherwise unreliable
connection to Google's CDN, the fetch can hang or fail outright, leaving the
app on a permanently blank page — confirmed directly, both as a silent hang
with zero console errors (2026-07-27) and later as an explicit
`Failed to fetch dynamically imported module: https://www.gstatic.com/...`
thrown from `flutter run -d chrome` when that same CDN request failed
(2026-07-28). The flag forces the local `canvaskit/` copy to be used
instead, matching how `tfjs.min.js` and `passkeys_bundle.js` are already
vendored locally for the same reason. It defaults to *on* (CDN enabled) in
both `flutter build` and `flutter run`, so it's easy to forget on the
`flutter run` side specifically since only the build command tends to get
documented/scripted. See the CSP comment in `web/index.html` for how this
also lets `script-src` drop the `gstatic.com` allowlist entry entirely.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
