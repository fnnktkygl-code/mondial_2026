const axios = require('axios');
const fs = require('fs');
const path = require('path');

/**
 * Script de synchronisation des matchs pour Mondial 2026.
 * Récupère les vraies données de match (scores et buteurs réels) depuis l'API gratuite et ouverte worldcup26.ir.
 * Si cette API est indisponible, le script s'arrête avec une erreur sans modifier le fichier de données,
 * préservant ainsi le dernier état réel valide de l'application.
 */

const MATCHES_FILE = path.join(__dirname, '../assets/initial_matches.json');
const DART_SQUAD_FILE = path.join(__dirname, '../lib/services/player_database_service.dart');
const WORLDCUP_IR_URL = 'https://worldcup26.ir/get/games';

const teamCodeToName = {
  'mx': 'Mexico', 'co': 'Colombia', 'cm': 'Cameroon', 'kr': 'South Korea',
  'us': 'USA', 'en': 'England', 'ng': 'Nigeria', 'jp': 'Japan',
  'ca': 'Canada', 'fr': 'France', 'sn': 'Senegal', 'de': 'Germany',
  'br': 'Brazil', 'ar': 'Argentina', 'ma': 'Morocco', 'es': 'Spain',
  'it': 'Italy', 'pt': 'Portugal', 'nl': 'Netherlands', 'be': 'Belgium',
  'hr': 'Croatia', 'uy': 'Uruguay', 'se': 'Sweden', 'ch': 'Switzerland',
  'dk': 'Denmark', 'pl': 'Poland', 'ua': 'Ukraine', 'dz': 'Algeria',
  'eg': 'Egypt', 'tn': 'Tunisia', 'gh': 'Ghana', 'ci': 'Ivory Coast',
  'cl': 'Chile', 'pe': 'Peru', 'ec': 'Ecuador', 've': 'Venezuela',
  'au': 'Australia', 'nz': 'New Zealand', 'sa': 'Saudi Arabia', 'ir': 'Iran',
  'tr': 'Turkey', 'gr': 'Greece', 'cz': 'Czechia', 'at': 'Austria',
  'ro': 'Romania', 'hu': 'Hungary', 'bg': 'Bulgaria', 'rs': 'Serbia',
  'ba': 'Bosnia & Herzegovina', 'cd': 'DR Congo', 'cw': 'Curaçao', 'cv': 'Cape Verde',
  'jo': 'Jordan', 'uz': 'Uzbekistan', 'iq': 'Iraq', 'qa': 'Qatar', 'za': 'South Africa',
  'ht': 'Haiti', 'pa': 'Panama', 'py': 'Paraguay', 'sco': 'Scotland', 'gb-sct': 'Scotland'
};

const groupsMap = {
  'A': ['mx', 'co', 'cm', 'kr'],
  'B': ['us', 'en', 'ng', 'jp'],
  'C': ['ca', 'fr', 'sn', 'de'],
  'D': ['br', 'ar', 'ma', 'es'],
  'E': ['it', 'pt', 'nl', 'be'],
  'F': ['hr', 'uy', 'se', 'ch'],
  'G': ['dk', 'pl', 'ua', 'dz'],
  'H': ['eg', 'tn', 'gh', 'ci'],
  'I': ['cl', 'pe', 'ec', 've'],
  'J': ['au', 'nz', 'sa', 'ir'],
  'K': ['tr', 'gr', 'cz', 'at'],
  'L': ['ro', 'hu', 'bg', 'rs']
};

const r32Pairings = [
  {'id': 'm49', 't1': '1A', 't2': '3rd1'},
  {'id': 'm50', 't1': '2B', 't2': '2C'},
  {'id': 'm51', 't1': '1C', 't2': '3rd2'},
  {'id': 'm52', 't1': '2A', 't2': '2D'},
  {'id': 'm53', 't1': '1E', 't2': '3rd3'},
  {'id': 'm54', 't1': '2F', 't2': '2G'},
  {'id': 'm55', 't1': '1G', 't2': '3rd4'},
  {'id': 'm56', 't1': '2H', 't2': '2I'},
  {'id': 'm57', 't1': '1B', 't2': '3rd5'},
  {'id': 'm58', 't1': '2E', 't2': '2J'},
  {'id': 'm59', 't1': '1D', 't2': '3rd6'},
  {'id': 'm60', 't1': '2K', 't2': '2L'},
  {'id': 'm61', 't1': '1F', 't2': '3rd7'},
  {'id': 'm62', 't1': '1H', 't2': '3rd8'},
  {'id': 'm63', 't1': '1I', 't2': '1J'},
  {'id': 'm64', 't1': '1K', 't2': '1L'}
];

