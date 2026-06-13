const axios = require('axios');

const API_KEY = process.env.FOOTBALL_API_KEY;
const BASE_URL = 'https://v3.football.api-sports.io';

async function check2022() {
  if (!API_KEY) {
    console.error('❌ Erreur : FOOTBALL_API_KEY non définie.');
    return;
  }

  try {
    console.log('📡 Récupération des matchs World Cup 2022 (autorisé en Free)...');
    const response = await axios.get(`${BASE_URL}/fixtures`, {
      headers: { 'x-apisports-key': API_KEY },
      params: { league: 1, season: 2022 }
    });

    const fixtures = response.data.response;
    if (fixtures && fixtures.length > 0) {
      console.log(`✅ ${fixtures.length} matchs trouvés.`);
      console.log('Exemple IDs :', fixtures.slice(0, 5).map(f => f.fixture.id));
    } else {
      console.log('Aucun match trouvé ou erreur :', response.data.errors);
    }
  } catch (error) {
    console.error('❌ Erreur :', error.message);
  }
}

check2022();
