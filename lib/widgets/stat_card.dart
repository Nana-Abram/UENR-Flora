// lib/widgets/stat_card.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';

class StatCardData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String topLabel;
  final String value;
  final String bottomLabel;
  const StatCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.topLabel,
    required this.value,
    required this.bottomLabel,
  });
}

/// Small "icon + label, big value, sub-label" tile used by Home's dashboard
/// stats row and Profile's overview stats row — those used to each define
/// their own copy of this. Home and Profile still want visibly different
/// icon sizes/value typography/shadow, so those are parameters here
/// (defaulted to Home's look) rather than forcing one look on both.
class StatCard extends StatelessWidget {
  final StatCardData data;
  final double iconCircleSize;
  final double iconSize;
  final TextStyle? valueStyle;
  final BorderRadius? cardRadius;
  final List<BoxShadow>? shadow;

  const StatCard({
    super.key,
    required this.data,
    this.iconCircleSize = 32,
    this.iconSize = 16,
    this.valueStyle,
    this.cardRadius,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    // Can't be a constructor default value (kTx isn't a compile-time
    // constant — see theme.dart) — resolved here instead, at build time.
    final resolvedValueStyle =
        valueStyle ?? TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: kTx);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: cardRadius ?? kBR2xl,
        border: Border.all(color: kBorder, width: 0.5),
        boxShadow: shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(data.topLabel,
                    style: TextStyle(fontSize: 12, color: kMu),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                width: iconCircleSize, height: iconCircleSize,
                decoration: BoxDecoration(color: data.iconBg, shape: BoxShape.circle),
                child: Icon(data.icon, size: iconSize, color: data.iconColor),
              ),
            ],
          ),
          const Spacer(),
          Text(data.value, style: resolvedValueStyle),
          const SizedBox(height: 2),
          Text(data.bottomLabel, style: TextStyle(fontSize: 11, color: kMu)),
        ],
      ),
    );
  }
}
