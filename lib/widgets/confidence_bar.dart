import 'package:flutter/material.dart';
import '../core/theme.dart';

class ConfidenceBar extends StatelessWidget {
  final double confidence; // 0.0 – 1.0

  const ConfidenceBar({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AI confidence',
                style: TextStyle(fontSize: 12, color: kMu)),
            Text('$pct%',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: kDeep)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(height: 6, color: kLight),
              FractionallySizedBox(
                widthFactor: confidence.clamp(0.0, 1.0),
                child: Container(height: 6, color: kDeep),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
