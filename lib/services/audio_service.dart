import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service to handle national anthems playback.
/// Uses the audioplayers package to fetch and stream MP3s from nationalanthems.info.
class WCAudioService {
  WCAudioService._internal() {
    _init();
  }

  static final WCAudioService instance = WCAudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  // Reactive state notifiers
  final ValueNotifier<String?> currentPlayingTeamCode = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<PlayerState> playerState = ValueNotifier<PlayerState>(
    PlayerState.stopped,
  );
  final ValueNotifier<Duration> position = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<Duration> duration = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<double> volume = ValueNotifier<double>(1.0);

  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  // Set of 62 verified team codes that have working anthems on nationalanthems.info
  static const Set<String> _validCountryCodes = {
    'ar',
    'at',
    'au',
    'ba',
    'be',
    'bg',
    'br',
    'ca',
    'cd',
    'ch',
    'ci',
    'cl',
    'cm',
    'co',
    'cu',
    'cv',
    'cz',
    'de',
    'dk',
    'dz',
    'ec',
    'eg',
    'en',
    'es',
    'fr',
    'sco',
    'gh',
    'gr',
    'hr',
    'ht',
    'hu',
    'iq',
    'ir',
    'it',
    'jo',
    'jp',
    'kr',
    'ma',
    'mx',
    'ng',
    'nl',
    'no',
    'nz',
    'pa',
    'pe',
    'pl',
    'pt',
    'py',
    'qa',
    'ro',
    'rs',
    'sa',
    'se',
    'sn',
    'tn',
    'tr',
    'ua',
    'us',
    'uy',
    'uz',
    've',
    'za',
  };

  // Special URL name mappings for country codes on nationalanthems.info
  static const Map<String, String> _urlMappings = {
    'en': 'gb', // England uses the United Kingdom anthem (gb)
    'sco': 'sco', // Scotland uses Flower of Scotland (sco)
  };

  void _init() {
    _player.setReleaseMode(ReleaseMode.release);

    _positionSub = _player.onPositionChanged.listen((pos) {
      position.value = pos;
      if (isLoading.value && pos > Duration.zero) {
        isLoading.value = false;
      }
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      duration.value = dur;
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      playerState.value = state;
      if (state == PlayerState.playing ||
          state == PlayerState.paused ||
          state == PlayerState.stopped) {
        isLoading.value = false;
      }
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      _resetPlaybackState();
    });
  }

  void _resetPlaybackState() {
    currentPlayingTeamCode.value = null;
    playerState.value = PlayerState.stopped;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    isLoading.value = false;
  }

  /// Checks if a team code has a valid anthem
  bool isValidCountry(String code) {
    final cleanCode = code.toLowerCase().replaceAll('g_', '');
    return _validCountryCodes.contains(cleanCode);
  }

  /// Plays or toggles the anthem of the specified team
  Future<void> playAnthem(String teamCode) async {
    final cleanCode = teamCode.toLowerCase().replaceAll('g_', '');
    if (!_validCountryCodes.contains(cleanCode)) {
      return; // Skip placeholders like 1A, 2B, tbd
    }

    // If tapping the currently playing anthem, toggle it
    if (currentPlayingTeamCode.value == cleanCode) {
      if (playerState.value == PlayerState.playing) {
        await pause();
      } else {
        await resume();
      }
      return;
    }

    // Stop current play if any
    await stop();

    currentPlayingTeamCode.value = cleanCode;
    isLoading.value = true;
    position.value = Duration.zero;
    duration.value = Duration.zero;

    final String fileCode = _urlMappings[cleanCode] ?? cleanCode;
    final String url = 'https://nationalanthems.info/$fileCode.mp3';

    try {
      await _player.play(UrlSource(url));
    } catch (e) {
      if (kDebugMode) {
        print("Error playing anthem for $cleanCode: $e");
      }
      _resetPlaybackState();
    }
  }

  /// Pauses the current audio playback
  Future<void> pause() async {
    if (playerState.value == PlayerState.playing) {
      await _player.pause();
    }
  }

  /// Resumes the current audio playback
  Future<void> resume() async {
    if (playerState.value == PlayerState.paused) {
      await _player.resume();
    }
  }

  /// Stops audio playback completely and resets indicators
  Future<void> stop() async {
    await _player.stop();
    _resetPlaybackState();
  }

  /// Seeks to a specific duration in the anthem
  Future<void> seek(Duration dest) async {
    await _player.seek(dest);
  }

  /// Sets the volume of the playback
  Future<void> setVolume(double val) async {
    final clamped = val.clamp(0.0, 1.0);
    volume.value = clamped;
    await _player.setVolume(clamped);
  }

  /// Disposes resources used by the service
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
  }
}
