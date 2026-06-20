import 'package:flutter/material.dart';
import '../core/theme.dart';

class PillBadge extends StatelessWidget {
  final bool healthy;
  const PillBadge({super.key, required this.healthy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: healthy ? kHealthyBg : kUnhealthyBg,
        borderRadius: kBRPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!healthy) ...[
            Icon(Icons.warning_amber_rounded,
                size: 10, color: kUnhealthyTx),
            const SizedBox(width: 3),
          ],
          Text(
            healthy ? 'Healthy' : 'Needs care',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: healthy ? kHealthyTx : kUnhealthyTx,
            ),
          ),
        ],
      ),
    );
  }
}
