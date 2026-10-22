import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated Splash Screen for QRLink using the `another_flutter_splash_screen` package.
class QrLinkSplashScreen extends StatelessWidget {
  const QrLinkSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.fadeIn(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF070B14),
          Color(0xFF0F1A34),
          Color(0xFF0A0E1A),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      animationDuration: const Duration(milliseconds: 1200),
      duration: const Duration(milliseconds: 2400),
      childWidget: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Squircle App Icon
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00008B).withValues(alpha: 0.55),
                    blurRadius: 36,
                    spreadRadius: 4,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Brand Title
            Text(
              'QRLink',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Brand Tagline
            Text(
              'Scan  •  Create  •  Connect',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 36),

            // Modern Brand Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'QR Code Studio',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFCBD5E1),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onEnd: () {
        if (context.mounted) {
          context.go('/');
        }
      },
    );
  }
}
