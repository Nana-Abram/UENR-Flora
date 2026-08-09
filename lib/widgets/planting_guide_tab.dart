// lib/widgets/planting_guide_tab.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils/text_formatter.dart';
import '../core/widgets/bullet_list.dart';

/// Splits a `planting_advice` value into its WHEN/HOW/WHERE blocks — the
/// content is always authored as three "LABEL: prose" paragraphs in that
/// order (see supabase/ornamental_planting_advice.sql), so a single regex
/// pass over the section labels is enough; nothing here assumes a specific
/// separator between blocks (blank line, single newline, etc.).
Map<String, String> parsePlantingAdvice(String advice) {
  final labels = RegExp(r'(WHEN|HOW|WHERE):\s*');
  final matches = labels.allMatches(advice).toList();
  final sections = <String, String>{};
  for (var i = 0; i < matches.length; i++) {
    final start = matches[i].end;
    final end = i + 1 < matches.length ? matches[i + 1].start : advice.length;
    sections[matches[i].group(1)!] = advice.substring(start, end).trim();
  }
  return sections;
}

/// The "Planting Guide" tab shown for ornamental species that have
/// `planting_advice` — same content and layout on both the Results screen
/// and the Explorer species detail modal.
class PlantingGuideTab extends StatelessWidget {
  final String advice;
  const PlantingGuideTab({super.key, required this.advice});

  @override
  Widget build(BuildContext context) {
    final sections = parsePlantingAdvice(advice);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlantingSection(emoji: '📅', title: 'When to Plant', text: sections['WHEN']),
        const SizedBox(height: 16),
        _PlantingSection(emoji: '🌱', title: 'How to Plant', text: sections['HOW']),
        const SizedBox(height: 16),
        _PlantingSection(emoji: '📍', title: 'Where on Campus', text: sections['WHERE']),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PlantingSection extends StatelessWidget {
  final String emoji;
  final String title;
  final String? text;
  const _PlantingSection({required this.emoji, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: kDeep, borderRadius: kBRMd),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        BulletList(items: toBullets(text ?? '')),
      ],
    );
  }
}
