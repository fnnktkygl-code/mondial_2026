/// Central constants file for the Mondial 2026 app.
/// Magic numbers, configuration values, and named constants live here.
library app_constants;

// ─── Scoring ─────────────────────────────────────────────────────────────────
const int kExactScorePoints     = 30;   // Points for predicting the exact scoreline
const int kCorrectOutcomePoints = 10;   // Points for predicting the correct match result
const int kChampionBonusPoints  = 100;  // Bonus for correctly predicting the tournament winner

// ─── XP / Level thresholds ───────────────────────────────────────────────────
/// Each entry is [minXp, maxXp (exclusive), level, rankNameKey, nextLevelXp].
/// Rank name keys must match keys in AppTranslations.
const List<Map<String, dynamic>> kXpLevels = [
  {'minXp': 0,   'maxXp': 100,  'level': 1, 'rankKey': 'rankRookie',         'nextLevelXp': 100},
  {'minXp': 100, 'maxXp': 300,  'level': 2, 'rankKey': 'rankTacticianPro',   'nextLevelXp': 300},
  {'minXp': 300, 'maxXp': 600,  'level': 3, 'rankKey': 'rankMasterAnalyst',  'nextLevelXp': 600},
  {'minXp': 600, 'maxXp': null, 'level': 4, 'rankKey': 'rankSpecialOne',     'nextLevelXp': 1000},
];

// ─── Gamification thresholds ─────────────────────────────────────────────────
const int kGuruBadgeMinCount = 3; // Minimum exact guesses to earn the Guru 🔮 badge

// ─── Match data ──────────────────────────────────────────────────────────────
const String kFinalMatchId       = 'm80';  // ID of the tournament final
const String kGroupMatchIdPrefix = 'g_';   // Prefix applied to group stage match IDs
const int    kGroupMatchMaxIndex = 72;     // Group stage matches are m1..m72

// ─── Animation ───────────────────────────────────────────────────────────────
const Duration kLivePulseDuration = Duration(milliseconds: 900);
const double   kLivePulseMin      = 0.25;
const double   kLivePulseMax      = 1.0;

// ─── API / Network ───────────────────────────────────────────────────────────
/// Points to the GitHub raw file updated by GitHub Actions every 15 min.
const String kApiUrl        = 'https://raw.githubusercontent.com/fnnktkygl-code/mondial_2026/main/assets/initial_matches.json';
const String kFlagCdnUrl    = 'https://flagcdn.com/w80/'; // Append "{countryCode}.png"
const String kFlagCdnSmUrl  = 'https://flagcdn.com/w40/'; // Small size variant
const Duration kApiTimeout            = Duration(seconds: 8);
const Duration kCacheRefreshInterval  = Duration(minutes: 5); // Re-fetch remote data after this

// ─── SharedPreferences keys ──────────────────────────────────────────────────
const String kMatchesCacheKey    = 'wc2026_matches_cache';
const String kPredictionsKey     = 'wc2026_user_predictions';
const String kGroupsKey          = 'wc2026_user_challenge_groups';
const String kUserIdKey          = 'wc2026_anon_user_id';

// ─── Default / fallback values ───────────────────────────────────────────────
const String kDefaultUsername = ''; // Empty → user is prompted to enter a name

// ─── Simulated friends ───────────────────────────────────────────────────────
/// Virtual rivals that appear in local challenge groups.
const List<Map<String, String>> kSimulatedFriends = [
  {'name': 'Marie 🦄',  'emblem': '🦄'},
  {'name': 'Thomas ⚡', 'emblem': '⚡'},
  {'name': 'Lucas 🛡️', 'emblem': '🛡️'},
];

// ─── Global group ────────────────────────────────────────────────────────────
const String kGlobalGroupName = 'Mondial Global Cup';
const String kGlobalGroupCode = 'GLOBAL-2026';
const String kUserEmblem      = '⚽';

// ─── Crowd prediction model ──────────────────────────────────────────────────
const double kDefaultDrawProbability = 0.20;
const double kWinProbabilityScale    = 0.80; // (1 - kDefaultDrawProbability)

/// FIFA-style strength rating (1–99) per team, used for crowd-prediction bar.
const Map<String, int> kTeamRatings = {
  'ar': 89, 'br': 88, 'fr': 87, 'es': 87,
  'en': 86, 'pt': 86, 'de': 85, 'it': 84,
  'nl': 83, 'be': 82, 'uy': 82, 'hr': 79,
  'ma': 81, 'co': 81, 'mx': 79, 'us': 78,
  'jp': 78, 'kr': 77, 'sn': 77, 'ng': 75,
  'cm': 74, 'ca': 76,
};

// ─── Snackbar / UI ───────────────────────────────────────────────────────────
const Duration kSnackBarDuration = Duration(seconds: 3);
