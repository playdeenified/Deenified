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
          // Gold sunburst — gradient gives it depth.
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.softGold, AppColors.metallicGold],
            ).createShader(rect),
            child: Icon(Icons.star_rounded, size: size, color: Colors.white),
          ),
          // Number sits directly on the star — no inner circle.
          Text(
            '$number',
            style: GoogleFonts.outfit(
              fontSize: size * 0.30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
              shadows: [
                Shadow(
                  color: AppColors.darkGold.withValues(alpha: 0.6),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
