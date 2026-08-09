// lib/core/widgets/bullet_list.dart
import 'package:flutter/material.dart';
import '../theme.dart';

/// Renders [items] (see [toBullets]) as a bulleted list. Any item whose
/// text starts with "CAUTION" is styled in amber with a warning icon
/// instead of the default green dot — the source content uses that literal
/// prefix to flag safety-relevant bullets (toxicity, thorns, invasiveness),
/// so this is a display convention, not a guess at intent.
class BulletList extends StatelessWidget {
  final List<String> items;
  final Color? bulletColor;

  const BulletList({
    super.key,
    required this.items,
    this.bulletColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'No information available.',
        style: TextStyle(color: kMu),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final isCaution = item.toLowerCase().startsWith('caution');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Icon(
                  isCaution ? Icons.warning_amber_rounded : Icons.circle,
                  size: isCaution ? 16 : 8,
                  color: isCaution
                      ? Colors.amber.shade700
                      : (bulletColor ?? const Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isCaution ? Colors.amber.shade900 : kTx,
                    fontWeight: isCaution ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
