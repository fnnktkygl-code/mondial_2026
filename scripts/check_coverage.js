const axios = require('axios');

const API_KEY = process.env.FOOTBALL_API_KEY;
const BASE_URL = 'https://v3.football.api-sports.io';

async function checkCoverage() {
  if (!API_KEY) {
    console.error('❌ Erreur : FOOTBALL_API_KEY non définie.');
    return;
  }

  try {
    console.log('📡 Vérification de la couverture pour League 1 (World Cup), Season 2026...');
    const response = await axios.get(`${BASE_URL}/leagues`, {
      headers: { 'x-apisports-key': API_KEY },
      params: { id: 1, season: 2026 }
    });

    console.log('Réponse API :', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('❌ Erreur :', error.message);
  }
}

checkCoverage();
