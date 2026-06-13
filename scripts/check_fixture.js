const axios = require('axios');

const API_KEY = process.env.FOOTBALL_API_KEY;
const BASE_URL = 'https://v3.football.api-sports.io';

async function checkFixture() {
  if (!API_KEY) {
    console.error('❌ Erreur : FOOTBALL_API_KEY non définie.');
    return;
  }

  try {
    const fixtureId = 537327;
    console.log(`📡 Tentative de récupération du match ID ${fixtureId}...`);
    const response = await axios.get(`${BASE_URL}/fixtures`, {
      headers: { 'x-apisports-key': API_KEY },
      params: { id: fixtureId }
    });

    console.log('Réponse API :', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('❌ Erreur :', error.message);
  }
}

checkFixture();
