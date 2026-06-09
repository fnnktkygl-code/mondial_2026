import 'package:mondial_2026/l10n/translations.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'team_flag.dart';
import 'team_profile_dialog.dart';

class MascotInfo {
  final String name;
  final String animal;
  final String countryCode;
  final String countryNameFr;
  final String countryNameEn;
  final String countryNameEs;
  final String roleFr;
  final String roleEn;
  final String roleEs;
  final String descFr;
  final String descEn;
  final String descEs;
  final String assetPath;
  final Color themeColor;

  MascotInfo({
    required this.name,
    required this.animal,
    required this.countryCode,
    required this.countryNameFr,
    required this.countryNameEn,
    required this.countryNameEs,
    required this.roleFr,
    required this.roleEn,
    required this.roleEs,
    required this.descFr,
    required this.descEn,
    required this.descEs,
    required this.assetPath,
    required this.themeColor,
  });
}

class WCMascotsDialog extends StatefulWidget {
  final String lang;

  const WCMascotsDialog({
    super.key,
    required this.lang,
  });

  static void show(BuildContext context, String lang) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => WCMascotsDialog(lang: lang),
    );
  }

  @override
  State<WCMascotsDialog> createState() => _WCMascotsDialogState();
}

class _WCMascotsDialogState extends State<WCMascotsDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<MascotInfo> _mascots = [
    MascotInfo(
      name: 'Maple',
      animal: 'Moose / Élan',
      countryCode: 'ca',
      countryNameFr: 'Canada',
      countryNameEn: 'Canada',
      countryNameEs: 'Canadá',
      roleFr: 'Gardien de but & artiste créatif',
      roleEn: 'Goalkeeper & Creative Artist',
      roleEs: 'Portero y artista creativo',
      descFr: 'Maple adore le style urbain, la musique et le dessin. Il incarne la créativité et la résilience canadiennes, fièrement vêtu de rouge avec le motif de la feuille d\'érable.',
      descEn: 'Maple loves street style, music, and drawing. He embodies Canadian resilience and creativity, wearing red with the maple leaf design.',
      descEs: 'A Maple le encanta el estilo urbano, la música y el dibujo. Personifica la creatividad y la resiliencia canadienses, vistiendo de rojo con el diseño de la hoja de arce.',
      assetPath: 'assets/mascots/maple.png',
      themeColor: const Color(0xFFF87171),
    ),
    MascotInfo(
      name: 'Zayu',
      animal: 'Jaguar',
      countryCode: 'mx',
      countryNameFr: 'Mexique',
      countryNameEn: 'Mexico',
      countryNameEs: 'México',
      roleFr: 'Buteur agile & ambassadeur de joie',
      roleEn: 'Agile Striker & Ambassador of Joy',
      roleEs: 'Goleador ágil y ambajador de la alegría',
      descFr: 'Inspiré par le riche patrimoine naturel du Mexique, Zayu est un jaguar agile qui transmet la force, l\'unité et l\'esprit de fête à travers le football.',
      descEn: 'Inspired by Mexico\'s rich natural heritage, Zayu is an agile jaguar who spreads strength, unity, and celebration through football.',
      descEs: 'Inspirado en el rico patrimonio natural de México, Zayu es un jaguar ágil que difunde la fuerza, la unidad y la celebración a través del fútbol.',
      assetPath: 'assets/mascots/zayu.png',
      themeColor: const Color(0xFF34D399),
    ),
    MascotInfo(
      name: 'Clutch',
      animal: 'Bald Eagle / Pygargue',
      countryCode: 'us',
      countryNameFr: 'États-Unis',
      countryNameEn: 'United States',
      countryNameEs: 'Estados Unidos',
      roleFr: 'Milieu audacieux & leader inspirant',
      roleEn: 'Bold Midfielder & Inspiring Leader',
      roleEs: 'Centrocampista audaz y líder inspirador',
      descFr: 'Clutch incarne le courage et l\'action décisive sous pression. Cet aigle royal symbolise l\'unité, le leadership et l\'énergie débordante des fans américains.',
      descEn: 'Clutch represents courage and decisive action under pressure. This bald eagle symbols unity, leadership, and the high-energy spirit of American fans.',
      descEs: 'Clutch representa el coraje y la acción decisiva bajo presión. Esta águila calva simboliza la unidad, el liderazgo y el espíritu de alta energía de los fanáticos estadounidenses.',
      assetPath: 'assets/mascots/clutch.png',
      themeColor: const Color(0xFF60A5FA),
    ),
  ];

  void _launchVideo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: WCEmbeddedWebView(
          url: 'https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/mascots',
          title: AppTranslations.get(widget.lang, 'officialMascots'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = AppTranslations.get(widget.lang, 'officialMascots');

    final String watchVideoText = AppTranslations.get(widget.lang, 'watchOfficialTrailer');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header ──────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_people, color: AppColors.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textDim, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ─── Slider ──────────────────────────────────────────────────────────
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 440,
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _mascots.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentPage = idx;
                        });
                      },
                      itemBuilder: (context, idx) {
                        final mascot = _mascots[idx];
                        final countryName = widget.lang == 'fr' ? mascot.countryNameFr : (widget.lang == 'es' ? mascot.countryNameEs : mascot.countryNameEn);
                        final roleText = widget.lang == 'fr' ? mascot.roleFr : (widget.lang == 'es' ? mascot.roleEs : mascot.roleEn);
                        final descText = widget.lang == 'fr' ? mascot.descFr : (widget.lang == 'es' ? mascot.descEs : mascot.descEn);

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Mascot Illustration Card with colored glow shadow
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: mascot.themeColor.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: mascot.themeColor.withOpacity(0.25),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    mascot.assetPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) => Container(
                                      color: AppColors.cardDark,
                                      child: const Icon(Icons.image_not_supported, size: 40, color: AppColors.textDim),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Mascot Name & Flag Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      mascot.name,
                                      style: TextStyle(
                                        color: mascot.themeColor,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    TeamFlagWidget(
                                      code: mascot.countryCode,
                                      width: 28,
                                      height: 18,
                                      borderRadius: 4,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      countryName,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Role Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: mascot.themeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: mascot.themeColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    roleText.toUpperCase(),
                                    style: TextStyle(
                                      color: mascot.themeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Description
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    descText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _mascots.length,
                      (index) => GestureDetector(
                        onTap: () => _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? _mascots[index].themeColor
                                : AppColors.borderStrong,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ─── Watch Trailer Button ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _launchVideo(context),
                icon: const Icon(Icons.play_circle_fill, size: 20),
                label: Text(
                  watchVideoText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
