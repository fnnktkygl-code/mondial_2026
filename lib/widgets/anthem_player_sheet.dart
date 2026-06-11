import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../services/audio_service.dart';
import '../services/insights_service.dart';
import 'team_flag.dart';

class AnthemPlayerSheet extends StatefulWidget {
  final List<WorldCupMatch> matches;
  final String lang;

  const AnthemPlayerSheet({
    super.key,
    required this.matches,
    required this.lang,
  });

  @override
  State<AnthemPlayerSheet> createState() => _AnthemPlayerSheetState();
}

class _AnthemPlayerSheetState extends State<AnthemPlayerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final WCAudioService _audioService = WCAudioService.instance;
  String _searchQuery = '';
  List<String> _allTeams = [];

  @override
  void initState() {
    super.initState();
    _initTeamsList();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  void _initTeamsList() {
    final Set<String> teamCodes = {};
    for (final m in widget.matches) {
      if (_audioService.isValidCountry(m.t1)) {
        teamCodes.add(m.t1.toLowerCase());
      }
      if (_audioService.isValidCountry(m.t2)) {
        teamCodes.add(m.t2.toLowerCase());
      }
    }
    // Sort alphabetically by translated name
    _allTeams = teamCodes.toList()
      ..sort(
            (a, b) => AppTranslations.getTeam(
          widget.lang,
          a,
        ).compareTo(AppTranslations.getTeam(widget.lang, b)),
      );
  }

  String _getFlagCdnUrl(String code) {
    String c = code.toLowerCase().replaceAll('g_', '');
    if (c == 'en') c = 'gb-eng';
    if (c == 'sco') c = 'gb-sct';
    if (c == 'wa') c = 'gb-wls';
    return 'https://flagcdn.com/w80/$c.png';
  }

  void _playPrev() {
    final code = _audioService.currentPlayingTeamCode.value;
    if (code == null) return;
    final teams = _getFilteredTeams();
    final idx = teams.indexOf(code);
    if (idx > 0) _audioService.playAnthem(teams[idx - 1]);
  }

  void _playNext() {
    final code = _audioService.currentPlayingTeamCode.value;
    if (code == null) return;
    final teams = _getFilteredTeams();
    final idx = teams.indexOf(code);
    if (idx >= 0 && idx < teams.length - 1) _audioService.playAnthem(teams[idx + 1]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getFilteredTeams() {
    if (_searchQuery.isEmpty) {
      return _allTeams;
    }
    return _allTeams.where((code) {
      final name = AppTranslations.getTeam(widget.lang, code).toLowerCase();
      return name.contains(_searchQuery) || code.contains(_searchQuery);
    }).toList();
  }

  Widget _buildFlag(String code, double size) {
    return Container(
      width: size * 1.4,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          _getFlagCdnUrl(code),
          width: size * 1.4,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => TeamFlagWidget(
            code: code,
            width: size * 1.4,
            height: size,
            borderRadius: 6,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeams = _getFilteredTeams();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Header Drag Handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderMid,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Header Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.get(widget.lang, 'anthemsTitle'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDim),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: AppTranslations.get(widget.lang, 'searchTeams'),
                    hintStyle: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textDim,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textDim,
                      ),
                      onPressed: () => _searchController.clear(),
                    )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Team Grid list
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 12,
                    bottom: 200,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.1,
                  ),
                  itemCount: filteredTeams.length,
                  itemBuilder: (context, index) {
                    final code = filteredTeams[index];
                    final name = AppTranslations.getTeam(widget.lang, code);

                    return ValueListenableBuilder<String?>(
                      valueListenable: _audioService.currentPlayingTeamCode,
                      builder: (context, currentCode, _) {
                        final isPlayingThis = currentCode == code;

                        return ValueListenableBuilder<PlayerState>(
                          valueListenable: _audioService.playerState,
                          builder: (context, state, _) {
                            final isCurrentlyPlaying =
                                isPlayingThis && state == PlayerState.playing;

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPlayingThis
                                      ? AppColors.accent
                                      : AppColors.border,
                                  width: isPlayingThis ? 2.0 : 1.5,
                                ),
                              ),
                              child: GestureDetector(
                                // Utilisation de GestureDetector pour une meilleure portée
                                behavior: HitTestBehavior
                                    .opaque, // IMPORTANT : intercepte tout le rectangle
                                onTap: () => _audioService.playAnthem(code),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Row(
                                    children: [
                                      _buildFlag(code, 32),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                height: 1.1,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                            ),
                                            const SizedBox(height: 4),
                                            if (isCurrentlyPlaying)
                                              const SoundwaveVisualizer()
                                            else
                                              Text(
                                                code.toUpperCase(),
                                                style: const TextStyle(
                                                  color: AppColors.textDim,
                                                  fontSize: 10,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Small play/pause action button
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                        _audioService.isLoading,
                                        builder: (context, loading, _) {
                                          if (isPlayingThis && loading) {
                                            return const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                AlwaysStoppedAnimation<
                                                    Color
                                                >(AppColors.accent),
                                              ),
                                            );
                                          }

                                          return Icon(
                                            isCurrentlyPlaying
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_filled,
                                            color: isPlayingThis
                                                ? AppColors.accent
                                                : AppColors.textDim,
                                            size: 26,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating sticky bottom player
          _buildBottomPlayer(),
        ],
      ),
    );
  }

  Widget _buildBottomPlayer() {
    return ValueListenableBuilder<String?>(
      valueListenable: _audioService.currentPlayingTeamCode,
      builder: (context, playingCode, _) {
        if (playingCode == null) {
          return const SizedBox.shrink();
        }

        final String name = AppTranslations.getTeam(widget.lang, playingCode);
        final history = WCInsightsService.getHistory(playingCode);
        final String? funFact = WCInsightsService.getRandomFunFact(playingCode);

        final teams = _getFilteredTeams();
        final idx = teams.indexOf(playingCode);
        final hasPrev = idx > 0;
        final hasNext = idx >= 0 && idx < teams.length - 1;

        // Build a clean subtitle: first WC year if known, otherwise participation count
        final String subtitle = history?.firstWorldCup != null
            ? 'Depuis ${history!.firstWorldCup}'
            : AppTranslations.get(widget.lang, 'anthemsTitle');

        return Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accent, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info & Controls row
                Row(
                  children: [
                    _buildFlag(playingCode, 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Prev button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        color: hasPrev ? AppColors.textMuted : AppColors.border,
                        size: 26,
                      ),
                      onPressed: hasPrev ? _playPrev : null,
                    ),
                    // Loading spinner / Play-Pause Button
                    ValueListenableBuilder<bool>(
                      valueListenable: _audioService.isLoading,
                      builder: (context, loading, _) {
                        if (loading) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.accent,
                                ),
                              ),
                            ),
                          );
                        }

                        return ValueListenableBuilder<PlayerState>(
                          valueListenable: _audioService.playerState,
                          builder: (context, state, _) {
                            final isPlaying = state == PlayerState.playing;
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                color: AppColors.accent,
                                size: 32,
                              ),
                              onPressed: () =>
                                  _audioService.playAnthem(playingCode),
                            );
                          },
                        );
                      },
                    ),
                    // Next button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: hasNext ? AppColors.textMuted : AppColors.border,
                        size: 26,
                      ),
                      onPressed: hasNext ? _playNext : null,
                    ),
                    // Stop Button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(
                        Icons.stop_circle_outlined,
                        color: AppColors.danger,
                        size: 28,
                      ),
                      onPressed: () => _audioService.stop(),
                    ),
                  ],
                ),

                // Fun fact strip — only when available
                if (funFact != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      funFact,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                const SizedBox(height: 4),

                // Progress Bar (Slider)
                ValueListenableBuilder<Duration>(
                  valueListenable: _audioService.position,
                  builder: (context, pos, _) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: _audioService.duration,
                      builder: (context, dur, _) {
                        final double maxVal = dur.inMilliseconds.toDouble();
                        final double currentVal = pos.inMilliseconds
                            .toDouble()
                            .clamp(0.0, maxVal);

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                activeTrackColor: AppColors.accent,
                                inactiveTrackColor: AppColors.border,
                                thumbColor: AppColors.accent,
                              ),
                              child: Slider(
                                value: currentVal,
                                max: maxVal > 0 ? maxVal : 1.0,
                                onChanged: (val) {
                                  _audioService.seek(
                                    Duration(milliseconds: val.toInt()),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(pos),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(dur),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                // Volume Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.volume_down,
                        color: AppColors.textDim,
                        size: 14,
                      ),
                      Expanded(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _audioService.volume,
                          builder: (context, vol, _) {
                            return SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                ),
                                activeTrackColor: AppColors.accent,
                                inactiveTrackColor: AppColors.border,
                                thumbColor: AppColors.accent,
                              ),
                              child: Slider(
                                value: vol,
                                onChanged: (val) =>
                                    _audioService.setVolume(val),
                              ),
                            );
                          },
                        ),
                      ),
                      const Icon(
                        Icons.volume_up,
                        color: AppColors.textDim,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final String minutes = d.inMinutes.toString().padLeft(2, '0');
    final String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}

/// A micro-animation widget displaying bouncing sound bars
class SoundwaveVisualizer extends StatefulWidget {
  const SoundwaveVisualizer({super.key});

  @override
  State<SoundwaveVisualizer> createState() => _SoundwaveVisualizerState();
}

class _SoundwaveVisualizerState extends State<SoundwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = [4.0, 10.0, 6.0, 12.0];
  final List<double> _targets = [4.0, 10.0, 6.0, 12.0];
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )
      ..addListener(() {
        setState(() {
          for (int i = 0; i < 4; i++) {
            // Smoothly interpolate height to target
            _heights[i] = _heights[i] + (_targets[i] - _heights[i]) * 0.25;
          }
        });
      })
      ..repeat();

    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) return;
      for (int i = 0; i < 4; i++) {
        _targets[i] =
            3.0 +
                _random.nextDouble() * 11.0; // Random heights between 3 and 14
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          return Container(
            width: 2.2,
            height: _heights[index],
            margin: const EdgeInsets.symmetric(horizontal: 1.0),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(1.0),
            ),
          );
        }),
      ),
    );
  }
}