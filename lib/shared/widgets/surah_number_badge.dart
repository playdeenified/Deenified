import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';

/// Soft gold sunburst badge with the surah number in the center.
/// No harsh black circle — a warm gold gradient star with a subtle
/// cream-white inner disc so the number stays legible.
class SurahNumberBadge extends StatelessWidget {
  const SurahNumberBadge({super.key, required this.number, this.size = 52});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gold sunburst — gradient gives it depth without going dark.
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.softGold, AppColors.metallicGold],
            ).createShader(rect),
            child: Icon(Icons.star_rounded, size: size, color: Colors.white),
          ),
          // Soft inner disc holds the number.
          Container(
            width: size * 0.56,
            height: size * 0.56,
            decoration: const BoxDecoration(
              color: AppColors.creamSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: GoogleFonts.outfit(
                fontSize: size * 0.27,
                fontWeight: FontWeight.w800,
                color: AppColors.darkGold,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
