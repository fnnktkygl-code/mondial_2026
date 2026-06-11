import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';

class LandingPage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const LandingPage({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0E1A),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          
          // Decorative Grid (simulated)
          Opacity(
            opacity: 0.1,
            child: GridPaper(
              color: AppColors.accent.withValues(alpha: 0.2),
              divisions: 1,
              subdivisions: 1,
              interval: 100,
              child: Container(),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon / Logo
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/app_icon.png',
                            height: 120,
                            width: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Title with Gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF006847), // Mexico Green
                          Color(0xFF002868), // USA Blue
                          Color(0xFFFF0000), // Canada Red
                        ],
                      ).createShader(bounds),
                      child: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "PRONOS\nCHALLENGE",
                            textAlign: TextAlign.center,
                            softWrap: false,
                            style: GoogleFonts.syne(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                              letterSpacing: -1.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      "Vivez la Coupe du Monde 2026 comme jamais.\nPrédictions en direct, groupes privés et classement mondial.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 64),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onGetStarted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                          elevation: 20,
                          shadowColor: AppColors.accent.withValues(alpha: 0.4),
                        ),
                        child: const Text(
                          "JOUER MAINTENANT",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Version / Footer
                    Text(
                      "Coupe du Monde 2026 · USA / Canada / Mexique",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
