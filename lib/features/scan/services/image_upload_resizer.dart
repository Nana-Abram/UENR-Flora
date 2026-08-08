// lib/features/scan/services/image_upload_resizer.dart
//
// JS interop wrapper around web/image_resize.js. Deliberately split out
// from background_identifier_service.dart, which has a VM-run unit test
// suite (test/unit/background_identifier_service_test.dart) — merely
// importing dart:js_interop anywhere in that file's own dependency graph
// makes `flutter test` fail to even compile it ("Dart library
// 'dart:js_interop' is not available on this platform"), regardless of
// whether the interop call is actually invoked. So this function is
// injected into BackgroundIdentifierService's real constructor from
// main.dart (which is never loaded by that VM test suite) instead of
// being imported directly.
import 'dart:js_interop';
import 'dart:typed_data';

@JS('uenrImageResize.resizeForUpload')
external JSPromise<JSUint8Array> _resizeForUpload(JSUint8Array bytes);

/// Downscales/recompresses [bytes] before an upload to the
/// background-identify edge function. Never throws — web/image_resize.js
/// falls back to returning the original bytes unchanged on any internal
/// decode failure.
Future<Uint8List> resizeImageForUpload(Uint8List bytes) async {
  final result = await _resizeForUpload(bytes.toJS).toDart;
  return result.toDart;
}
