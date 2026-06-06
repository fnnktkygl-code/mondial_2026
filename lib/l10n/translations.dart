class AppTranslations {
  static const Map<String, String> _emblems = {
    'mx': '🦅', // El Tri / Aigle
    'co': '☕', // Cafeteros
    'cm': '🦁', // Lions Indomptables
    'kr': '🐯', // Guerriers Taeguk / Tigres
    'us': '🦅', // Stars & Stripes
    'en': '🦁', // Three Lions
    'ng': '🦅', // Super Eagles
    'jp': '🦅', // Blue Samurai
    'ca': '🍁', // Maple Leafs
    'fr': '🐓', // Le Coq gaulois
    'sn': '🦁', // Lions de la Téranga
    'de': '🦅', // Mannschaft
    'br': '🐆', // Jaguar / Seleção
    'ar': '☀️', // Albiceleste
    'ma': '🦁', // Lions de l'Atlas
    'es': '🐂', // Toro / La Roja
    'it': '🐺', // Azzurri / Loup
    'pt': '🛡️', // Quinas / Navigateurs
    'nl': '🦁', // Lion / Oranje
    'be': '😈', // Diables Rouges
    'hr': '🐆', // Vatreni
    'uy': '☀️', // Celeste
    'se': '🛡️', // Blågult
    'ch': '⛰️', // Nati
    'dk': '🛡️', // Danish Dynamite
    'pl': '🦅', // Aigles Blancs
    'ua': '🌻', // Sbirna
    'dz': '🦊', // Fennecs
    'eg': '🦅', // Pharaons
    'tn': '🦅', // Aigles de Carthage
    'gh': '🌟', // Black Stars
    'ci': '🐘', // Éléphants
    'cl': '⛰️', // La Roja
    'pe': '🦙', // La Blanquirroja
    'ec': '🦅', // La Tri
    've': '🦜', // La Vinotinto
    'au': '🦘', // Socceroos
    'nz': '🥝', // All Whites / Kiwis
    'sa': '🌴', // Faucons Verts
    'ir': '🐆', // Guépards Perses
    'tr': '🌙', // Bizim Çocuklar
    'gr': '🛡️', // Bateau Pirate
    'cz': '🦁', // Narodak
    'at': '🦅', // Das Team
    'ro': '🦅', // Tricolorii
    'hu': '🦅', // Magyars
    'bg': '🦁', // Lions Bulgare
    'rs': '🦅', // Aigles Serbe
  };

  static const Map<String, Map<String, dynamic>> _data = {
    'fr': {
      'appTitle': 'Mondial 2026',
      'allMatches': 'Tous les matchs',
      'myAlerts': 'Mes alertes',
      'group': 'Groupe',
      'setAlertTitle': 'Configurer une alerte',
      'alert1Day': '1 jour avant',
      'alert1Hour': '1 heure avant',
      'alert30Min': '30 min avant',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'removeAlert': 'Supprimer',
      'timezoneInfo': 'Heures locales',
      'noAlerts': 'Aucune alerte configurée.',
      'listView': 'Liste',
      'calendarView': 'Calendrier',
      'loading': 'Chargement du calendrier API...',
      'prevWeek': 'Semaine préc.',
      'nextWeek': 'Semaine suiv.',
      'today': 'Tournoi',
      'knockouts': 'Phase Finale',
      'standings': 'Classement',
      'pos': 'Pos',
      'team': 'Équipe',
      'played': 'J',
      'pts': 'Pts',
      'gd': 'Diff',
      'wins': 'G',
      'draws': 'N',
      'losses': 'P',
      'goalsFor': 'BP',
      'goalsAgainst': 'BC',
      'scorers': 'Buteurs',
      'assists': 'Passeurs',
      'stats': 'Statistiques',
      'possession': 'Possession',
      'shots': 'Tirs',
      'shotsOnTarget': 'Tirs cadrés',
      'fouls': 'Fautes commises',
      'yellowCards': 'Cartons jaunes',
      'redCards': 'Cartons rouges',
      'liveMode': 'Mode Live',
      'simMode': 'Mode Simulé',
      'bracket': 'Tableau',
      'simulator': 'Simulateur',
      'r32': '16es de finale',
      'r16': '8es de finale',
      'qf': 'Quarts',
      'sf': 'Demi-finales',
      'f': 'Finale',
      'groupsTab': 'Groupes',
      'scorersTab': 'Buteurs',
      'assistsTab': 'Passeurs',
      'teamStatsTab': 'Stats Équipe',
      'challengeTab': 'Challenge',
      'myPredictions': 'Mes Pronos',
      'friendGroups': 'Groupes d\'Amis',
      'bonusBets': 'Bonus',
      'predictChampion': 'Champion Mondial 2026',
      'predictScorer': 'Soulier d\'Or (Buteur)',
      'createGroup': 'Créer un groupe',
      'joinGroup': 'Rejoindre un groupe',
      'groupName': 'Nom du groupe',
      'groupCode': 'Code du groupe',
      'shareInvite': 'Rejoins mon groupe de pronos {groupName}! Code: {code}',
      'copyCode': 'Copier le code',
      'copied': 'Copié !',
      'enterCode': 'Coller un code de groupe',
      'enterName': 'Modifier mon pseudo',
      'totalPoints': 'Points',
      'ranking': 'Rang',
      'pointsSuffix': 'pts',
      'exactPoints': 'Exact (+30 pts)',
      'outcomePoints': 'Résultat (+10 pts)',
      'noPoints': 'Incorrect (0 pts)',
      'predictButton': 'Valider le prono',
      'selectWinner': 'Choisir le vainqueur',
      'goalsScored': 'Buts marqués',
      'goalsConceded': 'Buts encaissés',
      'matchesPlayed': 'Matchs joués',
      'squadStats': 'Stats de l\'effectif',
      // ── Gamification ───────────────────────────────────────────────────────
      'rankRookie':        'Rookie 🥉',
      'rankTacticianPro': 'Tacticien Pro 🥈',
      'rankMasterAnalyst':'Maître Analyste 🥇',
      'rankSpecialOne':   'The Special One 👑',
      'favTeamLabel':     'Supporté :',
      'chooseTeam':       'Choisir',
      'boosterLabel':     'Double Points (Joker)',
      'boosterActive':    'JOKER ACTIVÉ (Score doublé !)',
      'leaderboardError': 'Erreur lors du chargement du classement',
      'noUsers':          'Aucun utilisateur pour le moment',
      'pseudoUpdated':    'Pseudo mis à jour !',
      'teamUpdated':      'Équipe supportée mise à jour & alertes activées !',
      'championSaved':    'Champion enregistré !',
      'scorerSaved':      'Buteur bonus enregistré !',
      'groupCreated':     'Groupe créé !',
      'groupJoined':      'Groupe rejoint avec succès !',
      'groupJoinFailed':  'Code invalide ou groupe déjà rejoint',
      'groupStage':       'Phase de Poules',
      'knockoutStage':    'Phase Finale',
      'youSuffix':        ' (Vous)',
      // ── Match detail sheet ────────────────────────────────────────────────
      'crowdPredictions': 'PRONOSTICS DU PUBLIC',
      'drawLabel':        'Nul',
      'triviaTitle':      'Humour & Anecdotes',
      'alertReminderSet': 'Rappel configuré pour {t1} vs {t2} !',
      'dbResetSuccess':   'Base de données réinitialisée avec succès.',
      'resetTournament':  'Réinitialiser le tournoi',
      'groupStageFilter': 'Phase de Poules',
      'knockoutFilter':   'Phase Finale',
      'predGroupStage':   'Phase de Poules',
      'predKnockout':     'Phase Finale',
      'jokes': {
        'default': 'Un match qui s\'annonce spectaculaire ! Préparez le pop-corn. 🍿⚽',
        'mx_de': 'Attention aux secousses sismiques à Mexico ! Rappelez-vous 2018... 🇲🇽⚡🇩🇪',
        'us_en': 'Le derby historique du mot "Soccer". Qui a raison ? 🇺🇸⚽🇬🇧',
        'ca_jp': 'Le sirop d\'érable face au sushi mécanique. 🍁🍣',
        'fr_br': 'L\'ombre de 1998 et 2006 plane toujours... Un duel légendaire ! 🇫🇷🇧🇷✨',
        'sn_ar': 'Le rythme endiablé des Lions face au tango argentin. 🇸🇳🕺🇦🇷',
        'ma_es': 'Un parfum de 2022... Attention aux séances de tirs au but ! 🇲🇦🧤🇪🇸',
        'it_pt': 'Le choc de deux géants européens qui ont faim de victoires. 🇮🇹🇵🇹⚽',
        'nl_be': 'Le derby des Plats Pays. Qui aura la meilleure frite ? 🍟🇧🇪🇳🇱',
        'hr_uy': 'La grinta céleste contre le fighting spirit croate. 🇺🇾🇭🇷💪',
        'jp_fr': 'Match de haut vol. Est-ce que le Bleus feront face à la rigueur des Samouraïs ? 🇯🇵🇫🇷',
        'br_sn': 'Le beau jeu du Brésil contre la puissance physique des Lions du Sénégal. 🇧🇷🇸🇳🦁',
        'knockout_tbd': 'Le suspense est insoutenable, même le chatbot ne sait pas qui va jouer ! 🤖🔮',
      },
      'teams': {
        'mx': 'Mexique', 'de': 'Allemagne', 'us': 'États-Unis', 'en': 'Angleterre',
        'ca': 'Canada', 'jp': 'Japon', 'fr': 'France', 'br': 'Brésil',
        'sn': 'Sénégal', 'ar': 'Argentine', 'ma': 'Maroc', 'es': 'Espagne',
        'it': 'Italie', 'pt': 'Portugal', 'nl': 'Pays-Bas', 'be': 'Belgique',
        'hr': 'Croatie', 'uy': 'Uruguay', 'co': 'Colombie', 'kr': 'Corée du Sud', 'cm': 'Cameroun',
        'ng': 'Nigéria', 'se': 'Suède', 'ch': 'Suisse', 'dk': 'Danemark', 'pl': 'Pologne',
        'ua': 'Ukraine', 'dz': 'Algérie', 'eg': 'Égypte', 'tn': 'Tunisie', 'gh': 'Ghana',
        'ci': 'Côte d\'Ivoire', 'cl': 'Chili', 'pe': 'Pérou', 'ec': 'Équateur', 've': 'Venezuela',
        'au': 'Australie', 'nz': 'Nouvelle-Zélande', 'sa': 'Arabie Saoudite', 'ir': 'Iran',
        'tr': 'Turquie', 'gr': 'Grèce', 'cz': 'République Tchèque', 'at': 'Autriche',
        'ro': 'Roumanie', 'hu': 'Hongrie', 'bg': 'Bulgarie', 'rs': 'Serbie',
        '1A': '1er Groupe A', '2B': '2e Groupe B',
        '1C': '1er Groupe C', '2D': '2e Groupe D',
        'w49': 'Vainqueur M49', 'w50': 'Vainqueur M50',
        'w61': 'Vainqueur D1', 'w62': 'Vainqueur D2',
        'tbd': 'À déterminer'
      }
    },
    'en': {
      'appTitle': 'World Cup 2026',
      'allMatches': 'All matches',
      'myAlerts': 'My alerts',
      'group': 'Group',
      'setAlertTitle': 'Set an alert',
      'alert1Day': '1 day before',
      'alert1Hour': '1 hour before',
      'alert30Min': '30 mins before',
      'cancel': 'Cancel',
      'save': 'Save',
      'removeAlert': 'Remove',
      'timezoneInfo': 'Local times',
      'noAlerts': 'No alerts configured yet.',
      'listView': 'List',
      'calendarView': 'Calendar',
      'loading': 'Loading API schedule...',
      'prevWeek': 'Prev week',
      'nextWeek': 'Next week',
      'today': 'Tournament',
      'knockouts': 'Knockout Stage',
      'standings': 'Standings',
      'pos': 'Pos',
      'team': 'Team',
      'played': 'PL',
      'pts': 'Pts',
      'gd': 'GD',
      'wins': 'W',
      'draws': 'D',
      'losses': 'L',
      'goalsFor': 'GF',
      'goalsAgainst': 'GA',
      'scorers': 'Scorers',
      'assists': 'Assists',
      'stats': 'Statistics',
      'possession': 'Possession',
      'shots': 'Shots',
      'shotsOnTarget': 'Shots on target',
      'fouls': 'Fouls committed',
      'yellowCards': 'Yellow cards',
      'redCards': 'Red cards',
      'liveMode': 'Live Mode',
      'simMode': 'Sim Mode',
      'bracket': 'Bracket',
      'simulator': 'Simulator',
      'r32': 'Round of 32',
      'r16': 'Round of 16',
      'qf': 'Quarter-Finals',
      'sf': 'Semi-Finals',
      'f': 'Final',
      'groupsTab': 'Groups',
      'scorersTab': 'Scorers',
      'assistsTab': 'Assists',
      'teamStatsTab': 'Team Stats',
      'challengeTab': 'Challenge',
      'myPredictions': 'My Pronos',
      'friendGroups': 'Friend Groups',
      'bonusBets': 'Bonus',
      'predictChampion': '2026 Champion',
      'predictScorer': 'Golden Boot Winner',
      'createGroup': 'Create Group',
      'joinGroup': 'Join Group',
      'groupName': 'Group Name',
      'groupCode': 'Group Code',
      'shareInvite': 'Join my prediction group {groupName}! Code: {code}',
      'copyCode': 'Copy Code',
      'copied': 'Copied!',
      'enterCode': 'Paste a group code',
      'enterName': 'Change nickname',
      'totalPoints': 'Points',
      'ranking': 'Rank',
      'pointsSuffix': 'pts',
      'exactPoints': 'Exact (+30 pts)',
      'outcomePoints': 'Outcome (+10 pts)',
      'noPoints': 'Incorrect (0 pts)',
      'predictButton': 'Save Prediction',
      'selectWinner': 'Select Winner',
      'goalsScored': 'Goals Scored',
      'goalsConceded': 'Goals Conceded',
      'matchesPlayed': 'Matches Played',
      'squadStats': 'Squad Statistics',
      // ── Gamification ───────────────────────────────────────────────────────
      'rankRookie':        'Rookie 🥉',
      'rankTacticianPro': 'Tactician Pro 🥈',
      'rankMasterAnalyst':'Master Analyst 🥇',
      'rankSpecialOne':   'The Special One 👑',
      'favTeamLabel':     'Fav Team:',
      'chooseTeam':       'Choose',
      'boosterLabel':     'Double Points (Booster)',
      'boosterActive':    'BOOSTER ACTIVATED (Score Doubled!)',
      'leaderboardError': 'Error loading leaderboard',
      'noUsers':          'No users yet',
      'pseudoUpdated':    'Nickname updated!',
      'teamUpdated':      'Supported team updated & alerts activated!',
      'championSaved':    'Champion saved!',
      'scorerSaved':      'Golden Boot saved!',
      'groupCreated':     'Group created!',
      'groupJoined':      'Group joined successfully!',
      'groupJoinFailed':  'Invalid code or group already joined',
      'groupStage':       'Group Stage',
      'knockoutStage':    'Knockout Stage',
      'youSuffix':        ' (You)',
      // ── Match detail sheet ────────────────────────────────────────────────
      'crowdPredictions': 'CROWD PREDICTIONS',
      'drawLabel':        'Draw',
      'triviaTitle':      'Humor & Trivia',
      'alertReminderSet': 'Reminder set for {t1} vs {t2}!',
      'dbResetSuccess':   'Database reset to defaults successfully.',
      'resetTournament':  'Reset Tournament',
      'groupStageFilter': 'Group Stage',
      'knockoutFilter':   'Knockout Stage',
      'predGroupStage':   'Group Stage',
      'predKnockout':     'Knockout Stage',
      'jokes': {
        'default': 'A match that promises to be spectacular! Grab your popcorn. 🍿⚽',
        'mx_de': 'Watch out for seismic activity in Mexico! Remember 2018... 🇲🇽⚡🇩🇪',
        'us_en': 'The classic debate over the word "Soccer". Who is right? 🇺🇸⚽🇬🇧',
        'ca_jp': 'Maple syrup versus precision mechanical sushi. 🍁🍣',
        'fr_br': 'The ghosts of 1998 and 2006 still linger... A legendary clash! 🇫🇷🇧🇷✨',
        'sn_ar': 'The rhythm of Dakar against the tango of Buenos Aires. 🇸🇳🕺🇦🇷',
        'ma_es': 'A rematch of 2022... Watch out for penalty shootouts! 🇲🇦🧤🇪🇸',
        'it_pt': 'Two European giants hungry for glory clash head-to-one. 🇮🇹🇵🇹⚽',
        'nl_be': 'The Low Countries derby. Who makes the best fries? 🍟🇧🇪🇳🇱',
        'hr_uy': 'La Celeste\'s grinta versus the Croatian fighting spirit. 🇺🇾🇭🇷💪',
        'jp_fr': 'High-flying match. Can the Bleus resist the Samurai discipline? 🇯🇵🇫🇷',
        'br_sn': 'Brazil\'s Joga Bonito meets Senegal\'s physical power. 🇧🇷🇸🇳🦁',
        'knockout_tbd': 'The suspense is unbearable, even the AI chatbot doesn\'t know who will win! 🤖🔮',
      },
      'teams': {
        'mx': 'Mexico', 'de': 'Germany', 'us': 'United States', 'en': 'England',
        'ca': 'Canada', 'jp': 'Japan', 'fr': 'France', 'br': 'Brazil',
        'sn': 'Senegal', 'ar': 'Argentina', 'ma': 'Morocco', 'es': 'Spain',
        'it': 'Italy', 'pt': 'Portugal', 'nl': 'Netherlands', 'be': 'Belgium',
        'hr': 'Croatia', 'uy': 'Uruguay', 'co': 'Colombia', 'kr': 'South Korea', 'cm': 'Cameroon',
        'ng': 'Nigeria', 'se': 'Sweden', 'ch': 'Switzerland', 'dk': 'Denmark', 'pl': 'Poland',
        'ua': 'Ukraine', 'dz': 'Algeria', 'eg': 'Egypt', 'tn': 'Tunisia', 'gh': 'Ghana',
        'ci': 'Ivory Coast', 'cl': 'Chile', 'pe': 'Peru', 'ec': 'Ecuador', 've': 'Venezuela',
        'au': 'Australia', 'nz': 'New Zealand', 'sa': 'Saudi Arabia', 'ir': 'Iran',
        'tr': 'Turkey', 'gr': 'Greece', 'cz': 'Czechia', 'at': 'Austria',
        'ro': 'Romania', 'hu': 'Hungary', 'bg': 'Bulgaria', 'rs': 'Serbia',
        '1A': 'Winner Group A', '2B': 'Runner-up Group B',
        '1C': 'Winner Group C', '2D': 'Runner-up Group D',
        'w49': 'Winner M49', 'w50': 'Winner M50',
        'w61': 'Winner SF1', 'w62': 'Winner SF2',
        'tbd': 'TBD'
      }
    },
    'es': {
      'appTitle': 'Mundial 2026',
      'allMatches': 'Todos los partidos',
      'myAlerts': 'Mis alertas',
      'group': 'Grupo',
      'setAlertTitle': 'Configurar alerta',
      'alert1Day': '1 día antes',
      'alert1Hour': '1 hora antes',
      'alert30Min': '30 min antes',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'removeAlert': 'Eliminar',
      'timezoneInfo': 'Horas locales',
      'noAlerts': 'Aún no hay alertas configuradas.',
      'listView': 'Lista',
      'calendarView': 'Calendario',
      'loading': 'Cargando calendario API...',
      'prevWeek': 'Semana ant.',
      'nextWeek': 'Semana sig.',
      'today': 'Torneo',
      'knockouts': 'Fase Final',
      'standings': 'Clasificación',
      'pos': 'Pos',
      'team': 'Equipo',
      'played': 'PJ',
      'pts': 'Pts',
      'gd': 'DG',
      'wins': 'PG',
      'draws': 'PE',
      'losses': 'PP',
      'goalsFor': 'GF',
      'goalsAgainst': 'GC',
      'scorers': 'Goleadores',
      'assists': 'Asistentes',
      'stats': 'Estadísticas',
      'possession': 'Posesión',
      'shots': 'Remates',
      'shotsOnTarget': 'Remates al arco',
      'fouls': 'Faltas cometidas',
      'yellowCards': 'Tarjetas amarillas',
      'redCards': 'Tarjetas rojas',
      'liveMode': 'Modo Live',
      'simMode': 'Modo Simulado',
      'bracket': 'Cuadro',
      'simulator': 'Simulador',
      'r32': 'Dieciseisavos',
      'r16': 'Octavos de final',
      'qf': 'Cuartos',
      'sf': 'Semifinales',
      'f': 'Final',
      'groupsTab': 'Grupos',
      'scorersTab': 'Goleadores',
      'assistsTab': 'Asistentes',
      'teamStatsTab': 'Stats Equipo',
      'challengeTab': 'Desafío',
      'myPredictions': 'Mis Pronos',
      'friendGroups': 'Grupos de Amigos',
      'bonusBets': 'Bonos',
      'predictChampion': 'Campeón 2026',
      'predictScorer': 'Bota de Oro',
      'createGroup': 'Crear Grupo',
      'joinGroup': 'Unirse a Grupo',
      'groupName': 'Nombre del Grupo',
      'groupCode': 'Código del Grupo',
      'shareInvite': '¡Únete a mi grupo de pronos {groupName}! Código: {code}',
      'copyCode': 'Copiar Código',
      'copied': '¡Copiado!',
      'enterCode': 'Pegar un código de grupo',
      'enterName': 'Cambiar apodo',
      'totalPoints': 'Puntos',
      'ranking': 'Rango',
      'pointsSuffix': 'pts',
      'exactPoints': 'Exacto (+30 pts)',
      'outcomePoints': 'Resultado (+10 pts)',
      'noPoints': 'Incorrecto (0 pts)',
      'predictButton': 'Guardar Pronóstico',
      'selectWinner': 'Seleccionar Ganador',
      'goalsScored': 'Goles Marcados',
      'goalsConceded': 'Goles Concedidos',
      'matchesPlayed': 'Partidos Jugados',
      'squadStats': 'Stats de Plantilla',
      // ── Gamification ───────────────────────────────────────────────────────
      'rankRookie':        'Rookie 🥉',
      'rankTacticianPro': 'Táctico Pro 🥈',
      'rankMasterAnalyst':'Analista Maestro 🥇',
      'rankSpecialOne':   'The Special One 👑',
      'favTeamLabel':     'Mi equipo:',
      'chooseTeam':       'Elegir',
      'boosterLabel':     'Puntos Dobles (Joker)',
      'boosterActive':    'JOKER ACTIVADO (¡Puntuación doblada!)',
      'leaderboardError': 'Error al cargar la clasificación',
      'noUsers':          'Sin usuarios aún',
      'pseudoUpdated':    '¡Apodo actualizado!',
      'teamUpdated':      '¡Equipo actualizado y alertas activadas!',
      'championSaved':    '¡Campeón guardado!',
      'scorerSaved':      '¡Bota de Oro guardada!',
      'groupCreated':     '¡Grupo creado!',
      'groupJoined':      '¡Grupo unido con éxito!',
      'groupJoinFailed':  'Código inválido o grupo ya unido',
      'groupStage':       'Fase de Grupos',
      'knockoutStage':    'Fase Final',
      'youSuffix':        ' (Tú)',
      // ── Match detail sheet ────────────────────────────────────────────────
      'crowdPredictions': 'PRONÓSTICOS DEL PÚBLICO',
      'drawLabel':        'Empate',
      'triviaTitle':      'Humor y Anécdotas',
      'alertReminderSet': '¡Recordatorio configurado para {t1} vs {t2}!',
      'dbResetSuccess':   'Base de datos restablecida correctamente.',
      'resetTournament':  'Reiniciar torneo',
      'groupStageFilter': 'Fase de Grupos',
      'knockoutFilter':   'Fase Final',
      'predGroupStage':   'Fase de Grupos',
      'predKnockout':     'Fase Final',
      'jokes': {
        'default': '¡Un partido que promete ser espectacular! Prepara las palomitas. 🍿⚽',
        'mx_de': '¡Cuidado con la actividad sísmica en CDMX! Recuerden el 2018... 🇲🇽⚡🇩🇪',
        'us_en': 'El histórico debate sobre la palabra "Soccer". ¿Quién tiene razón? 🇺🇸⚽🇬🇧',
        'ca_jp': 'Jarabe de arce contra sushi de alta precisión. 🍁🍣',
        'fr_br': 'Las sombras de 1998 y 2006 siguen rondando... ¡Duelo legendario! 🇫🇷🇧🇷✨',
        'sn_ar': 'El ritmo de Dakar contra el tango de Buenos Aires. 🇸🇳🕺🇦🇷',
        'ma_es': 'Reminiscencias de 2022... ¡Mucho ojo con la tanda de penaltis! 🇲🇦🧤🇪🇸',
        'it_pt': 'Choque de titanes europeos con mucha hambre de victoria. 🇮🇹🇵🇹⚽',
        'nl_be': 'El derbi de los Países Bajos. ¿Quién se lleva la mejor patata frita? 🍟🇧🇪🇳🇱',
        'hr_uy': 'La garra charrúa contra el indomable espíritu croata. 🇺🇾🇭🇷💪',
        'jp_fr': 'Partidazo. ¿Podrán los Bleus contra la disciplina de los Samuráis? 🇯🇵🇫🇷',
        'br_sn': 'El Joga Bonito de Brasil frente al poderío físico de Senegal. 🇧🇷🇸🇳🦁',
        'knockout_tbd': '¡El suspenso es insoportable, ni siquiera la IA sabe quién jugará! 🤖🔮',
      },
      'teams': {
        'mx': 'México', 'de': 'Alemania', 'us': 'Estados Unidos', 'en': 'Inglaterra',
        'ca': 'Canadá', 'jp': 'Japón', 'fr': 'Francia', 'br': 'Brasil',
        'sn': 'Senegal', 'ar': 'Argentina', 'ma': 'Marruecos', 'es': 'España',
        'it': 'Italia', 'pt': 'Portugal', 'nl': 'Países Bajos', 'be': 'Bélgica',
        'hr': 'Croacia', 'uy': 'Uruguay', 'co': 'Colombia', 'kr': 'Corea del Sur', 'cm': 'Cameroun',
        'ng': 'Nigeria', 'se': 'Suecia', 'ch': 'Suiza', 'dk': 'Dinamarca', 'pl': 'Polonia',
        'ua': 'Ucrania', 'dz': 'Argelia', 'eg': 'Egipto', 'tn': 'Túnez', 'gh': 'Ghana',
        'ci': 'Costa de Marfil', 'cl': 'Chile', 'pe': 'Perú', 'ec': 'Ecuador', 've': 'Venezuela',
        'au': 'Australia', 'nz': 'Nueva Zelanda', 'sa': 'Arabia Saudita', 'ir': 'Irán',
        'tr': 'Turquía', 'gr': 'Grecia', 'cz': 'República Checa', 'at': 'Austria',
        'ro': 'Rumanía', 'hu': 'Hungría', 'bg': 'Bulgaria', 'rs': 'Serbia',
        '1A': '1ro Grupo A', '2B': '2do Grupo B',
        '1C': '1ro Grupo C', '2D': '2do Grupo D',
        'w49': 'Ganador M49', 'w50': 'Ganador M50',
        'w61': 'Ganador SF1', 'w62': 'Ganador SF2',
        'tbd': 'Por definir'
      }
    }
  };

  static String get(String lang, String key) {
    return _data[lang]?[key] ?? key;
  }

  static String getTeam(String lang, String code) {
    final teamsMap = _data[lang]?['teams'] as Map<String, String>?;
    return teamsMap?[code] ?? code.toUpperCase();
  }

  static String getTeamWithEmblem(String lang, String code) {
    final name = getTeam(lang, code);
    final emblem = _emblems[code.toLowerCase()];
    return emblem != null ? '$emblem $name' : name;
  }

  static String getJoke(String lang, String t1, String t2, {bool isKnockout = false}) {
    final jokesMap = _data[lang]?['jokes'] as Map<String, String>?;
    if (jokesMap == null) return '';

    final key1 = '${t1}_${t2}';
    final key2 = '${t2}_${t1}';
    if (jokesMap.containsKey(key1)) return jokesMap[key1]!;
    if (jokesMap.containsKey(key2)) return jokesMap[key2]!;

    if (isKnockout && (t1 == 'tbd' || t2 == 'tbd' || t1.startsWith('w') || t2.startsWith('w'))) {
      return jokesMap['knockout_tbd'] ?? 'TBD';
    }

    return jokesMap['default'] ?? 'Match scheduled';
  }
}
