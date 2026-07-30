// lib/core/connectivity_provider.dart
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

/// App-wide online/offline flag, backed by the browser's navigator.onLine
/// signal — lets AppShell show a persistent offline banner instead of every
/// screen discovering the outage independently via a failed Supabase call.
class ConnectivityProvider extends ChangeNotifier {
  bool isOnline;

  ConnectivityProvider() : isOnline = ConnectivityService.isOnline {
    ConnectivityService.listen((online) {
      if (online == isOnline) return;
      isOnline = online;
      notifyListeners();
    });
  }
}
