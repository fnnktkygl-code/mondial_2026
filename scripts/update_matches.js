/**
 * update_matches.js
 * Fetches live FIFA World Cup 2026 data from football-data.org
 * and writes assets/initial_matches.json in the app's schema.
 *
 * Usage:
 *   FOOTBALL_API_KEY=<your_key> node scripts/update_matches.js
 *
 * Run automatically via GitHub Actions (.github/workflows/update_matches.yml)
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const API_KEY = process.env.FOOTBALL_API_KEY || 'cb1ed7d2f34548a9b75a9e6a2ec4e5ce';
const OUTPUT_PATH = path.join(__dirname, '..', 'assets', 'initial_matches.json');

// Map football-data.org 3-letter TLA → 2-letter ISO country code used by the app
// (used for flag CDN URLs and team translations)
const TLA_TO_ISO = {
  MEX: 'mx', RSA: 'za', KOR: 'kr', CZE: 'cz', CAN: 'ca', BIH: 'ba',
  USA: 'us', PAR: 'py', QAT: 'qa', SUI: 'ch', BRA: 'br', MAR: 'ma',
  HAI: 'ht', SCO: 'gb-sct', AUS: 'au', TUR: 'tr', GER: 'de', CUW: 'cw',
  NED: 'nl', JPN: 'jp', CIV: 'ci', ECU: 'ec', SWE: 'se', TUN: 'tn',
  ESP: 'es', CPV: 'cv', BEL: 'be', EGY: 'eg', KSA: 'sa', URY: 'uy',
  IRN: 'ir', NZL: 'nz', FRA: 'fr', SEN: 'sn', IRQ: 'iq', NOR: 'no',
  ARG: 'ar', ALG: 'dz', AUT: 'at', JOR: 'jo', POR: 'pt', COD: 'cd',
  ENG: 'en', CRO: 'hr', GHA: 'gh', PAN: 'pa', UZB: 'uz', COL: 'co',
  // Fallbacks
  POL: 'pl', UKR: 'ua', SRB: 'rs', NGR: 'ng', CMR: 'cm', CHL: 'cl',
  PER: 'pe', GRE: 'gr', ITA: 'it', DEN: 'dk', ROM: 'ro', HUN: 'hu',
  DAN: 'dk',
};

// Map football-data.org stage codes → app stage strings
const STAGE_MAP = {
  'GROUP_STAGE': null,                           // uses group field instead
  'LAST_32': 'Round of 32',
  'LAST_16': 'Round of 16',
  'ROUND_OF_16': 'Round of 16',
  'QUARTER_FINALS': 'Quarter-Final',
  'SEMI_FINALS': 'Semi-Final',
  'THIRD_PLACE': 'Play-off for third place',
  'FINAL': 'Final',
};


// Map football-data.org group codes → single letter
function parseGroup(groupStr) {
  if (!groupStr) return null;
  // GROUP_A → A
  const m = groupStr.match(/GROUP_([A-Z0-9]+)/);
  return m ? m[1] : null;
}

function fetch(url, headers) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { headers }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error(`JSON parse error: ${e.message}\nBody: ${data.substring(0, 200)}`)); }
      });
    });
    req.on('error', reject);
  });
}

function tlaToIso(tla) {
  if (!tla) return 'tbd';  // Knockout stage placeholder — team not yet determined
  return TLA_TO_ISO[tla] || tla.toLowerCase().substring(0, 2);
}

async function main() {
  console.log('🌍 Fetching FIFA World Cup 2026 matches...');

  const headers = { 'X-Auth-Token': API_KEY };

  // 1. Fetch all matches
  const matchData = await fetch(
    'https://api.football-data.org/v4/competitions/WC/matches',
    headers
  );

  if (!matchData.matches || matchData.matches.length === 0) {
    console.error('❌ No matches returned from API');
    process.exit(1);
  }

  console.log(`✅ Got ${matchData.matches.length} matches`);

  // 2. Fetch scorers (only available once tournament starts)
  let scorersData = null;
  try {
    scorersData = await fetch(
      'https://api.football-data.org/v4/competitions/WC/scorers?limit=50',
      headers
    );
    console.log(`✅ Got ${scorersData.scorers?.length || 0} top scorers`);
  } catch (e) {
    console.warn('⚠️  Could not fetch scorers (may not be available yet):', e.message);
  }

  // Build scorer lookup: playerName → { goals, assists }
  const scorerLookup = {};
  if (scorersData?.scorers) {
    for (const s of scorersData.scorers) {
      scorerLookup[s.player.name] = {
        goals: s.goals || 0,
        assists: s.assists || 0,
      };
    }
  }

  // 3. Fetch match details for FINISHED matches to get goals
  // The free tier doesn't include goals in the list endpoint, 
  // but we can try the individual match endpoint
  const finishedMatches = matchData.matches.filter(m => m.status === 'FINISHED');
  console.log(`📊 ${finishedMatches.length} finished matches, ${matchData.matches.length - finishedMatches.length} upcoming`);

  // Build a map of match details with goals
  const matchGoals = {};
  if (finishedMatches.length > 0) {
    console.log('🔍 Fetching goal details for finished matches...');
    // Rate limit: 10 req/min → fetch in batches with delay
    for (let i = 0; i < finishedMatches.length; i++) {
      const m = finishedMatches[i];
      try {
        const detail = await fetch(
          `https://api.football-data.org/v4/matches/${m.id}`,
          headers
        );
        if (detail.goals && detail.goals.length > 0) {
          matchGoals[m.id] = detail.goals.map(g => ({
            team: g.team?.tla === m.homeTeam.tla ? 't1' : 't2',
            scorer: g.scorer?.name || 'Unknown',
            assistant: g.assist?.name || null,
            minute: g.minute,
          }));
        } else {
          matchGoals[m.id] = [];
        }

        // Rate limiting: max 10 req/min → ~6s between requests
        if (i < finishedMatches.length - 1) {
          await new Promise(r => setTimeout(r, 6500));
        }
        process.stdout.write(`  Match ${i + 1}/${finishedMatches.length} done\r`);
      } catch (e) {
        console.warn(`  ⚠️  Could not fetch goals for match ${m.id}:`, e.message);
        matchGoals[m.id] = [];
      }
    }
    console.log('\n✅ Goal details fetched');
  }

  // 4. Transform to app schema
  const appMatches = matchData.matches.map((m, idx) => {
    const isGroupStage = m.stage === 'GROUP_STAGE';
    const stage = STAGE_MAP[m.stage] || m.stage;
    const group = isGroupStage ? parseGroup(m.group) : null;
    const isFinished = m.status === 'FINISHED';

    return {
      id: isGroupStage
        ? `g_${m.id}`        // prefix group stage IDs to avoid collisions
        : `m${m.id}`,
      date: m.utcDate,
      t1: tlaToIso(m.homeTeam?.tla),
      t2: tlaToIso(m.awayTeam?.tla),
      t1Score: isFinished ? (m.score?.fullTime?.home ?? null) : null,
      t2Score: isFinished ? (m.score?.fullTime?.away ?? null) : null,
      venue: null,            // not provided by free tier, kept null
      group: group,
      stage: isGroupStage ? null : stage,
      isKnockout: !isGroupStage,
      status: m.status,      // TIMED / SCHEDULED / IN_PLAY / FINISHED
      lastUpdated: m.lastUpdated,
      goals: isFinished ? (matchGoals[m.id] || []) : [],
      stats: null,            // not in free tier
    };
  });

  // Sort: group stage first by date, then knockout by date
  appMatches.sort((a, b) => new Date(a.date) - new Date(b.date));

  // 5. Write output
  const wrapper = {
    lastUpdated: new Date().toISOString(),
    source: 'football-data.org',
    competition: 'FIFA World Cup 2026',
    matches: appMatches,
  };

  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(wrapper.matches, null, 2));
  console.log(`\n🎉 Written ${appMatches.length} matches to ${OUTPUT_PATH}`);
  console.log(`   Last updated: ${wrapper.lastUpdated}`);

  // Also write metadata file for the app to read
  const metaPath = path.join(__dirname, '..', 'assets', 'matches_meta.json');
  fs.writeFileSync(metaPath, JSON.stringify({
    lastUpdated: wrapper.lastUpdated,
    source: wrapper.source,
    totalMatches: appMatches.length,
    finishedMatches: finishedMatches.length,
  }, null, 2));
  console.log(`   Metadata written to ${metaPath}`);
}

main().catch(err => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});