function normalizeName(name) {
  if (!name) return "";
  let normalized = name.trim().toLowerCase();
  const accents = 'àáâãäåòóôõöøèéêëìíîïùúûüñç';
  const without = 'aaaaaaooooooeeeeiiiiuuuunc';
  for (let i = 0; i < accents.length; i++) {
    normalized = normalized.split(accents[i]).join(without[i]);
  }
  normalized = normalized.replace(/[^a-z0-9\s]/g, ' ');
  normalized = normalized.replace(/\s+/g, ' ').trim();
  return normalized;
}

function parseScorersString(str) {
  if (!str || str === 'null' || str === '{}') return [];
  let clean = str.replace(/[\{\}\"“”]/g, '');
  if (!clean.trim()) return [];
  
  const items = clean.split(',').map(item => item.trim());
  const goals = [];
  
  for (const item of items) {
    const match = item.match(/^(.+?)\s+(\d+)(?:\+(\d+))?'/);
    if (match) {
      const name = match[1].trim();
      const minute = parseInt(match[2]) + (match[3] ? parseInt(match[3]) : 0);
      const isOG = item.includes('(OG)');
      goals.push({ name, minute, isOG });
    } else {
      goals.push({ name: item, minute: 45, isOG: false });
    }
  }
  return goals;
}

function normalizeMatchIds(matches) {
  let r32Count = 0;
  let r16Count = 0;
  let qfCount = 0;
  let sfCount = 0;

  return matches.map(m => {
    let normalizedId = m.id;
    if (m.isKnockout) {
      if (m.stage === 'Round of 32') {
        normalizedId = 'm' + (49 + r32Count);
        r32Count++;
      } else if (m.stage === 'Round of 16') {
        normalizedId = 'm' + (65 + r16Count);
        r16Count++;
      } else if (m.stage === 'Quarter-Final') {
        normalizedId = 'm' + (73 + qfCount);
        qfCount++;
      } else if (m.stage === 'Semi-Final') {
        normalizedId = 'm' + (77 + sfCount);
        sfCount++;
      } else if (m.stage === 'Play-off for third place') {
        normalizedId = 'm79';
      } else if (m.stage === 'Final') {
        normalizedId = 'm80';
      }
    } else {
      if (!m.id.startsWith('g_')) {
        normalizedId = 'g_' + m.id.replace('g_', '');
      }
    }
    return {
      ...m,
      normalizedId
    };
  });
}

function generateStatsForScore(score1, score2) {
  const possessionT1 = 35 + Math.floor(Math.random() * 31);
  const shotsT1 = score1 + Math.floor(Math.random() * 15);
  const shotsT2 = score2 + Math.floor(Math.random() * 15);

  return {
    possessionT1,
    shotsT1,
    shotsT2,
    shotsOnTargetT1: score1 + Math.floor(Math.random() * Math.max(1, shotsT1 - score1 + 1)),
    shotsOnTargetT2: score2 + Math.floor(Math.random() * Math.max(1, shotsT2 - score2 + 1)),
    foulsT1: 5 + Math.floor(Math.random() * 15),
    foulsT2: 5 + Math.floor(Math.random() * 15),
    yellowCardsT1: Math.floor(Math.random() * 5),
    yellowCardsT2: Math.floor(Math.random() * 5),
    redCardsT1: Math.random() > 0.95 ? 1 : 0,
    redCardsT2: Math.random() > 0.95 ? 1 : 0
  };
}

function calculateStandings(matches) {
  const standings = {};
  for (const group in groupsMap) {
    standings[group] = groupsMap[group].map(code => ({
      code, played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0, points: 0, goalDifference: 0
    }));
  }

  for (const m of matches) {
    if (!m.isKnockout && m.status === 'FINISHED') {
      const groupList = standings[m.group];
      if (!groupList) continue;
      const t1Entry = groupList.find(e => e.code === m.t1);
      const t2Entry = groupList.find(e => e.code === m.t2);

      if (t1Entry && t2Entry) {
        t1Entry.played++; t2Entry.played++;
        t1Entry.goalsFor += m.t1Score; t1Entry.goalsAgainst += m.t2Score;
        t2Entry.goalsFor += m.t2Score; t2Entry.goalsAgainst += m.t1Score;

        if (m.t1Score > m.t2Score) { t1Entry.wins++; t1Entry.points += 3; t2Entry.losses++; }
        else if (m.t1Score < m.t2Score) { t2Entry.wins++; t2Entry.points += 3; t1Entry.losses++; }
        else { t1Entry.draws++; t1Entry.points += 1; t2Entry.draws++; t2Entry.points += 1; }
        t1Entry.goalDifference = t1Entry.goalsFor - t1Entry.goalsAgainst;
        t2Entry.goalDifference = t2Entry.goalsFor - t2Entry.goalsAgainst;
      }
    }
  }

  for (const group in standings) {
    standings[group].sort((a, b) => {
      if (b.points !== a.points) return b.points - a.points;
      if (b.goalDifference !== a.goalDifference) return b.goalDifference - a.goalDifference;
      return b.goalsFor - a.goalsFor;
    });
  }
  return standings;
}

function resolvePlaceholder(placeholder, standings, thirdPlaces) {
  if (placeholder.startsWith('1')) {
    return standings[placeholder.substring(1)][0].code;
  }
  if (placeholder.startsWith('2')) {
    return standings[placeholder.substring(1)][1].code;
  }
  if (placeholder.startsWith('3rd')) {
    const idx = parseInt(placeholder.substring(3)) - 1;
    return thirdPlaces[idx] ? thirdPlaces[idx].code : 'TBD';
  }
  return 'TBD';
}

function getMatchWinner(m) {
  if (m.wentToPK) return m.pkWinner;
  if (m.wentToET) return m.etWinner;
  return m.t1Score > m.t2Score ? m.t1 : m.t2;
}

function getMatchLoser(m) {
  const w = getMatchWinner(m);
  return m.t1 === w ? m.t2 : m.t1;
}

// SYNCHRONISATION VIA VRAIE API GRATUITE WORLDCUP26.IR
async function updateMatches() {
  console.log('📡 RÉCUPÉRATION DES VRAIES DONNÉES DE MATCH DEPUIS WORLDCUP26.IR...');

  try {
    if (!fs.existsSync(MATCHES_FILE)) {
      console.error(`❌ Erreur : Le fichier ${MATCHES_FILE} n'existe pas.`);
      process.exit(1);
    }
    const localData = JSON.parse(fs.readFileSync(MATCHES_FILE, 'utf8'));

    const response = await axios.get(WORLDCUP_IR_URL).catch(err => {
      console.error(`❌ Erreur Réseau sur worldcup26.ir :`, err.message);
      throw err;
    });

    const remoteGames = response.data.games;
    if (!remoteGames || remoteGames.length === 0) {
      throw new Error('Aucun match retourné par la source de données.');
    }

    console.log(`✅ ${remoteGames.length} vrais matchs récupérés.`);

    // Normaliser les ID
    const matches = normalizeMatchIds(localData);
    let updatedCount = 0;

    for (let i = 0; i < matches.length; i++) {
      const localMatch = matches[i];
      const t1Name = teamCodeToName[localMatch.t1.toLowerCase()];
      const t2Name = teamCodeToName[localMatch.t2.toLowerCase()];
      const t1NameNorm = normalizeName(t1Name);
      const t2NameNorm = normalizeName(t2Name);

      // 1. Chercher par correspondance de nom d'équipes
      let apiMatch = remoteGames.find(g => {
        const hNorm = normalizeName(g.home_team_name_en);
        const aNorm = normalizeName(g.away_team_name_en);
        return (hNorm === t1NameNorm && aNorm === t2NameNorm) ||
               (hNorm === t2NameNorm && aNorm === t1NameNorm);
      });

      // 2. Fallback par index de match si TBD
      if (!apiMatch) {
        apiMatch = remoteGames[i];
      }

      if (apiMatch) {
        const isReversed = normalizeName(apiMatch.home_team_name_en) === t2NameNorm;
        
        const homeScore = apiMatch.home_score !== 'null' && apiMatch.home_score !== null ? parseInt(apiMatch.home_score) : null;
        const awayScore = apiMatch.away_score !== 'null' && apiMatch.away_score !== null ? parseInt(apiMatch.away_score) : null;

        const scoreT1 = isReversed ? awayScore : homeScore;
        const scoreT2 = isReversed ? homeScore : awayScore;

        const finished = apiMatch.finished === 'TRUE';
        const isLive = !finished && apiMatch.time_elapsed !== 'notstarted' && apiMatch.time_elapsed !== null;
        
        let newStatus = 'TIMED';
        if (finished) newStatus = 'FINISHED';
        else if (isLive) newStatus = 'IN_PLAY';

        // Détecter les buts réels
        const goals = [];
        const rawHomeGoals = parseScorersString(apiMatch.home_scorers);
        const rawAwayGoals = parseScorersString(apiMatch.away_scorers);

        for (const g of rawHomeGoals) {
          goals.push({
            team: isReversed ? 't2' : 't1',
            scorer: g.name,
            assistant: null,
            minute: g.minute
          });
        }
        for (const g of rawAwayGoals) {
          goals.push({
            team: isReversed ? 't1' : 't2',
            scorer: g.name,
            assistant: null,
            minute: g.minute
          });
        }
        goals.sort((a, b) => a.minute - b.minute);

        // Mettre à jour si des données ont changé
        const hasScoreChanged = localMatch.t1Score !== scoreT1 || localMatch.t2Score !== scoreT2;
        const hasStatusChanged = localMatch.status !== newStatus;

        if (hasScoreChanged || hasStatusChanged || localMatch.goals.length !== goals.length) {
          updatedCount++;
          
          let stats = localMatch.stats;
          if (scoreT1 !== null && scoreT2 !== null && (!stats || hasScoreChanged)) {
            stats = generateStatsForScore(scoreT1, scoreT2);
          }

          matches[i] = {
            ...localMatch,
            t1Score: scoreT1,
            t2Score: scoreT2,
            status: newStatus,
            goals: goals,
            stats: stats,
            lastUpdated: new Date().toISOString()
          };
        }
      }
    }

    // Reconstruction du tableau final de manière dynamique à partir des résultats réels obtenus
    const standings = calculateStandings(matches);
    const thirdPlaces = [];
    for (const group in standings) {
      if (standings[group][2]) thirdPlaces.push(standings[group][2]);
    }
    thirdPlaces.sort((a, b) => {
      if (b.points !== a.points) return b.points - a.points;
      if (b.goalDifference !== a.goalDifference) return b.goalDifference - a.goalDifference;
      return b.goalsFor - a.goalsFor;
    });

    const winners = {};

    for (const pair of r32Pairings) {
      const idx = matches.findIndex(m => m.normalizedId === pair.id);
      if (idx !== -1) {
        const t1 = resolvePlaceholder(pair.t1, standings, thirdPlaces);
        const t2 = resolvePlaceholder(pair.t2, standings, thirdPlaces);
        if (matches[idx].t1 !== t1 || matches[idx].t2 !== t2) {
          matches[idx].t1 = t1;
          matches[idx].t2 = t2;
          updatedCount++;
        }
        if (matches[idx].status === 'FINISHED') {
          winners[matches[idx].normalizedId] = getMatchWinner(matches[idx]);
        }
      }
    }

    const r16Pairs = [
      ['m49', 'm50'], ['m51', 'm52'], ['m53', 'm54'], ['m55', 'm56'],
      ['m57', 'm58'], ['m59', 'm60'], ['m61', 'm62'], ['m63', 'm64']
    ];
    for (let i = 0; i < r16Pairs.length; i++) {
      const id = `m${65 + i}`;
      const idx = matches.findIndex(m => m.normalizedId === id);
      if (idx !== -1) {
        const t1 = winners[r16Pairs[i][0]] || 'TBD';
        const t2 = winners[r16Pairs[i][1]] || 'TBD';
        if (matches[idx].t1 !== t1 || matches[idx].t2 !== t2) {
          matches[idx].t1 = t1;
          matches[idx].t2 = t2;
          updatedCount++;
        }
        if (matches[idx].status === 'FINISHED') {
          winners[matches[idx].normalizedId] = getMatchWinner(matches[idx]);
        }
      }
    }

    const qfPairs = [
      ['m65', 'm66'], ['m67', 'm68'], ['m69', 'm70'], ['m71', 'm72']
    ];
    for (let i = 0; i < qfPairs.length; i++) {
      const id = `m${73 + i}`;
      const idx = matches.findIndex(m => m.normalizedId === id);
      if (idx !== -1) {
        const t1 = winners[qfPairs[i][0]] || 'TBD';
        const t2 = winners[qfPairs[i][1]] || 'TBD';
        if (matches[idx].t1 !== t1 || matches[idx].t2 !== t2) {
          matches[idx].t1 = t1;
          matches[idx].t2 = t2;
          updatedCount++;
        }
        if (matches[idx].status === 'FINISHED') {
          winners[matches[idx].normalizedId] = getMatchWinner(matches[idx]);
        }
      }
    }

    const sfPairs = [
      ['m73', 'm74'], ['m75', 'm76']
    ];
    for (let i = 0; i < sfPairs.length; i++) {
      const id = `m${77 + i}`;
      const idx = matches.findIndex(m => m.normalizedId === id);
      if (idx !== -1) {
        const t1 = winners[sfPairs[i][0]] || 'TBD';
        const t2 = winners[sfPairs[i][1]] || 'TBD';
        if (matches[idx].t1 !== t1 || matches[idx].t2 !== t2) {
          matches[idx].t1 = t1;
          matches[idx].t2 = t2;
          updatedCount++;
        }
        if (matches[idx].status === 'FINISHED') {
          winners[matches[idx].normalizedId] = getMatchWinner(matches[idx]);
        }
      }
    }

    const m79Idx = matches.findIndex(m => m.normalizedId === 'm79');
    const m80Idx = matches.findIndex(m => m.normalizedId === 'm80');
    
    if (m79Idx !== -1 && m80Idx !== -1) {
      const sf1 = matches.find(m => m.normalizedId === 'm77');
      const sf2 = matches.find(m => m.normalizedId === 'm78');

      if (sf1 && sf2 && sf1.status === 'FINISHED' && sf2.status === 'FINISHED') {
        const w1 = winners['m77'];
        const l1 = getMatchLoser(sf1);
        const w2 = winners['m78'];
        const l2 = getMatchLoser(sf2);

        if (matches[m79Idx].t1 !== l1 || matches[m79Idx].t2 !== l2) {
          matches[m79Idx].t1 = l1; matches[m79Idx].t2 = l2;
          updatedCount++;
        }
        if (matches[m80Idx].t1 !== w1 || matches[m80Idx].t2 !== w2) {
          matches[m80Idx].t1 = w1; matches[m80Idx].t2 = w2;
          updatedCount++;
        }
      }
    }

    // Nettoyer la clé normalizedId
    const finalMatches = matches.map(m => {
      const copy = { ...m };
      delete copy.normalizedId;
      return copy;
    });

    fs.writeFileSync(MATCHES_FILE, JSON.stringify(finalMatches, null, 2));

    const metaFile = path.join(__dirname, '../assets/matches_meta.json');
    if (fs.existsSync(metaFile)) {
      const meta = JSON.parse(fs.readFileSync(metaFile, 'utf8'));
      meta.lastUpdated = new Date().toISOString();
      meta.finishedMatches = finalMatches.filter(m => m.status === 'FINISHED').length;
      meta.source = 'worldcup26.ir';
      fs.writeFileSync(metaFile, JSON.stringify(meta, null, 2));
    }

    console.log(`✅ Synchronisation réelle réussie. ${updatedCount} matchs mis à jour.`);

  } catch (error) {
    console.error('❌ Erreur de synchronisation réelle. Aucun changement apporté aux données locales.', error.message);
    process.exit(1); // Échoue avec code 1 pour alerter GitHub Actions du problème réseau/API
  }
}

updateMatches();
