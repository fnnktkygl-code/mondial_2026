const axios = require('axios');

const API_KEY = process.env.FOOTBALL_API_KEY;
const BASE_URL = 'https://v3.football.api-sports.io';

async function testApi() {
  if (!API_KEY || API_KEY === 'ta_cle_ici') {
    console.error('❌ Erreur : Vous devez remplacer "ta_cle_ici" par votre vraie clé API.');
    return;
  }

  console.log('--- DIAGNOSTIC API-FOOTBALL ---');

  // Test 1 : Vérification du statut de la clé
  try {
    console.log('1. Vérification du compte (/status)...');
    const statusRes = await axios.get(`${BASE_URL}/status`, {
      headers: { 'x-apisports-key': API_KEY }
    });
    
    const account = statusRes.data.response.account;
    const requests = statusRes.data.response.requests;
    
    console.log(`✅ Clé valide !`);
    console.log(`Utilisateur : ${account.firstname} ${account.lastname}`);
    console.log(`Forfait : ${statusRes.data.response.subscription.plan}`);
    console.log(`Requêtes aujourd'hui : ${requests.current}/${requests.limit_day}`);

    // Test 2 : Vérification de l'accès à la Coupe du Monde
    console.log('\n2. Vérification de l\'accès aux données World Cup...');
    const leagueRes = await axios.get(`${BASE_URL}/leagues`, {
      headers: { 'x-apisports-key': API_KEY },
      params: { id: 1 } // World Cup
    });

    if (leagueRes.data.response && leagueRes.data.response.length > 0) {
      console.log('✅ Accès à la World Cup confirmé.');
    } else {
      console.log('⚠️ Accès à la World Cup semble limité ou non trouvé.');
    }

    // Test 3 : Exemple de structure de buteur (si possible sur un match récent)
    console.log('\n3. Test structure buteurs (Match récent ID 1035080)...');
    const matchRes = await axios.get(`${BASE_URL}/fixtures`, {
      headers: { 'x-apisports-key': API_KEY },
      params: { id: 1035080 } // Un match récent pour éviter le blocage historique
    });

    if (matchRes.data.response && matchRes.data.response.length > 0) {
      const events = matchRes.data.response[0].events;
      const goals = events.filter(e => e.type === 'Goal');
      console.log(`⚽ ${goals.length} buts trouvés dans ce match.`);
      if (goals.length > 0) {
        console.log(`Format nom buteur : "${goals[0].player.name}"`);
        console.log(`Format nom passeur : "${goals[0].assist.name || 'N/A'}"`);
      }
    }

  } catch (error) {
    if (error.response && error.response.status === 403) {
      console.error('❌ Erreur 403 : Accès refusé.');
      console.log('Note : Si vous utilisez RapidAPI, essayez de remplacer "x-apisports-key" par "x-rapidapi-key" dans le code.');
    } else {
      console.error('❌ Erreur :', error.message);
    }
  }
}

testApi();
