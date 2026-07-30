// lib/features/scan/offline_scan_queue.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/dashboard_provider.dart';
import '../../core/device_id.dart';
import '../../services/connectivity_service.dart';
import '../../services/identification_logger.dart';
import '../profile/providers/profile_provider.dart';
import 'pending_scan.dart';

/// Scans whose identification_logs insert / profile-record RPC failed
/// (almost always because the device was offline — see the try/catch
/// around this pair of calls in scan_screen.dart) are queued here instead
/// of silently discarded, and replayed automatically once connectivity
/// returns, so a scan made offline still ends up counting toward the
/// device's history and achievements rather than just vanishing.
class OfflineScanQueue extends ChangeNotifier {
  static const _key = 'uenr_flora_pending_scans';
  // A device realistically won't rack up more than a handful of offline
  // scans before reconnecting — this just bounds worst-case growth (e.g.
  // a device stuck offline for a long trip) rather than reflecting any
  // expected steady-state size.
  static const _maxQueued = 50;

  final IdentificationLogger _logger;
  final ProfileProvider _profileProvider;
  final DashboardProvider _dashboardProvider;

  List<PendingScan> _pending = [];
  List<PendingScan> get pending => List.unmodifiable(_pending);
  int get pendingCount => _pending.length;
  bool _flushing = false;

  // Safety net for when flush() fails while the device is already online
  // (e.g. a transient Supabase error, not a real connectivity drop) — the
  // only other trigger is a genuine offline→online edge, which won't fire
  // again on its own, so without this a failed flush left the "Syncing…"
  // banner (see app_shell.dart's _OfflineBanner) showing forever with
  // nothing actually retrying behind it. 45s is frequent enough to clear
  // promptly once whatever failed recovers, without hammering Supabase.
  Timer? _retryTimer;

  OfflineScanQueue(this._logger, this._profileProvider, this._dashboardProvider) {
    _load();
    ConnectivityService.listen((online) {
      if (online) unawaited(flush());
    });
    _retryTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (_pending.isNotEmpty && ConnectivityService.isOnline) {
        unawaited(flush());
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? const [];
      _pending = raw
          .map((s) => PendingScan.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt/unreadable queue — nothing safe to recover from, starts empty
      // rather than crashing app boot over a queue of best-effort analytics.
      _pending = [];
    }
    notifyListeners();
    if (_pending.isNotEmpty && ConnectivityService.isOnline) {
      unawaited(flush());
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _key, _pending.map((p) => jsonEncode(p.toJson())).toList());
    } catch (_) {
      // Best-effort — the in-memory queue still drives this session's flush.
    }
  }

  Future<void> enqueue(PendingScan scan) async {
    _pending.add(scan);
    if (_pending.length > _maxQueued) {
      _pending.removeAt(0);
    }
    notifyListeners();
    await _persist();
  }

  /// Replays queued scans oldest-first against Supabase. Stops at the first
  /// failure rather than skipping it — if the device is still offline,
  /// every remaining item would fail too, so this just waits for the next
  /// connectivity change or app launch to pick back up where it left off.
  Future<void> flush() async {
    if (_flushing || _pending.isEmpty) return;
    _flushing = true;
    try {
      // IdentificationLogger throttles inserts to 1/sec and silently no-ops
      // (not an exception) when called too soon — this pause keeps a
      // flush from landing right on the heels of some other recent log
      // call and having its first item silently dropped rather than sent.
      await Future.delayed(const Duration(milliseconds: 1200));
      while (_pending.isNotEmpty) {
        final scan = _pending.first;
        try {
          final deviceId = await DeviceId.get();
          await _logger.log(
            classification: scan.classification,
            speciesId: scan.speciesId,
            deviceId: deviceId,
          );
          await _profileProvider.recordScan(scan.speciesId, scan.isCorrect);
          _pending.removeAt(0);
          notifyListeners();
          await _persist();
          if (_pending.isNotEmpty) {
            await Future.delayed(const Duration(seconds: 1, milliseconds: 100));
          }
        } catch (_) {
          break;
        }
      }
      unawaited(_dashboardProvider.reload());
    } finally {
      _flushing = false;
    }
  }
}
