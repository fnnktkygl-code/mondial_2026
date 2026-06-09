import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/match.dart';
import '../services/team_profile_service.dart';
import '../services/audio_service.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import 'team_flag.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WCTeamProfileDialog extends StatefulWidget {
  final String teamCode;
  final String lang;

  const WCTeamProfileDialog({
    super.key,
    required this.teamCode,
    required this.lang,
  });

  static void show(BuildContext context, String teamCode, String lang) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => WCTeamProfileDialog(
        teamCode: teamCode,
        lang: lang,
      ),
    );
  }

  @override
  State<WCTeamProfileDialog> createState() => _WCTeamProfileDialogState();
}

class _WCTeamProfileDialogState extends State<WCTeamProfileDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Correctly resolve variables using widget configuration scope properties
    final cleanCode = widget.teamCode.toLowerCase().replaceAll('g_', '');
    final bool isRealCountry = WCAudioService.instance.isValidCountry(cleanCode);

    final profile = WCTeamProfileService.getProfile(cleanCode, widget.lang);
    final teamName = AppTranslations.getTeam(widget.lang, cleanCode);

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
            // ─── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  // Dans lib/widgets/team_profile_dialog.dart
                  Hero(
                    tag: 'profile_flag_$cleanCode',
                    child: TeamFlagWidget(
                      // Normalisation locale : si c'est gb-sct, force sco, sinon garde le code
                      code: cleanCode == 'gb-sct' ? 'sco' : cleanCode,
                      width: 56,
                      height: 38,
                      borderRadius: 6,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          profile.nickname,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textDim, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ─── Body ─────────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. General Info
                    _buildSectionTitle(
                      AppTranslations.get(widget.lang, 'generalInformation'),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      icon: Icons.shield_outlined,
                      label: AppTranslations.get(widget.lang, 'emblem'),
                      value: profile.symbol,
                    ),
                    _buildInfoRow(
                      icon: Icons.format_list_numbered,
                      label: AppTranslations.get(widget.lang, 'fifaRanking'),
                      value: profile.fifaRanking == 999
                          ? (AppTranslations.get(widget.lang, 'unranked'))
                          : '#${profile.fifaRanking}',
                    ),
                    _buildInfoRow(
                      icon: Icons.sports_soccer_outlined,
                      label: AppTranslations.get(widget.lang, 'appearances'),
                      value: '${profile.appearances} ${AppTranslations.get(widget.lang, 'finalPhases')}',
                    ),
                    _buildInfoRow(
                      icon: Icons.emoji_events_outlined,
                      label: AppTranslations.get(widget.lang, 'bestFinish'),
                      value: profile.bestFinish,
                    ),

                    // 2. Trophies
                    if (profile.trophies.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        AppTranslations.get(widget.lang, 'majorTrophies'),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.trophies.map((trophy) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTrophyBadge(trophy),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    trophy,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // 3. Media & History — single card only
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      AppTranslations.get(widget.lang, 'mediaHistory'),
                    ),
                    const SizedBox(height: 12),
                    _buildMediaCard(
                      imageUrl: profile.imageUrl,
                      title: AppTranslations.get(widget.lang, 'teamHistoryProfile'),
                      description: AppTranslations.get(widget.lang, 'teamHistoryDesc'),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.85,
                            child: WCEmbeddedWebView(
                              url: profile.profileUrl,
                              title: AppTranslations.get(widget.lang, 'teamHistoryInfo'),
                            ),
                          ),
                        );
                      },
                    ),

                    // 4. National Anthem
                    if (isRealCountry) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        AppTranslations.get(widget.lang, 'nationalAnthem'),
                      ),
                      const SizedBox(height: 12),
                      _buildAnthemPlayerSection(cleanCode),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section title ───────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textDim,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  // ─── Info row ────────────────────────────────────────────────────────────────

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.4),
                children: [
                  TextSpan(
                    text: '$label : ',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Media card ──────────────────────────────────────────────────────────────

  Widget _buildMediaCard({
    required String? imageUrl,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final bool isLocalAsset = hasImage && imageUrl.startsWith('assets/');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          highlightColor: AppColors.border.withOpacity(0.3),
          splashColor: AppColors.accent.withOpacity(0.15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppColors.cardDark,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (hasImage) ...[
                      isLocalAsset
                          ? Image.asset(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => SizedBox(
                                height: 160,
                                child: _buildImagePlaceholder(),
                              ),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => SizedBox(
                                height: 160,
                                child: _buildImagePlaceholder(),
                              ),
                            ),
                    ] else
                      SizedBox(
                        height: 160,
                        child: _buildImagePlaceholder(),
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1),
                      ),
                      child: const Icon(Icons.article_outlined, color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_ios, color: AppColors.textDim, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.cardDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, color: AppColors.textDim, size: 40),
            const SizedBox(height: 8),
            Text(
              AppTranslations.get(widget.lang, 'previewNotAvailable'),
              style: const TextStyle(color: AppColors.textDim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Trophy badge ────────────────────────────────────────────────────────────

  Widget _buildTrophyBadge(String trophy) {
    final lower = trophy.toLowerCase();
    String? assetPath;
    IconData fallbackIcon = Icons.workspace_premium;
    Color fallbackColor = Colors.amber;

    if (lower.contains('coupe du monde') || lower.contains('world cup') || lower.contains('copa mundial')) {
      assetPath = 'assets/logos/fifa_logo_light.png';
    } else if (lower.contains('copa américa') || lower.contains('copa america')) {
      assetPath = 'assets/badges/conmebol.png';
    } else if (lower.contains('europe') || lower.contains('euro') || lower.contains('nations league') ||
        lower.contains('ligue des nations de l\'uefa') || lower.contains('liga de naciones de la uefa')) {
      assetPath = lower.contains('concacaf') ? 'assets/badges/concacaf.png' : 'assets/badges/uefa.png';
    } else if (lower.contains('afrique des nations') || lower.contains('africa cup') ||
        lower.contains('copa africana') || lower.contains('chan')) {
      assetPath = 'assets/badges/caf.png';
    } else if (lower.contains('asie') || lower.contains('asian cup') || lower.contains('copa asiática')) {
      assetPath = 'assets/badges/afc.png';
    } else if (lower.contains('confédérations') || lower.contains('confederations')) {
      assetPath = 'assets/badges/coupe_des_confederations.png';
    } else if (lower.contains('or de la concacaf') || lower.contains('gold cup') ||
        lower.contains('copa de oro') || lower.contains('nations league concacaf') ||
        lower.contains('ligue des nations concacaf')) {
      assetPath = 'assets/badges/concacaf.png';
    } else if (lower.contains('ofc') || lower.contains('océanie') || lower.contains('oceania')) {
      assetPath = 'assets/badges/ofc.png';
    } else if (lower.contains('arabe') || lower.contains('arab cup') || lower.contains('árabe')) {
      assetPath = 'assets/logos/fifa_logo_light.png';
    } else if (lower.contains('olympique') || lower.contains('olympic') || lower.contains('olímpica')) {
      fallbackIcon = Icons.stars;
      fallbackColor = Colors.blue;
    }

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: fallbackColor, size: 14),
      );
    }
    return Icon(fallbackIcon, color: fallbackColor, size: 14);
  }

  // ─── Anthem player ───────────────────────────────────────────────────────────

  Widget _buildAnthemPlayerSection(String code) {
    final audio = WCAudioService.instance;

    return ValueListenableBuilder<String?>(
      valueListenable: audio.currentPlayingTeamCode,
      builder: (context, playingCode, _) {
        final bool isCurrent = playingCode == code;

        return ValueListenableBuilder<PlayerState>(
          valueListenable: audio.playerState,
          builder: (context, state, _) {
            final bool isPlaying = isCurrent && state == PlayerState.playing;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isCurrent ? AppColors.accent : AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: audio.isLoading,
                        builder: (context, loading, _) {
                          if (isCurrent && loading) {
                            return const SizedBox(
                              width: 44,
                              height: 44,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          }
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                              backgroundColor: isPlaying ? Colors.amber : AppColors.accent,
                              foregroundColor: AppColors.surface,
                            ),
                            onPressed: () => audio.playAnthem(code),
                            child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 20),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.get(widget.lang, 'nationalAnthemStream'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isCurrent
                                  ? (isPlaying
                                      ? (AppTranslations.get(widget.lang, 'nowPlaying'))
                                      : (AppTranslations.get(widget.lang, 'paused')))
                                  : (AppTranslations.get(widget.lang, 'readyToListen')),
                              style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      SoundwaveVisualizer(isPlaying: isPlaying),
                    ],
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 12),
                    ValueListenableBuilder<Duration>(
                      valueListenable: audio.duration,
                      builder: (context, dur, _) {
                        return ValueListenableBuilder<Duration>(
                          valueListenable: audio.position,
                          builder: (context, pos, _) {
                            final double maxVal = dur.inMilliseconds.toDouble();
                            final double currVal = pos.inMilliseconds.toDouble().clamp(0.0, maxVal);
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: AppColors.accent,
                                    inactiveTrackColor: AppColors.border,
                                    thumbColor: AppColors.accent,
                                  ),
                                  child: Slider(
                                    min: 0.0,
                                    max: maxVal > 0.0 ? maxVal : 1.0,
                                    value: currVal,
                                    onChanged: (val) => audio.seek(Duration(milliseconds: val.toInt())),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(pos), style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                                      Text(_formatDuration(dur), style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.volume_down, color: AppColors.textMuted, size: 14),
                      Expanded(
                        child: ValueListenableBuilder<double>(
                          valueListenable: audio.volume,
                          builder: (context, vol, _) {
                            return SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                activeTrackColor: AppColors.textDim,
                                inactiveTrackColor: AppColors.border,
                                thumbColor: AppColors.textDim,
                              ),
                              child: Slider(
                                min: 0.0,
                                max: 1.0,
                                value: vol,
                                onChanged: (val) => audio.setVolume(val),
                              ),
                            );
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, color: AppColors.textMuted, size: 14),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final int min = d.inMinutes;
    final int sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

// ─── Soundwave visualizer ────────────────────────────────────────────────────

class SoundwaveVisualizer extends StatefulWidget {
  final bool isPlaying;
  const SoundwaveVisualizer({super.key, required this.isPlaying});

  @override
  State<SoundwaveVisualizer> createState() => _SoundwaveVisualizerState();
}

class _SoundwaveVisualizerState extends State<SoundwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = [10, 20, 14, 24, 8, 18, 12, 22];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SoundwaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _heights.length,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 2.5,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _heights.length,
            (i) {
              final scale = 0.25 + 0.75 * sin((_controller.value * 2 * pi) + (i * 0.4)).abs();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 2.5,
                height: (_heights[i] * scale).clamp(4.0, 24.0),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Embedded WebView ────────────────────────────────────────────────────────

class WCEmbeddedWebView extends StatefulWidget {
  final String url;
  final String title;

  const WCEmbeddedWebView({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WCEmbeddedWebView> createState() => _WCEmbeddedWebViewState();
}

class _WCEmbeddedWebViewState extends State<WCEmbeddedWebView> {
  InAppWebViewController? _webViewController;
  double _progress = 0.0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
                  onPressed: _canGoBack ? () async => _webViewController?.goBack() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                  onPressed: _canGoForward ? () async => _webViewController?.goForward() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                  onPressed: () async => _webViewController?.reload(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 3,
            )
          else
            const SizedBox(height: 3),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialSettings: InAppWebViewSettings(
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  iframeAllowFullscreen: true,
                  verticalScrollBarEnabled: true,
                  horizontalScrollBarEnabled: true,
                  supportZoom: true,
                  builtInZoomControls: true,
                  displayZoomControls: false,
                ),
                gestureRecognizers: {
                  Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                  Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
                  Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                  Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url;
                  if (uri == null) return NavigationActionPolicy.CANCEL;

                  // 1. Only allow http/https
                  if (uri.scheme != 'http' && uri.scheme != 'https') {
                    return NavigationActionPolicy.CANCEL;
                  }

                  // 2. Whitelist intended domains
                  final host = uri.host.toLowerCase();
                  if (host == 'fifa.com' || host.endsWith('.fifa.com')) {
                    return NavigationActionPolicy.ALLOW;
                  }

                  // 3. Deny everything else
                  return NavigationActionPolicy.CANCEL;
                },
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStart: (controller, url) async {
                  final back = await controller.canGoBack();
                  final forward = await controller.canGoForward();
                  if (mounted) setState(() { _canGoBack = back; _canGoForward = forward; });
                },
                onLoadStop: (controller, url) async {
                  final back = await controller.canGoBack();
                  final forward = await controller.canGoForward();
                  if (mounted) setState(() { _progress = 1.0; _canGoBack = back; _canGoForward = forward; });
                },
                onProgressChanged: (controller, progress) {
                  if (mounted) setState(() => _progress = progress / 100.0);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}