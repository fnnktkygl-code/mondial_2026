const axios = require('axios');
const fs = require('fs');
const path = require('path');

/**
 * Script de synchronisation des matchs pour Mondial 2026.
 * Récupère les données depuis API-Football et met à jour assets/initial_matches.json.
 */

const API_KEY = process.env.FOOTBALL_API_KEY;
const BASE_URL = 'https://v3.football.api-sports.io';
const LEAGUE_ID = 1; // World Cup
const SEASON = 2026;
const MATCHES_FILE = path.join(__dirname, '../assets/initial_matches.json');

// Normalisation identique à celle de l'App Flutter
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

async function updateMatches() {
  if (!API_KEY) {
    console.error('❌ Erreur : FOOTBALL_API_KEY non définie.');
    process.exit(1);
  }

  console.log('--- SYNCHRONISATION DES MATCHS ---');

  try {
    // 1. Lire le fichier local actuel
    if (!fs.existsSync(MATCHES_FILE)) {
      console.error(`❌ Erreur : Le fichier ${MATCHES_FILE} n'existe pas.`);
      process.exit(1);
    }
    const localData = JSON.parse(fs.readFileSync(MATCHES_FILE, 'utf8'));
    console.log(`Fichier local chargé : ${localData.length} matchs.`);

    // 2. Récupérer les données fraîches depuis l'API
    console.log(`Récupération des données API (League ${LEAGUE_ID}, Season ${SEASON})...`);
    const response = await axios.get(`${BASE_URL}/fixtures`, {
      headers: { 'x-apisports-key': API_KEY },
      params: { league: LEAGUE_ID, season: SEASON }
    }).catch(err => {
      if (err.response) {
        console.error(`❌ Erreur API (${err.response.status}):`, JSON.stringify(err.response.data));
      } else {
        console.error(`❌ Erreur Réseau :`, err.message);
      }
      throw err;
    });

    const remoteFixtures = response.data.response;
    if (!remoteFixtures || remoteFixtures.length === 0) {
      console.log('⚠️ Aucun match trouvé sur l\'API ou quota dépassé.');
      if (response.data.errors) console.log('Erreurs API:', JSON.stringify(response.data.errors));
      return;
    }

    console.log(`${remoteFixtures.length} matchs récupérés depuis l'API.`);

    // 3. Fusionner les données
    let updatedCount = 0;
    const updatedMatches = localData.map(localMatch => {
      // On cherche la correspondance par ID (format g_XXXXXX dans le JSON local)
      const apiId = parseInt(localMatch.id.replace('g_', ''));
      const apiMatch = remoteFixtures.find(f => f.fixture.id === apiId);

      if (apiMatch) {
        updatedCount++;
        
        // Extraction des buts et passes
        const goals = [];
        if (apiMatch.events) {
          apiMatch.events.forEach(event => {
            if (event.type === 'Goal') {
              goals.push({
                team: event.team.id === apiMatch.teams.home.id ? 't1' : 't2',
                scorer: event.player.name,
                assistant: event.assist.name || null,
                minute: event.time.elapsed + (event.time.extra || 0)
              });
            }
          });
        }

        return {
          ...localMatch,
          t1Score: apiMatch.goals.home,
          t2Score: apiMatch.goals.away,
          status: apiMatch.fixture.status.short === 'FT' ? 'FINISHED' : 
                  (apiMatch.fixture.status.short === 'NS' ? 'TIMED' : 'LIVE'),
          wentToET: apiMatch.fixture.status.short === 'AET',
          wentToPK: apiMatch.fixture.status.short === 'PEN',
          etWinner: apiMatch.fixture.status.short === 'AET' ? 
                    (apiMatch.teams.home.winner ? localMatch.t1 : localMatch.t2) : null,
          pkWinner: apiMatch.fixture.status.short === 'PEN' ? 
                    (apiMatch.teams.home.winner ? localMatch.t1 : localMatch.t2) : null,
          lastUpdated: new Date().toISOString(),
          goals: goals
        };
      }
      return localMatch;
    });

    // 4. Sauvegarder le fichier mis à jour
    fs.writeFileSync(MATCHES_FILE, JSON.stringify(updatedMatches, null, 2));
    console.log(`✅ Mise à jour terminée : ${updatedCount} matchs synchronisés.`);

  } catch (error) {
    console.error('❌ Erreur critique :', error.message);
    process.exit(1);
  }
}

updateMatches();
