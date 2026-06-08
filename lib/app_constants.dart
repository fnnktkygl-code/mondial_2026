/// Central constants file for the Mondial 2026 app.
/// Magic numbers, configuration values, and named constants live here.
///
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │  DATA STRATEGY — Static vs Dynamic                                      │
/// │                                                                         │
/// │  STATIC (hardcoded ici) : règles du jeu, design system, config réseau, │
/// │    gamification interne, fallbacks. Ne change pas en cours de compét.  │
/// │                                                                         │
/// │  DYNAMIC (API-Football, league=1 & season=2026) :                       │
/// │    – Fixtures / calendrier  → GET /fixtures?league=1&season=2026        │
/// │    – Standings              → GET /standings?league=1&season=2026       │
/// │    – Top scorers            → GET /players/topscorers?league=1&...      │
/// │    – Top assists            → GET /players/topassists?league=1&...      │
/// │    – Crowd predictions      → GET /predictions?fixture=FIXTURE_ID       │
/// │    – Team logos             → champ `team.logo` dans /teams             │
/// │    – Match events (live)    → GET /fixtures?live=all                    │
/// │                                                                         │
/// │  CACHE STRATEGY (plan Free = 100 req/jour) :                            │
/// │    – Fixtures   : 1x au boot + refresh toutes les 5 min si live        │
/// │    – Standings  : 1x/heure max (Hive TTL)                              │
/// │    – Top stats  : 1x/jour (Hive TTL)                                   │
/// │    – Predictions: 1x par fixture_id, write-once (Hive)                 │
/// └─────────────────────────────────────────────────────────────────────────┘
library app_constants;

// ─── API-Football ─────────────────────────────────────────────────────────────
// Clé API : variable `API_FOOTBALL_KEY` dans votre fichier .env (flutter_dotenv)
// Usage dans les services : {'x-apisports-key': dotenv.env['API_FOOTBALL_KEY']!}
const String kApiFootballBaseUrl  = 'https://v3.football.api-sports.io';
const int    kApiFootballLeagueId = 1;       // World Cup 2026
const int    kApiFootballSeason   = 2026;
const String kApiFootballHeader   = 'x-apisports-key';

// Endpoints (suffixes à concaténer avec kApiFootballBaseUrl)
const String kEndpointFixtures   = '/fixtures';
const String kEndpointStandings  = '/standings';
const String kEndpointTopScorers = '/players/topscorers';
const String kEndpointTopAssists = '/players/topassists';
const String kEndpointPrediction = '/predictions';
const String kEndpointRounds     = '/fixtures/rounds';
const String kEndpointTeams      = '/teams';

// ─── Legacy / Transitional API URL ───────────────────────────────────────────
// Utilisé par ApiService pendant la migration vers API-Football.
// À supprimer une fois ApiService entièrement migré.
const String kApiUrl = 'https://raw.githubusercontent.com/my-username/mondial_2026/main/assets/initial_matches.json';

// ─── Hive box names ──────────────────────────────────────────────────────────
const String kHiveBoxFixtures    = 'mondial_fixtures';
const String kHiveBoxStandings   = 'mondial_standings';
const String kHiveBoxTopStats    = 'mondial_top_stats';
const String kHiveBoxPredictions = 'mondial_predictions'; // key = fixture_id (int → String)

// ─── Network / Cache ─────────────────────────────────────────────────────────
const Duration kApiTimeout            = Duration(seconds: 8);
const Duration kCacheRefreshInterval  = Duration(minutes: 5);  // TTL cache fixtures (live)
const Duration kLivePollInterval      = Duration(seconds: 15); // polling pendant un match
const Duration kStandingsCacheTtl     = Duration(hours: 1);
const Duration kTopStatsCacheTtl      = Duration(hours: 24);

// ─── Scoring ─────────────────────────────────────────────────────────────────
// Phase de groupes
const int kExactScorePoints     = 30;
const int kCorrectOutcomePoints = 10;

// Phase à élimination — 90 minutes
const int kExactScoreKnockoutPoints  = 40;
const int kCorrectOutcomeKnockoutPts = 15;

// Phase à élimination — au-delà des 90 min (cumulatif)
const int kExtraTimeBonusPoints       = 20;
const int kPenaltyShootoutBonusPoints = 25;

// Bonus tournoi entier
const int kChampionBonusPoints    = 100;
const int kGoldenBootBonusPoints  = 50;
const int kTopAssisterBonusPoints = 50;

// ─── XP / Niveaux ────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> kXpLevels = [
  {'minXp': 0,   'maxXp': 100,  'level': 1, 'rankKey': 'rankRookie',        'nextLevelXp': 100},
  {'minXp': 100, 'maxXp': 300,  'level': 2, 'rankKey': 'rankTacticianPro',  'nextLevelXp': 300},
  {'minXp': 300, 'maxXp': 600,  'level': 3, 'rankKey': 'rankMasterAnalyst', 'nextLevelXp': 600},
  {'minXp': 600, 'maxXp': null, 'level': 4, 'rankKey': 'rankSpecialOne',    'nextLevelXp': 1000},
];

// ─── Gamification ────────────────────────────────────────────────────────────
const int kGuruBadgeMinCount = 3;

// ─── Structure du tournoi ─────────────────────────────────────────────────────
// kFinalMatchId : ID interne utilisé dans la logique de prédiction locale.
// Il correspond au match m80 dans le JSON de l'asset bundled.
// En parallèle, l'ID réel API-Football sera récupéré dynamiquement via
// /fixtures/rounds (dernier round = "Final") et stocké en Hive.
const String kFinalMatchId       = 'm80';
const String kGroupMatchIdPrefix = 'g_';
const int    kGroupMatchMaxIndex = 72;  // Les matchs m1..m72 sont en phase de groupes
const int    kGroupStageMatchCount = 72;
const int    kTotalMatchCount      = 104;

