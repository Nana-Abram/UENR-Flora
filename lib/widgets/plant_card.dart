import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/plant_species.dart';
import 'pill_badge.dart';

class PlantCard extends StatelessWidget {
  final String commonName;
  final String scientificName;
  final String familyName;
  final bool healthy;
  final Color cardColor;   // background of the image placeholder area
  final IconData icon;
  final Color iconColor;
  final String? imageUrl;
  final VoidCallback? onTap;

  const PlantCard({
    super.key,
    required this.commonName,
    required this.scientificName,
    required this.familyName,
    required this.healthy,
    required this.cardColor,
    required this.icon,
    required this.iconColor,
    this.imageUrl,
    this.onTap,
  });

  /// Convenience constructor from a real Supabase species record.
  factory PlantCard.fromSpecies(PlantSpecies species, {VoidCallback? onTap}) {
    final colors = colorPairForId(species.id);
    return PlantCard(
      commonName: species.commonName,
      scientificName: species.scientificName,
      familyName: species.familyName ?? 'Unclassified',
      healthy: true,
      cardColor: Color(colors[0]),
      iconColor: Color(colors[1]),
      icon: Icons.eco_outlined,
      imageUrl: species.referenceImageUrl,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              // Reference photo, falling back to a coloured placeholder
              SizedBox(
                height: 98,
                width: double.infinity,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: cardColor,
                          child: Center(child: Icon(icon, size: 40, color: iconColor)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: cardColor,
                          child: Center(child: Icon(icon, size: 40, color: iconColor)),
                        ),
                      )
                    : Container(
                        color: cardColor,
                        child: Center(child: Icon(icon, size: 40, color: iconColor)),
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
