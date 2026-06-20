import 'package:flutter/material.dart';
import '../core/theme.dart';

class FactCard extends StatelessWidget {
  final String text;
  const FactCard(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: kBRXl,
        border: Border.all(color: kMint, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, size: 16, color: kDeep),
              SizedBox(width: 8),
              Text('Did you know?',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: kDeep)),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            text,
            style: const TextStyle(
                fontSize: 13, color: kDeep, height: 1.6),
          ),
        ],
      ),
    );
  }
}