// ─── Animation ───────────────────────────────────────────────────────────────
const Duration kLivePulseDuration = Duration(milliseconds: 900);
const double   kLivePulseMin      = 0.25;
const double   kLivePulseMax      = 1.0;

const bool kIsLiveMode = true;

// ─── Assets / Logos ──────────────────────────────────────────────────────────
// getTeamLogoPath() : utilisé par TeamFlagWidget pour les assets bundled.
// Les logos venant de l'API-Football (team.logo URL) sont affichés via
// CachedNetworkImage dans les widgets migré, sans passer par cette fonction.
String getTeamLogoPath(String code) {
  final cleanCode = code.toLowerCase().replaceAll('g_', '');
  if (cleanCode == 'en') return 'assets/logos/gb.png';
  if (cleanCode == 'sco') return 'assets/logos/sco.png';
  return 'assets/logos/$cleanCode.png';
}

const String kLanguageFlagUrl = 'https://flagcdn.com/w40/';

// ─── SharedPreferences keys ──────────────────────────────────────────────────
const String kMatchesCacheKey = 'wc2026_matches_cache';
const String kPredictionsKey  = 'wc2026_user_predictions';
const String kGroupsKey       = 'wc2026_user_challenge_groups';
const String kUserIdKey       = 'wc2026_anon_user_id';

// ─── Valeurs par défaut ───────────────────────────────────────────────────────
const String kDefaultUsername = '';

// ─── Groupe global ────────────────────────────────────────────────────────────
const String kGlobalGroupName = 'Mondial Global Cup';
const String kGlobalGroupCode = 'GLOBAL-2026';
const String kUserEmblem      = '⚽';

// ─── Crowd prediction — modèle maison (synchrone, fallback) ──────────────────
// Utilisés dans _calculateProbability() (match_detail_sheet.dart) et
// WCOddsService lorsque les données API-Football ne sont pas encore chargées.
//
// PRIORITÉ EN PROD : remplacer par GET /predictions?fixture=ID
// → predictions.percent.{home,draw,away} (mis en cache Hive par fixture_id).
const double kDefaultDrawProbability = 0.20;
const double kWinProbabilityScale    = 0.80;

/// Notes de force FIFA-style (1–99) par équipe.
/// FALLBACK synchrone uniquement — utilisé par :
///   • WCOddsService.calculateOdds()  (calcul des cotes tournoi)
///   • match_detail_sheet._calculateProbability()  (barre crowd pre-match)
///
///
/// Points FIFA officiels utilisés pour le calcul des probabilités de match.
/// Mis à jour depuis le classement FIFA officiel (juin 2026).
/// Priorité en prod : remplacer par GET /predictions?fixture=ID
const Map<String, double> kTeamRatings = {
  'ar': 1876.12, 'es': 1873.01, 'fr': 1869.43, 'en': 1827.05,
  'pt': 1766.18, 'br': 1765.86, 'ma': 1755.10, 'nl': 1751.10,
  'be': 1742.24, 'de': 1735.77, 'hr': 1714.87, 'it': 1704.73,
  'co': 1698.35, 'mx': 1687.48, 'sn': 1686.41, 'uy': 1673.07,
  'us': 1671.23, 'jp': 1661.58, 'ch': 1650.06, 'ir': 1619.58,
  'dk': 1619.47, 'tr': 1605.73, 'ec': 1598.52, 'at': 1597.40,
  'kr': 1591.63, 'ng': 1586.69, 'au': 1579.34, 'dz': 1571.03,
  'eg': 1562.37, 'ca': 1559.48, 'no': 1557.44, 'ua': 1549.29,
  'ci': 1540.87, 'pa': 1539.16, 'ru': 1527.24, 'pl': 1526.18,
  'wa': 1516.95, 'se': 1509.79, 'cz': 1505.74, 'py': 1505.35,
  'hu': 1504.14, 'sco': 1503.34, 'rs': 1502.13, 'cm': 1481.24,
  'cd': 1479.68, 'tn': 1476.41, 'sk': 1473.66, 'gr': 1473.19,
  've': 1464.30, 'uz': 1461.21, 'pe': 1459.39, 'cr': 1457.00,
  'ro': 1455.89, 'ml': 1455.59, 'cl': 1452.94, 'iq': 1451.15,
  'qa': 1450.31, 'ie': 1441.10, 'si': 1441.09, 'za': 1428.38,
  'sa': 1421.54, 'bf': 1408.54, 'jo': 1387.74, 'ba': 1387.22,
  'hn': 1378.97, 'al': 1376.03, 'cv': 1371.11, 'ae': 1370.47,
  'mk': 1369.16, 'ni': 1366.56, 'jm': 1357.84, 'ge': 1355.26,
  'gh': 1346.88, 'is': 1343.92, 'fi': 1341.92, 'il': 1333.90,
  'bo': 1325.99, 'xk': 1319.12,
};

// ─── UI ───────────────────────────────────────────────────────────────────────
const Duration kSnackBarDuration = Duration(seconds: 3);

const double kCardRadius   = 16.0;
const double kButtonRadius = 12.0;
const double kDialogRadius = 24.0;
const double kBadgeRadius  = 8.0;

const double kPaddingSmall  = 8.0;
const double kPaddingMedium = 16.0;
const double kPaddingLarge  = 24.0;