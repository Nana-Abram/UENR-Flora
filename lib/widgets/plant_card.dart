import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import 'pill_badge.dart';

class PlantCard extends StatelessWidget {
  final String commonName;
  final String scientificName;
  final String familyName;
  final bool healthy;
  final Color cardColor;   // background of the image placeholder area
  final IconData icon;
  final Color iconColor;

  const PlantCard({
    super.key,
    required this.commonName,
    required this.scientificName,
    required this.familyName,
    required this.healthy,
    required this.cardColor,
    required this.icon,
    required this.iconColor,
  });

  /// Convenience constructor from the kSamplePlants map entries.
  factory PlantCard.fromMap(Map<String, dynamic> m) {
    return PlantCard(
      commonName:     m['common'] as String,
      scientificName: m['scientific'] as String,
      familyName:     m['family'] as String,
      healthy:        m['healthy'] as bool,
      cardColor:      Color(m['cardColor'] as int),
      iconColor:      Color(m['iconColor'] as int),
      icon:           Icons.eco_outlined, // default; override per-species later
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/results'),
      child: ClipRRect(
        borderRadius: kBRXl,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: kBorder, width: 0.5),
            borderRadius: kBRXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coloured image placeholder
              Container(
                height: 98,
                color: cardColor,
                child: Center(
                  child: Icon(icon, size: 40, color: iconColor),
                ),
              ),
              // Text body
              Container(
                color: kWhite,
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(commonName,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500, color: kTx),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(scientificName,
                        style: const TextStyle(
                            fontSize: 10,
                            color: kMu,
                            fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PillBadge(healthy: healthy),
                        Text(familyName,
                            style: const TextStyle(fontSize: 9, color: kMu)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
