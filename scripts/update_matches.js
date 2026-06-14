const axios = require('axios');
const fs = require('fs');
const path = require('path');

/**
 * Script de synchronisation des matchs pour Mondial 2026 via ESPN API.
 */

const MATCHES_FILE = path.join(__dirname, '../assets/initial_matches.json');
const ESPN_URL = 'https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard?dates=20260611-20260719';

const espnToInternal = {
  'MEX': 'mx', 'GER': 'de', 'USA': 'us', 'ENG': 'en', 'CAN': 'ca',
  'JPN': 'jp', 'FRA': 'fr', 'BRA': 'br', 'SEN': 'sn', 'ARG': 'ar',
  'MAR': 'ma', 'ESP': 'es', 'ITA': 'it', 'POR': 'pt', 'NED': 'nl',
  'BEL': 'be', 'CRO': 'hr', 'URU': 'uy', 'COL': 'co', 'KOR': 'kr',
  'CMR': 'cm', 'NGA': 'ng', 'SWE': 'se', 'SUI': 'ch', 'DEN': 'dk',
  'POL': 'pl', 'UKR': 'ua', 'ALG': 'dz', 'EGY': 'eg', 'TUN': 'tn',
  'GHA': 'gh', 'CIV': 'ci', 'CHI': 'cl', 'PER': 'pe', 'ECU': 'ec',
  'VEN': 've', 'AUS': 'au', 'NZL': 'nz', 'KSA': 'sa', 'IRN': 'ir',
  'TUR': 'tr', 'GRE': 'gr', 'CZE': 'cz', 'AUT': 'at', 'ROU': 'ro',
  'HUN': 'hu', 'BUL': 'bg', 'SRB': 'rs', 'RSA': 'za', 'BIH': 'ba',
  'COD': 'cd', 'CUW': 'cw', 'CPV': 'cv', 'SCO': 'sco', 'HAI': 'ht',
  'IRQ': 'iq', 'JOR': 'jo', 'NOR': 'no', 'PAN': 'pa', 'PAR': 'py',
  'QAT': 'qa', 'UZB': 'uz', 'WAL': 'wa', 'MLI': 'ml', 'BUR': 'bf',
  'JAM': 'jm', 'CRC': 'cr', 'HON': 'hn', 'SLV': 'sv', 'CUB': 'cu',
};

function mapEspnStatus(espnStatus) {
  switch (espnStatus) {
    case 'STATUS_SCHEDULED': return 'SCHEDULED';
    case 'STATUS_FIRST_HALF':
    case 'STATUS_HALFTIME':
    case 'STATUS_SECOND_HALF': return 'IN_PLAY';
    case 'STATUS_FULL_TIME':
    case 'STATUS_FINAL': return 'FINISHED';
    case 'STATUS_POSTPONED': return 'POSTPONED';
    default:
      if (espnStatus.includes('HALF') || espnStatus.includes('IN')) return 'IN_PLAY';
      return 'TIMED';
  }
}

