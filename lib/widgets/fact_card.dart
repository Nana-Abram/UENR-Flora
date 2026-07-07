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
        color: Color(0xFF2D6A4F),
        borderRadius: kBRXl,
        border: Border.all(color: kMint, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color:Colors.amber),
              SizedBox(width: 8),
              Text('Did you know?',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            text,
            style: const TextStyle(
                fontSize: 13, color: Colors.white, height: 1.6),
          ),
        ],
      ),
    );
  }
}
