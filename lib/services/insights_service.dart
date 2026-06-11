class TeamHistory {
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final List<String> funFacts;

  TeamHistory({
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    this.funFacts = const [],
  });
}

class WCInsightsService {
  static final Map<String, TeamHistory> _data = {
    'br': TeamHistory(
      played: 114, wins: 76, draws: 19, losses: 19, goalsFor: 237, goalsAgainst: 108,
      funFacts: [
        "Le Brésil est la seule nation à avoir participé à toutes les phases finales depuis 1930.",
        "Pelé reste le seul joueur à avoir remporté 3 Coupes du Monde."
      ],
    ),
    'de': TeamHistory(
      played: 112, wins: 68, draws: 21, losses: 23, goalsFor: 232, goalsAgainst: 130,
      funFacts: [
        "L'Allemagne a disputé le record de 8 finales de Coupe du Monde.",
        "Miroslav Klose est le meilleur buteur de l'histoire du tournoi avec 16 réalisations."
      ],
    ),
    'ar': TeamHistory(
      played: 88, wins: 47, draws: 17, losses: 24, goalsFor: 152, goalsAgainst: 101,
      funFacts: [
        "Lionel Messi détient le record du nombre de matchs joués en Coupe du Monde (26).",
        "L'Argentine a remporté sa 3ème étoile lors de l'édition 2022 au Qatar."
      ],
    ),
    'fr': TeamHistory(
      played: 73, wins: 39, draws: 14, losses: 20, goalsFor: 136, goalsAgainst: 85,
      funFacts: [
        "Just Fontaine détient le record de buts sur une seule édition (13 buts en 1958).",
        "La France a atteint la finale lors de 3 des 7 dernières éditions."
      ],
    ),
    'mx': TeamHistory(
      played: 60, wins: 17, draws: 15, losses: 28, goalsFor: 62, goalsAgainst: 101,
      funFacts: [
        "Le Mexique co-organise le tournoi pour la 3ème fois, un record historique.",
        "Guillermo Ochoa pourrait devenir le premier joueur à participer à 6 phases finales."
      ],
    ),
    'us': TeamHistory(
      played: 37, wins: 9, draws: 8, losses: 20, goalsFor: 40, goalsAgainst: 66,
      funFacts: [
        "Les USA ont atteint les demi-finales lors de la toute première édition en 1930.",
        "Christian Pulisic est le plus jeune capitaine de l'histoire de la sélection US."
      ],
    ),
    'ca': TeamHistory(
      played: 6, wins: 0, draws: 0, losses: 6, goalsFor: 2, goalsAgainst: 12,
      funFacts: [
        "Alphonso Davies a marqué le tout premier but du Canada en Coupe du Monde en 2022.",
        "Le Canada organise sa toute première Coupe du Monde masculine en 2026."
      ],
    ),
    'ma': TeamHistory(
      played: 23, wins: 5, draws: 7, losses: 11, goalsFor: 20, goalsAgainst: 27,
      funFacts: [
        "Le Maroc est devenu la première nation africaine à atteindre les demi-finales (2022).",
        "Yassine Bounou a réalisé 3 clean sheets lors de l'épopée historique au Qatar."
      ],
    ),
    'sn': TeamHistory(
      played: 12, wins: 5, draws: 3, losses: 4, goalsFor: 16, goalsAgainst: 16,
      funFacts: [
        "Le Sénégal a atteint les quarts de finale dès sa première participation en 2002.",
        "Sadio Mané reste le symbole de cette génération dorée des Lions de la Teranga."
      ],
    ),
    'cm': TeamHistory(
      played: 26, wins: 5, draws: 8, losses: 13, goalsFor: 22, goalsAgainst: 47,
      funFacts: [
        "Roger Milla est devenu en 1994 le buteur le plus âgé de l'histoire (42 ans).",
        "Le Cameroun fut le premier pays africain en quart de finale (1990)."
      ],
    ),
    'ir': TeamHistory(
      played: 18, wins: 3, draws: 4, losses: 11, goalsFor: 13, goalsAgainst: 31,
      funFacts: [
        "L'Iran a remporté sa première victoire historique contre les USA en 1998.",
        "La sélection est surnommée 'Team Melli'."
      ],
    ),
    'dz': TeamHistory(
      played: 13, wins: 3, draws: 3, losses: 7, goalsFor: 13, goalsAgainst: 19,
      funFacts: [
        "L'Algérie a battu l'Allemagne de l'Ouest lors de son premier match en 1982.",
        "Luca Zidane, fils de Zinedine, fait partie du groupe pour cette édition 2026."
      ],
    ),
    'pt': TeamHistory(
      played: 35, wins: 17, draws: 6, losses: 12, goalsFor: 60, goalsAgainst: 41,
      funFacts: [
        "Cristiano Ronaldo est le seul joueur à avoir marqué dans 5 éditions différentes.",
        "Eusébio reste le meilleur buteur portugais sur un tournoi (9 buts en 1966)."
      ],
    ),
    'es': TeamHistory(
      played: 67, wins: 31, draws: 17, losses: 19, goalsFor: 108, goalsAgainst: 75,
      funFacts: [
        "L'Espagne a remporté sa seule Coupe du Monde en 2010 grâce à Andres Iniesta.",
        "Lamine Yamal est attendu comme l'un des plus jeunes titulaires de l'histoire en 2026."
      ],
    ),
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
}
