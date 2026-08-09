import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/bullet_list.dart';

class EcoCard extends StatelessWidget {
  final String title;
  final String? body;
  /// When set, rendered as a [BulletList] instead of [body] — used for the
  /// long-form uses/description fields (medicinal uses, ecological
  /// importance, etc.) that read better as bullets than a single paragraph.
  final List<String>? bullets;
  final Color? iconBg;
  final Color? iconColor;
  final IconData? icon;

  const EcoCard({
    super.key,
    required this.title,
    this.body,
    this.bullets,
    this.iconBg,
    this.iconColor,
    this.icon,
  }) : assert(body != null || bullets != null,
            'EcoCard needs either body or bullets');

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
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
              ],
            ),
            const SizedBox(height: 7),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
            ),
          if (bullets != null)
            BulletList(items: bullets!, bulletColor: kDeep)
          else
            Text(body!,
                style: TextStyle(
                    fontSize: 12, color: kMu, height: 1.55)),
        ],
      ),
    );
  }
}
