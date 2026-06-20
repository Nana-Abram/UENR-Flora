import 'package:flutter/material.dart';
import '../core/theme.dart';

class EcoCard extends StatelessWidget {
  final String title;
  final String body;
  final Color? iconBg;
  final Color? iconColor;
  final IconData? icon;

  const EcoCard({
    super.key,
    required this.title,
    required this.body,
    this.iconBg,
    this.iconColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        border: Border.all(color: kBorder, width: 0.5),
        borderRadius: kBRLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: iconBg ?? kLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 14, color: iconColor ?? kDeep),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
              ],
            ),
            const SizedBox(height: 7),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
            ),
          Text(body,
              style: const TextStyle(
                  fontSize: 12, color: kMu, height: 1.55)),
        ],
      ),
    );
  }
}
