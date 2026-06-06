import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuzLogo extends StatelessWidget {
  final double size;
  final double borderRadius;

  const BuzLogo({
    super.key,
    this.size = 64,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const RadialGradient(
          colors: [
            Color(0xFF5E0B9E), // Lighter purple center highlight
            Color(0xFF32035C), // Rich velvet purple mid
            Color(0xFF190130), // Deep velvet purple edges
          ],
          center: Alignment(0.0, -0.2),
          radius: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.08),
          ),
          BoxShadow(
            color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
            blurRadius: size * 0.2,
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF9D4EDD).withValues(alpha: 0.3),
          width: size * 0.015,
        ),
      ),
      child: Center(
        child: Text(
          'B',
          style: GoogleFonts.outfit(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(1, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
