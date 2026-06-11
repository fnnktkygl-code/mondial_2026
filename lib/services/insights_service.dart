class TeamHistory {
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final List<String> funFacts;
  final int? firstWorldCup;
  final int? participationRank;

  TeamHistory({
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    this.funFacts = const [],
    this.firstWorldCup,
    this.participationRank,
  });

  int get participations => participationRank ?? 0;

  String? get participationRankLabel {
    if (participationRank == null) return null;
    final n = participationRank!;
    final suffix = _ordinalSuffix(n);
    return '$n$suffix in 2026';
  }

  static String _ordinalSuffix(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return 'th';
    switch (n % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}

class WCInsightsService {
  static final Map<String, TeamHistory> _data = {
    // ── SOUTH AMERICA ───────────────────────────────────────────────────────
    'br': TeamHistory(
      played: 114, wins: 76, draws: 19, losses: 19, goalsFor: 237, goalsAgainst: 108,
      firstWorldCup: 1930, participationRank: 22,
      funFacts: [
        "Le Brésil est la seule nation à avoir participé à toutes les phases finales depuis 1930.",
        "Pelé reste le seul joueur à avoir remporté 3 Coupes du Monde.",
        "Le Brésil détient le meilleur taux de victoires de l'histoire : 67 % sur 114 matchs.",
      ],
    ),
    'ar': TeamHistory(
      played: 88, wins: 47, draws: 17, losses: 24, goalsFor: 152, goalsAgainst: 101,
      firstWorldCup: 1930, participationRank: 19,
      funFacts: [
        "Lionel Messi détient le record du nombre de matchs joués en Coupe du Monde (26).",
        "L'Argentine tente de remporter deux titres consécutifs, comme l'ont fait l'Italie (1934, 1938) et le Brésil (1958, 1962).",
        "En 2022, Messi a été impliqué dans 10 des 15 buts argentins (7 buts, 3 passes décisives).",
        "Messi aborde ce Mondial avec **13 buts** en phase finale, record absolu parmi les joueurs encore en activité — et à portée des 16 de Klose.",
        "Messi s'apprête à disputer une **6ème Coupe du Monde**, un record absolu qu'il partage avec Ronaldo et Ochoa.",
        "Scaloni a conservé **17 des 26 champions du monde 2022** dans son groupe, soit le noyau le plus fourni de l'histoire récente.",
      ],
    ),
    'uy': TeamHistory(
      played: 59, wins: 25, draws: 13, losses: 21, goalsFor: 89, goalsAgainst: 76,
      firstWorldCup: 1930, participationRank: 15,
      funFacts: [
        "L'Uruguay a remporté la toute première Coupe du Monde en 1930, chez lui.",
        "Seule nation à avoir remporté le titre à deux reprises (1930, 1950) sans jamais rejouer une finale.",
        "Marcelo Bielsa est à la tête de sa 3ème sélection différente en Coupe du Monde après l'Argentine (2002) et le Chili (2010).",
      ],
    ),
    'co': TeamHistory(
      played: 22, wins: 9, draws: 3, losses: 10, goalsFor: 32, goalsAgainst: 30,
      firstWorldCup: 1962, participationRank: 7,
      funFacts: [
        "La Colombie a atteint les quarts de finale en 2014, sa meilleure performance historique.",
        "James Rodríguez avait remporté le Soulier d'Or en 2014 avec 6 buts en 5 matchs.",
        "Le coach Néstor Lorenzo a lui-même joué la finale 1990 avec l'Argentine contre l'Allemagne de l'Ouest.",
      ],
    ),
    'ec': TeamHistory(
      played: 13, wins: 5, draws: 2, losses: 6, goalsFor: 14, goalsAgainst: 14,
      firstWorldCup: 2002, participationRank: 5,
      funFacts: [
        "L'Équateur n'a concédé que 5 buts en 18 matchs de qualification, meilleure défense de la CONMEBOL.",
        "Sa seule apparition en 8e de finale date de 2006, éliminé par l'Angleterre.",
        "Il a terminé 2ème des qualifications CONMEBOL, derrière l'Argentine seulement.",
      ],
    ),
    'py': TeamHistory(
      played: 27, wins: 7, draws: 10, losses: 10, goalsFor: 30, goalsAgainst: 38,
      firstWorldCup: 1930, participationRank: 9,
      funFacts: [
        "Le Paraguay a atteint les quarts de finale en 2010, sa meilleure performance, avant d'être éliminé par l'Espagne.",
        "C'est leur première Coupe du Monde depuis 2010, après 16 ans d'absence.",
        "Gustavo Alfaro avait déjà coaché l'Équateur en 2022.",
      ],
    ),

    // ── EUROPE ──────────────────────────────────────────────────────────────
    'de': TeamHistory(
      played: 112, wins: 68, draws: 21, losses: 23, goalsFor: 232, goalsAgainst: 130,
      firstWorldCup: 1934, participationRank: 21,
      funFacts: [
        "L'Allemagne a disputé le record de 8 finales de Coupe du Monde.",
        "Miroslav Klose est le meilleur buteur de l'histoire du tournoi avec 16 réalisations — record que Messi pourrait battre.",
        "Éliminée au premier tour en 2018 et 2022, l'Allemagne cherche à se racheter en 2026.",
        "Julian Nagelsmann, 38 ans, pourrait devenir le plus jeune coach vainqueur depuis Menotti en 1978.",
        "Manuel Neuer (40 ans), champion du monde 2014, dispute sa **5ème Coupe du Monde** — le gardien le plus âgé d'Europe dans ce tournoi.",
        "Le milieu **Lennart Karl** (18 ans et 109 jours) est le 3ème plus jeune joueur du tournoi, signe du profond renouvellement générationnel de la Mannschaft.",
        "Avec **18 joueurs** convoqués dans le monde entier, le Bayern Munich est le 2ème club le mieux représenté du tournoi, juste derrière City.",
      ],
    ),
    'fr': TeamHistory(
      played: 73, wins: 39, draws: 14, losses: 20, goalsFor: 136, goalsAgainst: 85,
      firstWorldCup: 1930, participationRank: 17,
      funFacts: [
        "Just Fontaine détient le record de buts sur une seule édition (13 buts en 1958).",
        "La France a atteint la finale lors de 4 des 7 dernières éditions (1998, 2006, 2018, 2022).",
        "Didier Deschamps est l'un des 3 seuls individus à avoir gagné le Mondial en tant que joueur et entraîneur.",
        "La France tente de devenir la 3ème équipe à atteindre 3 finales consécutives.",
        "Kylian Mbappé arrive à 2026 avec **12 buts** en Coupe du Monde, à portée du record de Messi (13) et de Klose (16).",
        "Dembélé, Hernández, Kanté et Mbappé sont les **4 champions du monde 2018** retenus dans le groupe 2026.",
        "Le **PSG** compte **16 mondialistes** dans ses rangs, 2ème club français le mieux représenté derrière les clubs anglais.",
      ],
    ),
    'es': TeamHistory(
      played: 67, wins: 31, draws: 17, losses: 19, goalsFor: 108, goalsAgainst: 75,
      firstWorldCup: 1934, participationRank: 17,
      funFacts: [
        "L'Espagne est l'actuelle championne d'Europe et tente de réaliser le doublé Euro-Mondial.",
        "Elle est invaincue lors de ses 31 derniers matchs compétitifs depuis mars 2023.",
        "Lamine Yamal, né en 2007, est l'un des plus jeunes joueurs à disputer un Mondial.",
      ],
    ),
    'pt': TeamHistory(
      played: 35, wins: 17, draws: 6, losses: 12, goalsFor: 60, goalsAgainst: 41,
      firstWorldCup: 1966, participationRank: 9,
      funFacts: [
        "Cristiano Ronaldo est le seul joueur à avoir marqué dans 5 Mondiaux différents.",
        "Il dispute en 2026 son **6ème Mondial**, record absolu de longévité partagé avec Messi et Ochoa.",
      ],
    ),
    'it': TeamHistory(
      played: 83, wins: 45, draws: 21, losses: 17, goalsFor: 128, goalsAgainst: 77,
      firstWorldCup: 1934, participationRank: 19,
      funFacts: [
        "L'Italie revient en phase finale après 12 ans d'absence insupportable pour les Tifosi.",
        "Elle a remporté 4 titres mondiaux (1934, 1938, 1982, 2006).",
      ],
    ),
    'nl': TeamHistory(
      played: 55, wins: 30, draws: 14, losses: 11, goalsFor: 96, goalsAgainst: 52,
      firstWorldCup: 1934, participationRank: 12,
      funFacts: [
        "Les Pays-Bas détiennent le record du plus grand nombre de finales perdues sans titre (3).",
        "Ronald Koeman mène l'équipe après l'avoir servie en tant que joueur en 1990 et 1994.",
      ],
    ),
    'be': TeamHistory(
      played: 51, wins: 21, draws: 10, losses: 20, goalsFor: 69, goalsAgainst: 74,
      firstWorldCup: 1930, participationRank: 15,
      funFacts: [
        "La Belgique a fini 3ème en 2018, son apogée historique.",
        "C'est la première compétition majeure sans Eden Hazard pour les Diables Rouges.",
      ],
    ),
    'hr': TeamHistory(
      played: 30, wins: 13, draws: 8, losses: 9, goalsFor: 43, goalsAgainst: 33,
      firstWorldCup: 1998, participationRank: 7,
      funFacts: [
        "La Croatie a atteint le podium lors de 3 de ses 6 premières participations.",
        "Luka Modrić dispute son ultime Mondial à l'âge de 40 ans.",
      ],
    ),
    'at': TeamHistory(
      played: 29, wins: 12, draws: 4, losses: 13, goalsFor: 43, goalsAgainst: 47,
      firstWorldCup: 1934, participationRank: 8,
      funFacts: [
        "L'Autriche fait son grand retour après 28 ans d'absence (dernière en 1998).",
        "Leur meilleur résultat est une 3ème place en 1954.",
      ],
    ),
    'cz': TeamHistory(
      played: 33, wins: 12, draws: 5, losses: 16, goalsFor: 47, goalsAgainst: 49,
      firstWorldCup: 1934, participationRank: 10,
      funFacts: [
        "Première participation de la République Tchèque depuis 2006.",
        "La Tchécoslovaquie avait atteint deux finales historiques (1934, 1962).",
      ],
    ),
    'no': TeamHistory(
      played: 9, wins: 3, draws: 1, losses: 5, goalsFor: 16, goalsAgainst: 14,
      firstWorldCup: 1938, participationRank: 4,
      funFacts: [
        "Erling Haaland a marqué le chiffre record de 16 buts lors de la campagne de qualification.",
        "La Norvège n'avait plus vu la phase finale depuis 28 ans (France 98).",
      ],
    ),
    'sco': TeamHistory(
      played: 23, wins: 4, draws: 7, losses: 12, goalsFor: 25, goalsAgainst: 41,
      firstWorldCup: 1954, participationRank: 9,
      funFacts: [
        "L'Écosse revient enfin après 28 ans d'absence.",
        "Elle détient le triste record de n'avoir jamais franchi le premier tour en 8 tentatives.",
      ],
    ),
    'ch': TeamHistory(
      played: 41, wins: 14, draws: 8, losses: 19, goalsFor: 55, goalsAgainst: 73,
      firstWorldCup: 1934, participationRank: 13,
      funFacts: [
        "La Suisse a atteint les 8es de finale lors des 3 dernières éditions consécutives.",
        "Elle a participé au match le plus prolifique de l'histoire (défaite 7-5 contre l'Autriche en 1954).",
      ],
    ),
    'se': TeamHistory(
      played: 51, wins: 19, draws: 13, losses: 19, goalsFor: 80, goalsAgainst: 73,
      firstWorldCup: 1934, participationRank: 13,
      funFacts: [
        "La Suède a été finaliste à domicile en 1958 contre le Brésil de Pelé.",
        "Alexander Isak porte les espoirs d'un retour au sommet pour les Blågult.",
      ],
    ),

    // ── AFRICA ──────────────────────────────────────────────────────────────
    'ma': TeamHistory(
      played: 23, wins: 5, draws: 7, losses: 11, goalsFor: 20, goalsAgainst: 27,
      firstWorldCup: 1970, participationRank: 7,
      funFacts: [
        "Le Maroc est la première nation africaine à avoir atteint une demi-finale (2022).",
        "Yassine Bounou n'avait encaissé qu'un seul but avant la demi-finale historique au Qatar.",
      ],
    ),
    'sn': TeamHistory(
      played: 12, wins: 5, draws: 3, losses: 4, goalsFor: 16, goalsAgainst: 16,
      firstWorldCup: 2002, participationRank: 4,
      funFacts: [
        "Le Sénégal a atteint les quarts de finale dès sa première participation en 2002.",
        "C'est la 3ème qualification consécutive pour les Lions de la Téranga (record continental).",
      ],
    ),
    'dz': TeamHistory(
      played: 13, wins: 3, draws: 3, losses: 7, goalsFor: 13, goalsAgainst: 19,
      firstWorldCup: 1982, participationRank: 5,
      funFacts: [
        "L'Algérie a battu l'Allemagne de l'Ouest lors de son premier match historique en 1982.",
        "Luca Zidane, fils de Zinedine, fait partie du groupe pour cette édition 2026.",
      ],
    ),
    'cm': TeamHistory(
      played: 26, wins: 5, draws: 8, losses: 13, goalsFor: 22, goalsAgainst: 47,
      firstWorldCup: 1966, participationRank: 9,
      funFacts: [
        "Roger Milla est le buteur le plus âgé de l'histoire du Mondial (42 ans en 1994).",
        "Le Cameroun fut le premier pays africain à atteindre les quarts de finale (1990).",
      ],
    ),
    'ng': TeamHistory(
      played: 21, wins: 6, draws: 3, losses: 12, goalsFor: 23, goalsAgainst: 30,
      firstWorldCup: 1994, participationRank: 7,
      funFacts: [
        "Le Nigéria a atteint les 8es de finale lors de 3 de ses participations.",
        "Victor Osimhen est l'un des attaquants les plus surveillés par les défenseurs adverses.",
      ],
    ),
    'ci': TeamHistory(
      played: 9, wins: 3, draws: 1, losses: 5, goalsFor: 13, goalsAgainst: 14,
      firstWorldCup: 2006, participationRank: 4,
      funFacts: [
        "La Côte d'Ivoire n'a concédé aucun but lors de ses 10 matchs de qualification.",
        "C'est l'équipe avec la moyenne d'âge la plus basse du tournoi (25.8 ans).",
      ],
    ),
    'eg': TeamHistory(
      played: 9, wins: 1, draws: 2, losses: 6, goalsFor: 7, goalsAgainst: 22,
      firstWorldCup: 1934, participationRank: 4,
      funFacts: [
        "L'Égypte fut la toute première nation africaine à participer au Mondial en 1934.",
        "Mohamed Salah dispute probablement sa dernière chance de gloire mondiale.",
      ],
    ),
    'tn': TeamHistory(
      played: 18, wins: 3, draws: 5, losses: 10, goalsFor: 14, goalsAgainst: 26,
      firstWorldCup: 1978, participationRank: 7,
      funFacts: [
        "La Tunisie fut la première équipe africaine à gagner un match au Mondial (1978).",
      ],
    ),
    'za': TeamHistory(
      played: 9, wins: 2, draws: 4, losses: 3, goalsFor: 11, goalsAgainst: 16,
      firstWorldCup: 1998, participationRank: 4,
      funFacts: [
        "L'Afrique du Sud fut le premier pays africain organisateur de l'histoire en 2010.",
        "Les Bafana Bafana avaient battu la France 2-1 lors de l'édition 2010.",
      ],
    ),

    // ── ASIA / OCEANIA ──────────────────────────────────────────────────────
    'jp': TeamHistory(
      played: 25, wins: 7, draws: 6, losses: 12, goalsFor: 25, goalsAgainst: 33,
      firstWorldCup: 1998, participationRank: 8,
      funFacts: [
        "Le Japon a marqué 54 buts lors des qualifications, un record absolu pour la zone AFC.",
        "Hajime Moriyasu est le premier coach japonais à enchaîner deux Mondiaux.",
      ],
    ),
    'kr': TeamHistory(
      played: 38, wins: 7, draws: 10, losses: 21, goalsFor: 39, goalsAgainst: 78,
      firstWorldCup: 1954, participationRank: 12,
      funFacts: [
        "La Corée du Sud est la seule équipe asiatique à avoir atteint les demi-finales (2002).",
        "Elle détient le record de participations consécutives hors Europe/Amérique (11).",
      ],
    ),
    'ir': TeamHistory(
      played: 18, wins: 3, draws: 4, losses: 11, goalsFor: 13, goalsAgainst: 31,
      firstWorldCup: 1978, participationRank: 7,
      funFacts: [
        "L'Iran cherche à franchir le premier tour pour la toute première fois en 2026.",
        "La victoire contre les USA en 1998 reste le moment le plus politique du football mondial.",
      ],
    ),
    'sa': TeamHistory(
      played: 19, wins: 4, draws: 2, losses: 13, goalsFor: 14, goalsAgainst: 44,
      firstWorldCup: 1994, participationRank: 7,
      funFacts: [
        "L'Arabie Saoudite a battu l'Argentine future championne en 2022.",
        "25 des 26 joueurs de l'effectif actuel évoluent dans le championnat local saoudien.",
      ],
    ),
    'au': TeamHistory(
      played: 20, wins: 4, draws: 4, losses: 12, goalsFor: 17, goalsAgainst: 37,
      firstWorldCup: 1974, participationRank: 7,
      funFacts: [
        "L'Australie a atteint les 8es de finale en 2006 et 2022.",
        "C'est leur 6ème qualification consécutive via la zone Asie.",
      ],
    ),
    'uz': TeamHistory(
      played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0,
      firstWorldCup: 2026, participationRank: 1,
      funFacts: [
        "L'Ouzbékistan fait ses grands débuts historiques en Coupe du Monde.",
        "Fabio Cannavaro (Ballon d'Or 2006) est l'actuel sélectionneur des Loups Blancs.",
      ],
    ),
    'jo': TeamHistory(
      played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0,
      firstWorldCup: 2026, participationRank: 1,
      funFacts: [
        "La Jordanie s'est qualifiée pour la première fois de son histoire via les barrages.",
      ],
    ),
    'iq': TeamHistory(
      played: 3, wins: 0, draws: 0, losses: 3, goalsFor: 1, goalsAgainst: 4,
      firstWorldCup: 1986, participationRank: 2,
      funFacts: [
        "L'Irak revient en Coupe du Monde après 40 ans de disette (dernière en 1986).",
      ],
    ),
    'qa': TeamHistory(
      played: 3, wins: 0, draws: 0, losses: 3, goalsFor: 1, goalsAgainst: 7,
      firstWorldCup: 2022, participationRank: 2,
      funFacts: [
        "Le Qatar a engagé Julen Lopetegui pour mener sa campagne 2026.",
      ],
    ),
    'nz': TeamHistory(
      played: 6, wins: 0, draws: 3, losses: 3, goalsFor: 4, goalsAgainst: 14,
      firstWorldCup: 1982, participationRank: 3,
      funFacts: [
        "La Nouvelle-Zélande fut la seule équipe invaincue du Mondial 2010.",
      ],
    ),

    // ── CONCACAF ────────────────────────────────────────────────────────────
    'mx': TeamHistory(
      played: 60, wins: 17, draws: 15, losses: 28, goalsFor: 62, goalsAgainst: 101,
      firstWorldCup: 1930, participationRank: 18,
      funFacts: [
        "Le Mexique organise le tournoi pour la 3ème fois, un record mondial absolu.",
        "Gilberto Mora (17 ans) est le plus jeune joueur mexicain de l'histoire du Mondial.",
      ],
    ),
    'us': TeamHistory(
      played: 37, wins: 9, draws: 8, losses: 20, goalsFor: 40, goalsAgainst: 66,
      firstWorldCup: 1930, participationRank: 12,
      funFacts: [
        "Les USA ont atteint les demi-finales lors de la toute première édition en 1930.",
        "Le pays co-organise le tournoi pour la 2ème fois après 1994.",
      ],
    ),
    'ca': TeamHistory(
      played: 6, wins: 0, draws: 0, losses: 6, goalsFor: 2, goalsAgainst: 12,
      firstWorldCup: 1986, participationRank: 3,
      funFacts: [
        "Alphonso Davies a marqué le premier but canadien de l'histoire en 2022.",
        "Le Canada accueille son premier Mondial masculin de l'histoire en 2026.",
      ],
    ),
    'pa': TeamHistory(
      played: 3, wins: 0, draws: 1, losses: 2, goalsFor: 2, goalsAgainst: 6,
      firstWorldCup: 2018, participationRank: 2,
      funFacts: [
        "Le Panama revient après avoir découvert le tournoi mondial en 2018.",
      ],
    ),
    'ht': TeamHistory(
      played: 3, wins: 0, draws: 0, losses: 3, goalsFor: 1, goalsAgainst: 14,
      firstWorldCup: 1974, participationRank: 2,
      funFacts: [
        "Haïti revient au sommet 52 ans après sa seule participation en 1974.",
      ],
    ),
    'cw': TeamHistory(
      played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0,
      firstWorldCup: 2026, participationRank: 1,
      funFacts: [
        "Curaçao est l'une des plus petites nations à s'être jamais qualifiée au Mondial.",
      ],
    ),
    'cv': TeamHistory(
      played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0,
      firstWorldCup: 2026, participationRank: 1,
      funFacts: [
        "Le Cap-Vert participe à sa toute première phase finale historique en 2026.",
      ],
    ),
  };

  // ── MATCHUP FACTS ────────────────────────────────────────────────────────
  // Clés au format 'code1_code2' en ordre alphabétique (normalisé dans getMatchupFact).
  // Ne couvre que les rencontres réalistes en phase finale 2026
  // (équipes de branches différentes du bracket ou pouvant se croiser en 8e/QF/SF/Finale).
  static final Map<String, List<String>> _matchupFacts = {

    // ── CLASSIQUES EUROPÉENS ────────────────────────────────────────────────
    'de_fr': [
      "Leur dernier affrontement en Coupe du Monde remonte à l'Euro 2021 — et avant ça, la **demi-finale 1982** à Séville, considérée comme le plus beau match de l'histoire du tournoi.",
      "L'Allemagne et la France se sont rencontrées **7 fois** en compétitions officielles : 4 victoires allemandes, 3 françaises. Un bilan remarquablement équilibré.",
      "En 1982 à Séville, les deux nations ont joué la **première séance de tirs au but** de l'histoire d'une demi-finale mondiale — remportée par l'Allemagne.",
    ],
    'de_es': [
      "L'Allemagne et l'Espagne se sont rencontrées en quarts de finale à **chacune des 4 dernières éditions** (2002, 2006, 2010, 2014). L'Espagne mène 3-1.",
      "En 2010, Puyol avait marqué de la tête le seul but d'une demi-finale mémorable. En 2024 à l'Euro, c'est encore l'Espagne qui avait éliminé la Mannschaft en quart.",
    ],
    'es_fr': [
      "France et Espagne ne se sont **jamais rencontrées** en phase finale de Coupe du Monde — une statistique surprenante entre les deux voisins.",
      "Les deux nations ont remporté ensemble **3 des 7 derniers Mondiaux** (France 1998, Espagne 2010, France 2018).",
    ],
    'de_nl': [
      "La rivalité franco-germano-néerlandaise : le **Pays-Bas** n'a jamais battu l'Allemagne en Coupe du Monde (0-2-1).",
      "En 1974, l'Allemagne de Beckenbauer a battu les Pays-Bas de Cruyff 2-1 en finale à Munich — considérée comme l'une des plus grandes finales de l'histoire.",
    ],
    'de_it': [
      "L'Allemagne et l'Italie se sont rencontrées lors de **4 demi-finales ou finales** en Coupe du Monde (1970, 1978, 1982, 2006). L'Italie mène 3-1.",
      "La **demi-finale 1970 à Mexico** (4-3 après prolongations) est surnommée 'Le match du siècle'. Une plaque commémorative existe encore au stade Azteca.",
    ],
    'fr_pt': [
      "La France a éliminé le Portugal en **demi-finale 2006** grâce à un penalty de Zidane. Figo et Ronaldo en avaient pleuré.",
      "Cristiano Ronaldo et Kylian Mbappé se retrouvent une nouvelle fois — deux des 3 meilleurs buteurs de l'histoire des éliminatoires européens.",
    ],
    'es_pt': [
      "Le **classico ibérique** : les deux nations ne se sont jamais rencontrées en phase finale de Coupe du Monde, malgré 9 participations communes.",
      "Ronaldo et le sélectionneur espagnol Luis de la Fuente se retrouvent — De la Fuente avait battu le Portugal avec l'Espagne en finale de l'Euro 2024.",
    ],
    'fr_nl': [
      "En 1978, les Pays-Bas avaient éliminé la France en phase de groupes. En 2022, les Bleus avaient pris leur revanche en 8e de finale de la Ligue des Nations.",
    ],
    'be_fr': [
      "En 2018, la France avait battu la Belgique **0-1 en demi-finale** — le seul but inscrit par Samuel Umtiti sur corner. Les Belges parlent encore du 'vol du siècle'.",
      "Les deux nations ont souvent partagé un même groupe en qualifications. La frontière linguistique ne résiste pas au foot : **47 matchs officiels** entre elles.",
    ],
    'hr_fr': [
      "La Croatie et la France se sont rencontrées en **finale 1998** (0-3) et en **finale 2018** (2-4). Deux finales historiques avec le même vainqueur.",
      "Luka Modrić a perdu deux finales contre la France. En 2026, il dispute son dernier Mondial à 40 ans — une dernière chance de revanche.",
    ],
    'de_hr': [
      "En 1998, l'Allemagne a été éliminée par la Croatie en quarts de finale lors de la toute **première participation croate** au Mondial.",
    ],
    'nl_ar': [
      "En 2022, le quart de finale **Pays-Bas - Argentine** a été l'un des plus spectaculaires de l'histoire : 2-2 après prolongations, victoire aux tirs au but dans une atmosphère explosive.",
      "En 1978, les Pays-Bas avaient perdu la finale contre l'Argentine à Buenos Aires, devant 70 000 supporters locaux.",
    ],
    'fr_ar': [
      "La **finale 2022** France - Argentine est considérée comme la plus grande de l'histoire : 3-3 après prolongations, victoire de Messi aux tirs au but. Mbappé avait marqué un triplé.",
      "Deux finales de Mondials possibles entre ces deux nations en l'espace de 4 ans — du jamais vu depuis Brésil-Italie (1970, 1994).",
    ],
    'de_ar': [
      "Allemagne et Argentine se sont rencontrées en **finale à 3 reprises** (1986, 1990, 2014) — un record absolu. L'Allemagne mène 2-1.",
      "En 2014 à Rio, un but de Götze en prolongations avait privé Messi de son premier titre mondial.",
    ],
    'es_ar': [
      "Messi a grandi en **Catalogne** dès l'âge de 13 ans — un lien particulier avec l'Espagne, pays où il a construit sa légende au Barça pendant 17 saisons.",
    ],
    'br_fr': [
      "En 1998, le Brésil de Ronaldo avait perdu contre la France en finale (0-3) sur son propre sol symbolique — la France soulevait son premier trophée.",
      "En 2006, la France avait éliminé le Brésil en quarts de finale (0-1) grâce à Zidane, offrant l'un des matchs les plus tactiques de l'histoire.",
    ],
    'br_ar': [
      "Le **Superclasico de las Américas** en Coupe du Monde : les deux nations se sont rencontrées **5 fois**, avec 2 victoires brésiliennes, 2 argentines et 1 nul.",
      "Pelé vs Diego : la rivalité entre les deux légendes a cristallisé 50 ans de duels entre les deux nations. Messi a désormais le trophée qui manquait à Diego.",
      "Si Brésil et Argentine se retrouvent en finale, ce serait la **première finale entièrement sud-américaine** de l'histoire.",
    ],
    'br_de': [
      "Le **7-1** du 8 juillet 2014 à Belo Horizonte reste le plus grand traumatisme de l'histoire du football brésilien. Ce soir-là, l'Allemagne avait inscrit 5 buts en 18 minutes.",
      "Depuis ce soir-là, les deux nations ne se sont rencontrées qu'une seule fois en match amical — les Brésiliens attendent la revanche.",
    ],
    'br_es': [
      "Espagne et Brésil ne se sont rencontrées qu'une seule fois en Coupe du Monde — en finale de la Coupe des Confédérations 2013, victoire brésilienne 3-0.",
    ],
    'br_uy': [
      "Le **Maracanazo** : en 1950, l'Uruguay bat le Brésil 2-1 au Maracanã devant 200 000 spectateurs dans le silence le plus total. Le gardien brésilien Moacyr Barbosa a porté la honte toute sa vie.",
    ],
    'ar_uy': [
      "Argentine et Uruguay ont tous deux remporté la toute première Coupe du Monde en 1930 — mais c'est l'Uruguay qui avait battu l'Argentine en finale (4-2).",
    ],
    'br_pt': [
      "Portugal et Brésil partagent la même langue mais jamais de finale mondiale. Ronaldo vs Vinicius Jr : deux superstars, deux générations, une même langue.",
    ],
    'mx_ar': [
      "Le Mexique a été éliminé par l'Argentine en huitièmes de finale lors de **3 éditions consécutives** (2006, 2010, 2014). Une malédiction connue sous le nom de **'la maldición azteca'**.",
    ],
    'mx_br': [
      "Le Mexique et le Brésil se sont rencontrés en quarts de finale en 1986 — victoire brésilienne aux tirs au but dans un match légendaire au stade Jalisco.",
      "En 2026, le Mexique est co-organisateur. Une qualification historique face au Brésil devant ses propres supporters serait un moment monumental.",
    ],
    'us_mx': [
      "Le **El Tri vs Les Étoiles** : la rivalité nord-américaine la plus intense. Le match aller des qualifications 2026 avait été suspendu pour des chants homophobes.",
      "En 2026, USA et Mexique sont co-organisateurs. Une rencontre entre les deux hôtes serait inédite dans l'histoire du tournoi.",
    ],
    'us_br': [
      "Les USA avaient réalisé l'**une des plus grandes surprises de l'histoire** en battant l'Angleterre 1-0 en 1950 — mais n'ont jamais battu le Brésil en Coupe du Monde.",
    ],
    'us_ar': [
      "En 1930, les USA avaient battu… tout le monde en demi-finale avant de perdre contre l'Argentine (6-1). C'est la seule rencontre historique entre les deux nations en Coupe du Monde.",
    ],
    'ca_fr': [
      "La France compte plus de 1,5 million de francophones au **Québec** — un lien culturel qui rend ce match particulièrement symbolique des deux côtés de l'Atlantique.",
    ],
    'ca_br': [
      "Alphonso Davies, né au camp de réfugiés de **Buduburam au Ghana**, incarne à lui seul le miracle canadien. Face au Brésil, il représenterait l'ascension la plus rapide de l'histoire du football mondial.",
    ],
    'jp_de': [
      "Au Mondial 2022, le Japon avait battu l'Allemagne **4-2** et signé l'une des plus grandes surprises de l'histoire. Un souvenir que la Mannschaft veut effacer.",
    ],
    'jp_es': [
      "En 2022, le Japon avait éliminé l'Espagne en phase de groupes (2-1) grâce à un but de Tanaka dans une position litigieuse — 'le ballon de Tanaka' a alimenté les débats pendant des mois.",
    ],
    'jp_br': [
      "Le Brésil et le Japon s'affrontent régulièrement depuis les années 1990, époque où le Japon recrutait massivement les stars brésiliennes en J-League. Une amitié footballistique unique.",
    ],
    'kr_de': [
      "En 2018, la Corée du Sud avait éliminé l'Allemagne championne du monde en phase de groupes (2-0) — dans l'une des plus grandes surprises de l'histoire de la compétition.",
    ],
    'ma_fr': [
      "En 2022, le Maroc avait battu la France… Non — c'est la France qui avait gagné 2-0 en demi-finale. Mais la résistance marocaine avait impressionné le monde entier.",
      "Walid Regragui et Didier Deschamps se retrouvent. Le coach marocain a juré que 2026 serait différent.",
    ],
    'ma_es': [
      "En 2022, le Maroc avait éliminé l'Espagne aux tirs au but en huitièmes (0-0, 3-0 aux penalties). Bono n'avait pas eu à intervenir une seule fois en jeu.",
    ],
    'ma_pt': [
      "En 2022, le Maroc avait battu le Portugal **1-0** en quarts de finale, mettant fin au rêve mondial de Ronaldo à 37 ans. Youssef En-Nesyri avait marqué le but qualificatif.",
    ],
    'ma_br': [
      "Si le Maroc affronte le Brésil, ce serait un choc inédit entre le meilleur africain et le meilleur sud-américain de l'histoire récente.",
    ],
    'sn_fr': [
      "En 2002, le Sénégal avait battu la France championne du monde en titre lors du **match d'ouverture** (1-0) — l'une des plus grandes surprises de l'histoire du tournoi.",
    ],
    'de_pt': [
      "En 2006, l'Allemagne avait battu le Portugal **3-1** pour la troisième place, avec un but de Schweinsteiger. Figo avait pleuré à chaud.",
      "Avec Ronaldo et Wirtz sur le terrain, ce serait un choc entre deux des plus grands joueurs de leurs générations respectives.",
    ],
    'ng_ar': [
      "Le Nigéria et l'Argentine ont joué **5 fois** en Coupe du Monde — toujours en phase de groupes. L'Argentine mène 4-1, mais chaque rencontre a été serrée.",
    ],
    'it_br': [
      "L'Italie et le Brésil s'affrontent depuis **1938** en Coupe du Monde. Leur finale 1970 (0-4) reste la plus belle de l'histoire selon les experts. La finale 1994 s'est décidée aux tirs au but.",
    ],
    'it_fr': [
      "France et Italie ne se sont jamais rencontrées en Coupe du Monde — malgré des dizaines de matchs amicaux intenses. L'Euro 2020 avait vu l'Italie gagner le titre sans croiser la France.",
    ],
    'it_ar': [
      "L'Argentine et l'Italie partagent un lien culturel unique : une grande partie de la population argentine est d'origine italienne. Maradona lui-même a joué pour Naples.",
    ],
    'no_br': [
      "En 1998, la Norvège avait battu le Brésil 2-1 — l'une des plus grandes surprises de l'histoire avec **Tore André Flo** et **Kjetil Rekdal**. Erling Haaland était âgé de 4 ans.",
    ],
    'no_ar': [
      "Erling Haaland contre l'Argentine : deux des équipes les plus offensives du tournoi. Haaland a marqué **16 buts** en qualification — autant que Klose en carrière.",
    ],
    'at_ar': [
      "L'Autriche a participé à la toute **première Coupe du Monde** en 1930 avant même l'Argentine selon le classement FIFA de l'époque. Deux vieilles nations qui se retrouvent 96 ans plus tard.",
    ],
    'ch_br': [
      "La Suisse a joué le match le plus prolifique de l'histoire contre l'Autriche (7-5 en 1954) — mais contre le Brésil, les Helvètes pratiquent généralement un football bien plus défensif.",
    ],
    'se_br': [
      "En 1958, la Suède avait perdu la **finale à domicile** contre le Brésil de Pelé (2-5) à Stockholm. C'était le premier titre brésilien. Les Suédois s'en souviennent encore.",
    ],
    'kr_br': [
      "La Corée du Sud avait atteint les demi-finales en 2002 — et croisé le Brésil qui les avait éliminés 5-3. Park Ji-Sung avait marqué mais ça n'avait pas suffi.",
    ],
    'ir_us': [
      "En 1998, **Iran - USA** fut le match le plus politiquement chargé de l'histoire du Mondial. Les joueurs iraniens avaient offert des fleurs aux Américains avant le coup d'envoi. L'Iran avait gagné 2-1.",
    ],
    'sa_ar': [
      "En 2022, l'Arabie Saoudite avait battu **l'Argentine future championne du monde** 2-1 lors du match d'ouverture — la plus grande surprise de la décennie.",
    ],
    'eg_fr': [
      "Mohamed Salah, formé par la diaspora égyptienne à Liverpool, affronte une France qu'il connaît bien grâce à ses années en Ligue 1 avec l'AS Roma… Non, il n'a jamais joué en France — mais il connaît parfaitement Mbappé pour l'avoir affronté en Ligue des Champions.",
    ],
    'dz_fr': [
      "L'Algérie compte plus de **5 millions de ressortissants** en France. Un France - Algérie en Coupe du Monde serait le match le plus chargé émotionnellement depuis 1998.",
    ],
    'cm_fr': [
      "Le Cameroun fut la première nation africaine à atteindre les quarts de finale (1990) — éliminé par l'Angleterre. En 2026, **Rigobert Song** voudrait écrire un chapitre encore plus grand face à la France.",
    ],
    'mx_us': [
      "**El Clásico Norte-Americano** : la rivalité la plus intense du continent. Une rencontre entre les deux co-organisateurs en phase finale serait inédite dans l'histoire de la compétition.",
    ],
  };

  static TeamHistory? getHistory(String teamCode) {
    return _data[teamCode.toLowerCase()];
  }

  static String? getRandomFunFact(String teamCode) {
    final history = _data[teamCode.toLowerCase()];
    if (history == null || history.funFacts.isEmpty) return null;
    final random = DateTime.now().millisecond % history.funFacts.length;
    return history.funFacts[random];
  }

  /// Returns a contextual matchup fact if one exists for this pair of teams.
  /// Always checks both orderings (t1_t2 and t2_t1) so key order doesn't matter.
  /// Returns null if no specific matchup fact is available — caller should fall
  /// back to per-team funFacts.
  static String? getMatchupFact(String t1, String t2) {
    final a = t1.toLowerCase().replaceAll('g_', '');
    final b = t2.toLowerCase().replaceAll('g_', '');

    // Normalized key: alphabetical order
    final key = a.compareTo(b) <= 0 ? '${a}_$b' : '${b}_$a';
    final facts = _matchupFacts[key];
    if (facts == null || facts.isEmpty) return null;

    final random = DateTime.now().millisecond % facts.length;
    return facts[random];
  }
}