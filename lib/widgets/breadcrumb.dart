// lib/widgets/breadcrumb.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/navigation.dart';
import '../core/theme.dart';

/// "📍 UENR Campus › Current page" trail shown under the navbar on every
/// redesigned screen. Tapping "UENR Campus" sends the user back to
/// whichever page they were on before this one (see [RouteHistory]).
class Breadcrumb extends StatelessWidget {
  final String current;
  const Breadcrumb({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.go(RouteHistory.previous ?? '/'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: kMu),
              const SizedBox(width: 6),
              Text('UENR Campus', style: TextStyle(fontSize: 13, color: kMu)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right, size: 15, color: kMu),
        const SizedBox(width: 6),
        Text(current,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
      ],
    );
  }
}
