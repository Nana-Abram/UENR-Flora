// lib/services/web_share_service.dart
import 'dart:js_interop';

@JS('uenrShare.share')
external JSPromise<JSString> _share(JSString title, JSString text, JSString url);

@JS('uenrShare.isSupported')
external JSBoolean _isSupported();

enum ShareResult { shared, copied, cancelled, failed }

/// Shares a plant species via the browser's native share sheet (Web Share
/// API), falling back to copying the link to the clipboard when the API
/// isn't available. Web-only — see web/share.js.
class WebShareService {
  /// False only when neither navigator.share nor the Clipboard API is
  /// available (e.g. a non-secure context) — lets callers hide the share
  /// button instead of showing one that can only ever fail.
  static bool get isSupported => _isSupported().toDart;

  static Future<ShareResult> share({
    required String title,
    required String text,
    required String url,
  }) async {
    final result = (await _share(title.toJS, text.toJS, url.toJS).toDart).toDart;
    return ShareResult.values.firstWhere(
      (r) => r.name == result,
      orElse: () => ShareResult.failed,
    );
  }
}