async function updateMatches() {
  console.log('📡 RÉCUPÉRATION DES DONNÉES DE MATCH DEPUIS ESPN...');

  try {
    if (!fs.existsSync(MATCHES_FILE)) {
      console.error(`❌ Erreur : Le fichier ${MATCHES_FILE} n'existe pas.`);
      process.exit(1);
    }
    const localMatches = JSON.parse(fs.readFileSync(MATCHES_FILE, 'utf8'));

    const response = await axios.get(ESPN_URL);
    const events = response.data.events || [];

    console.log(`✅ ${events.length} événements récupérés depuis ESPN.`);

    let updatedCount = 0;

    for (const event of events) {
      const competition = event.competitions[0];
      const competitors = competition.competitors;
      
      const homeComp = competitors.find(c => c.homeAway === 'home');
      const awayComp = competitors.find(c => c.homeAway === 'away');

      const t1Code = espnToInternal[homeComp.team.abbreviation] || homeComp.team.abbreviation.toLowerCase();
      const t2Code = espnToInternal[awayComp.team.abbreviation] || awayComp.team.abbreviation.toLowerCase();

      // Trouver le match local correspondant
      const localIdx = localMatches.findIndex(m => {
        const sameTeams = (m.t1 === t1Code && m.t2 === t2Code) || (m.t1 === t2Code && m.t2 === t1Code);
        if (!sameTeams) return false;
        
        const localDate = new Date(m.date);
        const remoteDate = new Date(event.date);
        const diffHours = Math.abs(localDate - remoteDate) / 36e5;
        return diffHours < 24;
      });

      if (localIdx !== -1) {
        const local = localMatches[localIdx];
        const status = mapEspnStatus(event.status.type.name);
        
        const scoreT1 = (local.t1 === t1Code) ? parseInt(homeComp.score) : parseInt(awayComp.score);
        const scoreT2 = (local.t2 === t2Code) ? parseInt(awayComp.score) : parseInt(homeComp.score);

        const goals = [];
        const details = competition.details || [];
        for (const detail of details) {
          if (detail.type.text === 'Goal') {
            const teamKey = detail.team.id === homeComp.id ? (local.t1 === t1Code ? 't1' : 't2') : (local.t2 === t2Code ? 't2' : 't1');
            const scorer = detail.athletesInvolved && detail.athletesInvolved[0] ? detail.athletesInvolved[0].shortName : 'Unknown';
            const minute = parseInt(detail.clock.displayValue.replace("'", "")) || 0;
            goals.push({ team: teamKey, scorer, minute });
          }
        }

        // Stats basics from Scoreboard
        let stats = local.stats;
        const homeStats = homeComp.statistics || [];
        const awayStats = awayComp.statistics || [];
        
        function getStat(sList, name) {
          const s = sList.find(x => x.name === name);
          return s ? parseInt(parseFloat(s.displayValue)) : 0;
        }

        if (homeStats.length > 0) {
          const sT1 = (local.t1 === t1Code) ? homeStats : awayStats;
          const sT2 = (local.t2 === t2Code) ? awayStats : homeStats;
          
          stats = {
            possessionT1: getStat(sT1, 'possessionPct'),
            shotsT1: getStat(sT1, 'totalShots'),
            shotsT2: getStat(sT2, 'totalShots'),
            shotsOnTargetT1: getStat(sT1, 'shotsOnTarget'),
            shotsOnTargetT2: getStat(sT2, 'shotsOnTarget'),
            foulsT1: getStat(sT1, 'foulsCommitted'),
            foulsT2: getStat(sT2, 'foulsCommitted'),
            yellowCardsT1: getStat(sT1, 'yellowCards'),
            yellowCardsT2: getStat(sT2, 'yellowCards'),
            redCardsT1: getStat(sT1, 'redCards'),
            redCardsT2: getStat(sT2, 'redCards'),
          };
        }

        const hasChanged = local.t1Score !== scoreT1 || local.t2Score !== scoreT2 || local.status !== status;
        
        if (hasChanged) {
          updatedCount++;
          localMatches[localIdx] = {
            ...local,
            t1Score: scoreT1,
            t2Score: scoreT2,
            status: status,
            goals: goals,
            stats: stats,
            venue: event.venue ? event.venue.displayName : local.venue,
            lastUpdated: new Date().toISOString()
          };
        }
      }
    }

    fs.writeFileSync(MATCHES_FILE, JSON.stringify(localMatches, null, 2));

    const metaFile = path.join(__dirname, '../assets/matches_meta.json');
    if (fs.existsSync(metaFile)) {
      const meta = JSON.parse(fs.readFileSync(metaFile, 'utf8'));
      meta.lastUpdated = new Date().toISOString();
      meta.finishedMatches = localMatches.filter(m => m.status === 'FINISHED').length;
      meta.source = 'ESPN';
      fs.writeFileSync(metaFile, JSON.stringify(meta, null, 2));
    }

    console.log(`✅ Synchronisation ESPN réussie. ${updatedCount} matchs mis à jour.`);

  } catch (error) {
    console.error('❌ Erreur de synchronisation ESPN:', error.message);
    process.exit(1);
  }
}

updateMatches();
