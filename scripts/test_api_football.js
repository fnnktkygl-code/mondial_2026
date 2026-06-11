const axios = require('axios');

const API_KEY = process.env.FOOTBALL_API_KEY;
const BASE_URL = 'https://v3.football.api-sports.io';

async function deepDiveTest() {
  if (!API_KEY || API_KEY === 'ta_cle_ici') {
    console.error('❌ Erreur : FOOTBALL_API_KEY non définie. Lancez avec : FOOTBALL_API_KEY=votre_cle node scripts/test_api_football.js');
    return;
  }

  console.log('🚀 --- DEEP DIVE TEST : API-FOOTBALL V3 ---');

  try {
    // On prend un match de référence (Finale Argentine-France 2022 ID: 855750)
    // Note : Si le forfait Free bloque l'historique, on pourra tester un match live plus tard.
    const matchId = 855750; 
    
    console.log(`📡 Récupération complète du match ID : ${matchId}...`);
    
    const response = await axios.get(`${BASE_URL}/fixtures`, {
      headers: { 'x-apisports-key': API_KEY },
      params: { id: matchId }
    });

    if (!response.data.response || response.data.response.length === 0) {
      console.log('⚠️ Aucun résultat. Essai sur un match de qualification récent (ID: 1035080)...');
      const fallbackRes = await axios.get(`${BASE_URL}/fixtures`, {
        headers: { 'x-apisports-key': API_KEY },
        params: { id: 1035080 }
      });
      
      if (fallbackRes.data.response && fallbackRes.data.response.length > 0) {
        processMatch(fallbackRes.data.response[0]);
      } else {
        console.error('❌ Impossible de récupérer un match. Erreurs API :', response.data.errors);
      }
    } else {
      processMatch(response.data.response[0]);
    }

  } catch (error) {
    console.error('❌ Erreur critique :', error.message);
  }
}

function processMatch(match) {
  console.log('\n✅ DONNÉES RÉCUPÉRÉES !');
  console.log('====================================');
  console.log(`MATCH : ${match.teams.home.name} ${match.goals.home} - ${match.goals.away} ${match.teams.away.name}`);
  console.log(`STADE : ${match.fixture.venue.name}, ${match.fixture.venue.city}`);
  console.log('====================================');

  // 1. Structure des Événements (Buteurs / Passeurs)
  console.log('\n⚽ ÉVÉNEMENTS (Goals & Assists) :');
  match.events.filter(e => e.type === 'Goal').forEach(e => {
    console.log(`- BUT : ${e.player.name} [${e.time.elapsed}']`);
    console.log(`  PASSEUR : ${e.assist.name || 'Aucun'}`);
  });

  // 2. Structure des Statistiques (Possession, Tirs, etc.)
  console.log('\n📊 STATISTIQUES D\'ÉQUIPE :');
  match.statistics.forEach(s => {
    console.log(`\nStats pour ${s.team.name}:`);
    s.statistics.slice(0, 5).forEach(stat => {
      console.log(`  - ${stat.type} : ${stat.value}`);
    });
  });

  // 3. Structure des Compositions (Lineups)
  console.log('\n🏃 COMPOSITIONS (Lineups) :');
  match.lineups.forEach(l => {
    console.log(`\nFormation ${l.team.name} : ${l.formation}`);
    console.log(`Coach : ${l.coach.name}`);
    console.log(`Starters (Top 3) : ${l.startXI.slice(0, 3).map(p => p.player.name).join(', ')}...`);
  });

  console.log('\n\n💡 ANALYSE FINALE :');
  console.log('Cette API est extrêmement riche. On récupère non seulement les scores, mais aussi :');
  console.log('- Les noms EXACTS des buteurs et passeurs pour tes points.');
  console.log('- Les statistiques pour tes graphiques.');
  console.log('- Les compositions d\'équipes si tu veux ajouter un onglet "Terrain" plus tard.');
  console.log('====================================');
}

deepDiveTest();
