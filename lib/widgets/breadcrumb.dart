// lib/widgets/breadcrumb.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// "📍 UENR Campus › Current page" trail shown under the navbar on every
/// redesigned screen.
class Breadcrumb extends StatelessWidget {
  final String current;
  const Breadcrumb({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on_outlined, size: 14, color: kMu),
        const SizedBox(width: 6),
        const Text('UENR Campus', style: TextStyle(fontSize: 13, color: kMu)),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, size: 15, color: kMu),
        const SizedBox(width: 6),
        Text(current,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
      ],
    );
  }
}
