import 'package:mondial_2026/l10n/translations.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class TeamProfileData {
  final String teamCode;
  final String nickname;
  final String symbol;
  final int appearances;
  final String bestFinish;
  final List<String> trophies;
  final int fifaRanking;
  final String profileUrl;
  final String? mediaUrl;
  final String? imageUrl;

  TeamProfileData({
    required this.teamCode,
    required this.nickname,
    required this.symbol,
    required this.appearances,
    required this.bestFinish,
    required this.trophies,
    required this.fifaRanking,
    required this.profileUrl,
    required this.mediaUrl,
    required this.imageUrl,
  });
}

class WCTeamProfileService {
  static Map<String, Map<String, dynamic>> _mediaMap = {};

  static Future<void> loadMediaMap() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/team_media.json');
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      _mediaMap = decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {}
  }

  static TeamProfileData getProfile(String code, String lang) {
    final lowerCode = code.toLowerCase();
    final cleanCode = lowerCode.replaceAll('g_', '');

    // Fetch nickname using local method
    final nickname = _getNickname(cleanCode, lang);

    // Localized symbol / emblem description
    final symbol = _getSymbol(cleanCode, lang);

    // Historical WC appearances
    final appearances = _getAppearances(cleanCode);

    // Localized Best WC Finish
    final bestFinish = _getBestFinish(cleanCode, lang);

    // Localized Trophy / Palmarès list
    final trophies = _getTrophies(cleanCode, lang);

    final mediaEntry = _mediaMap[cleanCode];
    final profileUrl =
        mediaEntry?['profile_url'] ??
        'https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/$cleanCode-team-profile-history';
    final mediaUrl = mediaEntry?['media_url'];
    final imageUrl = mediaEntry?['image_url'] as String?;

    return TeamProfileData(
      teamCode: cleanCode,
      nickname: nickname.isNotEmpty ? nickname : cleanCode.toUpperCase(),
      symbol: symbol,
      appearances: appearances,
      bestFinish: bestFinish,
      trophies: trophies,
      fifaRanking: getFifaRanking(cleanCode),
      profileUrl: profileUrl,
      mediaUrl: mediaUrl,
      imageUrl: imageUrl,
    );
  }

  static String _getSymbol(String code, String lang) {
    final Map<String, Map<String, String>> symbols = {
      'fr': {
        'fr': 'Le Coq Gaulois',
        'en': 'The Gallic Rooster',
        'es': 'El Gallo Galo',
      },
      'br': {
        'fr': 'La Croix du Sud & La Constellation',
        'en': 'The Southern Cross',
        'es': 'La Cruz del Sur',
      },
      'ar': {
        'fr': 'Le Soleil de Mai',
        'en': 'The Sun of May',
        'es': 'El Sol de Mayo',
      },
      'de': {
        'fr': 'L\'Aigle Fédéral',
        'en': 'The Federal Eagle',
        'es': 'El Águila Federal',
      },
      'it': {
        'fr': 'L\'Écusson de la FIGC',
        'en': 'The FIGC Shield',
        'es': 'El Escudo de la FIGC',
      },
      'es': {
        'fr': 'Le Lion Rampant & Les Colonnes d\'Hercule',
        'en': 'The Rampant Lion',
        'es': 'El León Rampante',
      },
      'en': {
        'fr': 'Les Trois Lions',
        'en': 'The Three Lions',
        'es': 'Los Tres Leones',
      },
      'uy': {
        'fr': 'Le Soleil de Mai & Quatre Étoiles',
        'en': 'The Sun of May & 4 Stars',
        'es': 'El Sol de Mayo y 4 Estrellas',
      },
      'sn': {
        'fr': 'Le Lion & Le Baobab',
        'en': 'The Lion & Baobab',
        'es': 'El León y el Baobab',
      },
      'ma': {
        'fr': 'La Couronne Royale Chérifienne',
        'en': 'The Royal Crown',
        'es': 'La Corona Real',
      },
      'mx': {
        'fr': 'L\'Aigle Aztèque et le Serpent',
        'en': 'The Aztec Eagle & Serpent',
        'es': 'El Águila y la Serpiente',
      },
      'us': {
        'fr': 'L\'Écu aux Étoiles et Rayures',
        'en': 'The Shield with Stars & Stripes',
        'es': 'El Escudo con Barras y Estrellas',
      },
      'ca': {
        'fr': 'La Feuille d\'Érable',
        'en': 'The Maple Leaf',
        'es': 'La Hoja de Maple',
      },
      'jp': {
        'fr': 'Yatagarasu (Le Corbeau à Trois Pattes)',
        'en': 'Yatagarasu (Three-legged Crow)',
        'es': 'Yatagarasu (Cuervo de tres patas)',
      },
      'kr': {
        'fr': 'Le Tigre Blanc de l\'Est',
        'en': 'The White Tiger',
        'es': 'El Tigre Blanco',
      },
      'cm': {
        'fr': 'Le Lion et l\'Étoile Rouge',
        'en': 'The Lion & Red Star',
        'es': 'El León y la Estrella Roja',
      },
      'ng': {
        'fr': 'L\'Aigle Noir de la NFF',
        'en': 'The Eagle',
        'es': 'El Águila',
      },
      'dz': {
        'fr': 'Le Croissant et l\'Étoile',
        'en': 'The Crescent & Star',
        'es': 'La Media Luna y la Estrella',
      },
      'eg': {
        'fr': 'L\'Aigle de Saladin',
        'en': 'The Eagle of Saladin',
        'es': 'El Águila de Saladino',
      },
      'sco': {
        'fr': 'Le Chardon Écossais et les Lions',
        'en': 'The Thistle & Lions',
        'es': 'El Cardo y los Leones',
      },
      'be': {
        'fr': 'Le Couronne et l\'Union Royale',
        'en': 'The Crown & Royal Crest',
        'es': 'La Corona y el Escudo Real',
      },
      'za': {
        'fr': 'Le Protéa Royal',
        'en': 'The King Protea',
        'es': 'La Protea Real',
      },
      'qa': {
        'fr': 'Les Cimeterres Croisés & Le Dhow',
        'en': 'Crossed Scimitars & Dhow',
        'es': 'Cimitarras Cruzadas y Dhow',
      },
      'ch': {
        'fr': 'La Croix Suisse épurée',
        'en': 'The Swiss Cross',
        'es': 'La Cruz Suiza',
      },
      'ht': {
        'fr': 'Le Palmier et les Armes',
        'en': 'The Palm Tree & Arms',
        'es': 'La Palmera y las Armas',
      },
      'au': {
        'fr': 'Le Kangourou et l\'Émeu',
        'en': 'The Kangaroo & Emu',
        'es': 'El Canguro y el Emú',
      },
      'tr': {
        'fr': 'Le Croissant de l\'Étoile Blanche',
        'en': 'The Crescent & Star',
        'es': 'La Media Luna y la Estrella',
      },
      'cw': {
        'fr': 'Le Bonnet Phrygien et le Palmier',
        'en': 'The Phrygian Cap & Palm',
        'es': 'El Gorro Frigio y la Palmera',
      },
      'ci': {
        'fr': 'L\'Éléphant d\'Afrique',
        'en': 'The African Elephant',
        'es': 'El Elefante africano',
      },
      'nl': {
        'fr': 'Le Lion Rampant Couronné',
        'en': 'The Crowned Rampant Lion',
        'es': 'El León Rampante Coronado',
      },
      'se': {
        'fr': 'Les Trois Couronnes de l\'Armorial',
        'en': 'The Three Crowns',
        'es': 'Las Tres Coronas',
      },
      'tn': {
        'fr': 'Le Navire Punique & Le Lion',
        'en': 'The Punic Ship & Lion',
        'es': 'El Barco Púnico y el León',
      },
      'pt': {
        'fr': 'Les Cinq Écussons Quinas',
        'en': 'The Quinas Shields',
        'es': 'Las Quinas',
      },
      'cd': {
        'fr': 'La Tête de Léopard, Lance et Flèche',
        'en': 'The Leopard Head & Spears',
        'es': 'La Cabeza de Leopardo y Lanzas',
      },
      'uz': {
        'fr': 'L\'Oiseau Humo mythologique',
        'en': 'The Khumo Bird',
        'es': 'El Ave Humo',
      },
      'co': {
        'fr': 'Le Condor des Andes',
        'en': 'The Condor of the Andes',
        'es': 'El Cóndor de los Andes',
      },
      'hr': {
        'fr': 'Le Damier Rouge et Blanc (Šahovnica)',
        'en': 'The Red & White Chequy Shield',
        'es': 'El Tablero de Ajedrez',
      },
      'gh': {
        'fr': 'L\'Étoile Noire de la Liberté',
        'en': 'The Black Star',
        'es': 'La Estrella Negra',
      },
      'pa': {
        'fr': 'L\'Aigle Harpie héraldique',
        'en': 'The Harpy Eagle',
        'es': 'El Águila Arpía',
      },
      'no': {
        'fr': 'Le Lion d\'Or à la Hache d\'Argent',
        'en': 'The Golden Lion with Axe',
        'es': 'El León de Oro con Hacha',
      },
      'iq': {
        'fr': 'L\'Aigle de Saladin aux Couleurs Nationales',
        'en': 'The Eagle of Saladin',
        'es': 'El Águila de Saladino',
      },
      'at': {
        'fr': 'L\'Aigle Noir aux Chaînes Brisées',
        'en': 'The Black Eagle',
        'es': 'El Águila Negra',
      },
      'jo': {
        'fr': 'L\'Aigle Royal sur le Globe',
        'en': 'The Royal Eagle on Globe',
        'es': 'El Águila Real sobre el Globo',
      },
      'sa': {
        'fr': 'Le Palmier et les Deux Épées Croisées',
        'en': 'The Palm Tree & Crossed Swords',
        'es': 'La Palmera y Dos Espadas',
      },
      'nz': {
        'fr': 'La Fougère Argentée',
        'en': 'The Silver Fern',
        'es': 'El Helecho Plateado',
      },
      'ir': {
        'fr': 'Le Guépard Asiatique de la FFIRI',
        'en': 'The Asiatic Cheetah',
        'es': 'El Guepardo Asiático',
      },
      'ec': {
        'fr': 'Le Condor des Andes sur les Armes',
        'en': 'The Condor over the Shield',
        'es': 'El Cóndor sobre el Escudo',
      },
      'ba': {
        'fr': 'Fleur de Lys héraldique',
        'en': 'Fleur-de-lis',
        'es': 'Flor de Lis',
      },
      'py': {
        'fr': 'L\'Étoile Jaune entourée de Palme et d\'Olivier',
        'en': 'The Star, Palm & Olive Branch',
        'es': 'La Estrella, Palma y Olivo',
      },
      'pl': {
        'fr': 'L\'Aigle Blanc Couronné',
        'en': 'Le White Eagle Couronné',
        'es': 'El Águila Blanca Coronada',
      },
      'cv': {
        'fr': 'Les Dix Étoiles en Cercle',
        'en': 'The Ten Stars Circle',
        'es': 'Las Diez Estrellas en Círculo',
      },
    };

    final entry = symbols[code];
    if (entry != null) {
      return entry[lang] ?? entry['en'] ?? '';
    }
    return '';
  }

  static String _getNickname(String code, String lang) {
    final Map<String, Map<String, String>> nicknames = {
      'fr': {'fr': 'Les Bleus', 'en': 'Les Bleus', 'es': 'Les Bleus'},
      'br': {
        'fr': 'A Seleção / Auriverde',
        'en': 'The Canarinho',
        'es': 'La Canarinha',
      },
      'ar': {
        'fr': 'La Albiceleste',
        'en': 'La Albiceleste',
        'es': 'La Albiceleste',
      },
      'de': {
        'fr': 'Die Mannschaft',
        'en': 'Die Mannschaft',
        'es': 'Die Mannschaft',
      },
      'it': {'fr': 'Gli Azzurri', 'en': 'Gli Azzurri', 'es': 'Gli Azzurri'},
      'es': {
        'fr': 'La Furia Roja',
        'en': 'La Furia Roja',
        'es': 'La Furia Roja',
      },
      'en': {
        'fr': 'The Three Lions',
        'en': 'The Three Lions',
        'es': 'Los Tres Leones',
      },
      'uy': {'fr': 'La Celeste', 'en': 'La Celeste', 'es': 'La Celeste'},
      'sn': {
        'fr': 'Les Lions de la Téranga',
        'en': 'The Lions of Teranga',
        'es': 'Los Leones de la Teranga',
      },
      'ma': {
        'fr': 'Les Lions de l\'Atlas',
        'en': 'The Atlas Lions',
        'es': 'Los Leones del Atlas',
      },
      'mx': {'fr': 'El Tri', 'en': 'El Tri', 'es': 'El Tri'},
      'us': {
        'fr': 'The Stars & Stripes',
        'en': 'The Stars & Stripes',
        'es': 'The Stars & Stripes',
      },
      'ca': {
        'fr': 'Les Canucks / Les Rouges',
        'en': 'The Les Rouges',
        'es': 'Los Rojos',
      },
      'jp': {
        'fr': 'Les Samouraï Bleus',
        'en': 'The Blue Samurai',
        'es': 'Los Samurái Azules',
      },
      'kr': {
        'fr': 'Les Guerriers Taeguk',
        'en': 'The Taeguk Warriors',
        'es': 'Los Guerreros Taeguk',
      },
      'cm': {
        'fr': 'Le Lion Indomptable',
        'en': 'The Indomitable Lions',
        'es': 'Los Leones Indomables',
      },
      'ng': {
        'fr': 'Les Super Aigles',
        'en': 'The Super Eagles',
        'es': 'Las Súper Águilas',
      },
      'dz': {
        'fr': 'Les Fennecs',
        'en': 'The Desert Foxes',
        'es': 'Los Zorros del Desierto',
      },
      'eg': {'fr': 'Les Pharaons', 'en': 'The Pharaohs', 'es': 'Los Faraones'},
      'sco': {
        'fr': 'La Tartan Army',
        'en': 'The Tartan Army',
        'es': 'La Tartan Army',
      },
      'be': {
        'fr': 'Les Diables Rouges',
        'en': 'The Red Devils',
        'es': 'Los Diablos Rojos',
      },
      'za': {
        'fr': 'Bafana Bafana',
        'en': 'Bafana Bafana',
        'es': 'Bafana Bafana',
      },
      'qa': {'fr': 'Al-Annabi', 'en': 'The Maroons', 'es': 'Al-Annabi'},
      'ch': {'fr': 'La Nati', 'en': 'La Nati', 'es': 'La Nati'},
      'ht': {
        'fr': 'Les Grenadiers',
        'en': 'The Grenadiers',
        'es': 'Los Granaderos',
      },
      'au': {
        'fr': 'Les Socceroos',
        'en': 'The Socceroos',
        'es': 'Los Socceroos',
      },
      'tr': {
        'fr': 'Ay-Yıldızlılar',
        'en': 'The Crescent-Stars',
        'es': 'Ay-Yıldızlılar',
      },
      'cw': {
        'fr': 'La Vague Bleue',
        'en': 'The Blue Wave',
        'es': 'La Ola Azul',
      },
      'ci': {
        'fr': 'Les Éléphants',
        'en': 'The Elephants',
        'es': 'Los Elefantes',
      },
      'nl': {
        'fr': 'Les Oranjes',
        'en': 'Clockwork Orange',
        'es': 'La Naranja Mecánica',
      },
      'se': {
        'fr': 'Blågult',
        'en': 'The Blue and Yellow',
        'es': 'Azul y Amarillo',
      },
      'tn': {
        'fr': 'Les Aigles de Carthage',
        'en': 'The Eagles of Carthage',
        'es': 'Las Águilas de Cartago',
      },
      'pt': {
        'fr': 'A Seleção das Quinas',
        'en': 'The Selection of the Quinas',
        'es': 'La Selección de las Quinas',
      },
      'cd': {'fr': 'Les Léopards', 'en': 'The Leopards', 'es': 'Los Leopardos'},
      'uz': {
        'fr': 'Les Loups Blancs',
        'en': 'The White Wolves',
        'es': 'Los Lobos Blancos',
      },
      'co': {
        'fr': 'Los Cafeteros',
        'en': 'The Coffee Growers',
        'es': 'Los Cafeteros',
      },
      'hr': {
        'fr': 'Les Vatreni',
        'en': 'The Fiery Ones',
        'es': 'Los Ardientes',
      },
      'gh': {
        'fr': 'Les Black Stars',
        'en': 'The Black Stars',
        'es': 'Las Estrellas Negras',
      },
      'pa': {
        'fr': 'Los Canaleros',
        'en': 'The Canal Men',
        'es': 'Los Canaleros',
      },
      'no': {'fr': 'Løvene', 'en': 'The Lions', 'es': 'Los Leones'},
      'iq': {
        'fr': 'Les Lions de Mésopotamie',
        'en': 'The Lions of Mesopotamia',
        'es': 'Los Leones de Mesopotamia',
      },
      'at': {'fr': 'Das Team', 'en': 'Das Team', 'es': 'Das Team'},
      'jo': {
        'fr': 'Al-Nashama',
        'en': 'The Valiant Knights',
        'es': 'Al-Nashama',
      },
      'sa': {
        'fr': 'Les Faucons Verts',
        'en': 'The Green Falcons',
        'es': 'Los Halcones Verdes',
      },
      'nz': {
        'fr': 'The All Whites',
        'en': 'The All Whites',
        'es': 'The All Whites',
      },
      'ir': {'fr': 'Team Melli', 'en': 'Team Melli', 'es': 'Team Melli'},
      'ec': {'fr': 'La Tri', 'en': 'La Tri', 'es': 'La Tri'},
      'ba': {'fr': 'Zmajevi', 'en': 'The Dragons', 'es': 'Los Dragones'},
      'py': {'fr': 'La Albirroja', 'en': 'La Albirroja', 'es': 'La Albirroja'},
      'pl': {
        'fr': 'Biało-Czerwoni',
        'en': 'The White and Red',
        'es': 'Blancos y Rojos',
      },
      'cv': {
        'fr': 'Les Requins Bleus',
        'en': 'The Blue Sharks',
        'es': 'Los Tiburones Azules',
      },
    };

    final entry = nicknames[code];
    if (entry != null) {
      return entry[lang] ?? entry['en'] ?? '';
    }
    return '';
  }

  static int _getAppearances(String code) {
    final Map<String, int> apps = {
      'br': 22,
      'de': 20,
      'ar': 18,
      'it': 18,
      'mx': 17,
      'fr': 16,
      'gb': 16,
      'es': 16,
      'uy': 14,
      'be': 14,
      'se': 12,
      'ch': 12,
      'rs': 12,
      'us': 11,
      'nl': 11,
      'kr': 11,
      'pl': 9,
      'cl': 9,
      'pe': 9,
      'hu': 9,
      'cz': 9,
      'cm': 8,
      'pt': 8,
      'sco': 8,
      'py': 8,
      'au': 6,
      'sa': 6,
      'ir': 6,
      'ma': 6,
      'co': 6,
      'ng': 6,
      'dk': 6,
      'ro': 6,
      'bg': 7,
      'at': 7,
      'tn': 6,
      'dz': 4,
      'gh': 4,
      'ci': 3,
      'eg': 3,
      'sn': 3,
      'za': 3,
      'nz': 2,
      'pa': 1,
      'ba': 1,
      'cd': 1,
      'ht': 1,
      'iq': 1,
      'qa': 1,
      'ua': 1,
      'cw': 0,
      'cv': 0,
      'jo': 0,
      'uz': 0,
      've': 0,
    };
    return apps[code] ?? 0;
  }

  static String _getBestFinish(String code, String lang) {
    final Map<String, Map<String, String>> finishes = {
      'br': {
        'fr': 'Vainqueur (1958, 1962, 1970, 1994, 2002)',
        'en': 'Winner (1958, 1962, 1970, 1994, 2002)',
        'es': 'Campeón (1958, 1962, 1970, 1994, 2002)',
      },
      'de': {
        'fr': 'Vainqueur (1954, 1974, 1990, 2014)',
        'en': 'Winner (1954, 1974, 1990, 2014)',
        'es': 'Campeón (1954, 1974, 1990, 2014)',
      },
      'it': {
        'fr': 'Vainqueur (1934, 1938, 1982, 2006)',
        'en': 'Winner (1934, 1938, 1982, 2006)',
        'es': 'Campeón (1934, 1938, 1982, 2006)',
      },
      'ar': {
        'fr': 'Vainqueur (1978, 1986, 2022)',
        'en': 'Winner (1978, 1986, 2022)',
        'es': 'Campeón (1978, 1986, 2022)',
      },
      'fr': {
        'fr': 'Vainqueur (1998, 2018)',
        'en': 'Winner (1998, 2018)',
        'es': 'Campeón (1998, 2018)',
      },
      'uy': {
        'fr': 'Vainqueur (1930, 1950)',
        'en': 'Winner (1930, 1950)',
        'es': 'Campeón (1930, 1950)',
      },
      'en': {
        'fr': 'Vainqueur (1966)',
        'en': 'Winner (1966)',
        'es': 'Campeón (1966)',
      },
      'es': {
        'fr': 'Vainqueur (2010)',
        'en': 'Winner (2010)',
        'es': 'Campeón (2010)',
      },
      'nl': {
        'fr': 'Finaliste (1974, 1978, 2010)',
        'en': 'Runner-up (1974, 1978, 2010)',
        'es': 'Subcampeón (1974, 1978, 2010)',
      },
      'hu': {
        'fr': 'Finaliste (1938, 1954)',
        'en': 'Runner-up (1938, 1954)',
        'es': 'Subcampeón (1938, 1954)',
      },
      'cz': {
        'fr': 'Finaliste (1934, 1962)',
        'en': 'Runner-up (1934, 1962)',
        'es': 'Subcampeón (1934, 1962)',
      },
      'se': {
        'fr': 'Finaliste (1958)',
        'en': 'Runner-up (1958)',
        'es': 'Subcampeón (1958)',
      },
      'hr': {
        'fr': 'Finaliste (2018)',
        'en': 'Runner-up (2018)',
        'es': 'Subcampeón (2018)',
      },
      'us': {
        'fr': '3e place (1930)',
        'en': '3rd Place (1930)',
        'es': '3er Puesto (1930)',
      },
      'at': {
        'fr': '3e place (1954)',
        'en': '3rd Place (1954)',
        'es': '3er Puesto (1954)',
      },
      'be': {
        'fr': '3e place (2018)',
        'en': '3rd Place (2018)',
        'es': '3er Puesto (2018)',
      },
      'tr': {
        'fr': '3e place (2002)',
        'en': '3rd Place (2002)',
        'es': '3er Puesto (2002)',
      },
      'pl': {
        'fr': '3e place (1974, 1982)',
        'en': '3rd Place (1974, 1982)',
        'es': '3er Puesto (1974, 1982)',
      },
      'cl': {
        'fr': '3e place (1962)',
        'en': '3rd Place (1962)',
        'es': '3er Puesto (1962)',
      },
      'ma': {
        'fr': '4e place (2022)',
        'en': '4th Place (2022)',
        'es': '4to Puesto (2022)',
      },
      'kr': {
        'fr': '4e place (2002)',
        'en': '4th Place (2002)',
        'es': '4to Puesto (2002)',
      },
      'bg': {
        'fr': '4e place (1994)',
        'en': '4th Place (1994)',
        'es': '4to Puesto (1994)',
      },
      'rs': {
        'fr': '4e place (1930, 1962)',
        'en': '4th Place (1930, 1962)',
        'es': '4to Puesto (1930, 1962)',
      },
      'cm': {
        'fr': 'Quart de finale (1990)',
        'en': 'Quarter-final (1990)',
        'es': 'Cuartos de final (1990)',
      },
      'co': {
        'fr': 'Quart de finale (2014)',
        'en': 'Quarter-final (2014)',
        'es': 'Cuartos de final (2014)',
      },
      'sn': {
        'fr': 'Quart de finale (2002)',
        'en': 'Quarter-final (2002)',
        'es': 'Cuartos de final (2002)',
      },
      'gh': {
        'fr': 'Quart de finale (2010)',
        'en': 'Quarter-final (2010)',
        'es': 'Cuartos de final (2010)',
      },
      'ua': {
        'fr': 'Quart de finale (2006)',
        'en': 'Quarter-final (2006)',
        'es': 'Cuartos de final (2006)',
      },
      'pe': {
        'fr': 'Quart de finale (1970)',
        'en': 'Quarter-final (1970)',
        'es': 'Cuartos de final (1970)',
      },
      'ch': {
        'fr': 'Quart de finale (1934, 1938, 1954)',
        'en': 'Quarter-final (1934, 1938, 1954)',
        'es': 'Cuartos de final (1934, 1938, 1954)',
      },
      'ro': {
        'fr': 'Quart de finale (1994)',
        'en': 'Quarter-final (1994)',
        'es': 'Cuartos de final (1994)',
      },
      'dk': {
        'fr': 'Quart de finale (1998)',
        'en': 'Quarter-final (1998)',
        'es': 'Cuartos de final (1998)',
      },
      'py': {
        'fr': 'Quart de finale (2010)',
        'en': 'Quarter-final (2010)',
        'es': 'Cuartos de final (2010)',
      },
      'cu': {
        'fr': 'Premier Tournoi en 2026',
        'en': 'Tournament Debut in 2026',
        'es': 'Debut en el Torneo en 2026',
      },
      'cv': {
        'fr': 'Premier Tournoi en 2026',
        'en': 'Tournament Debut in 2026',
        'es': 'Debut en el Torneo en 2026',
      },
      'jo': {
        'fr': 'Premier Tournoi en 2026',
        'en': 'Tournament Debut in 2026',
        'es': 'Debut en el Torneo en 2026',
      },
      'uz': {
        'fr': 'Premier Tournoi en 2026',
        'en': 'Tournament Debut in 2026',
        'es': 'Debut en el Torneo en 2026',
      },
      've': {
        'fr': 'Premier Tournoi en 2026',
        'en': 'Tournament Debut in 2026',
        'es': 'Debut en el Torneo en 2026',
      },
    };

    final entry = finishes[code];
    if (entry != null) {
      return entry[lang] ?? entry['en'] ?? '';
    }

    return AppTranslations.get(lang, "groupStageFilter");
  }

  static List<String> _getTrophies(String code, String lang) {
    final Map<String, Map<String, List<String>>> trophies = {
      'br': {
        'fr': [
          '5x Coupe du Monde de la FIFA',
          '9x Copa América',
          '4x Coupe des Confédérations',
        ],
        'en': [
          '5x FIFA World Cup',
          '9x Copa América',
          '4x FIFA Confederations Cup',
        ],
        'es': [
          '5x Copa Mundial de la FIFA',
          '9x Copa América',
          '4x Copa de las Confederaciones',
        ],
      },
      'de': {
        'fr': [
          '4x Coupe du Monde de la FIFA',
          '3x Championnat d\'Europe (Euro)',
          '1x Coupe des Confédérations',
        ],
        'en': [
          '4x FIFA World Cup',
          '3x UEFA European Championship',
          '1x FIFA Confederations Cup',
        ],
        'es': [
          '4x Copa Mundial de la FIFA',
          '3x Eurocopa',
          '1x Copa de las Confederaciones',
        ],
      },
      'it': {
        'fr': [
          '4x Coupe du Monde de la FIFA',
          '2x Championnat d\'Europe (Euro)',
          '1x Médaille d\'Or Olympique',
        ],
        'en': [
          '4x FIFA World Cup',
          '2x UEFA European Championship',
          '1x Olympic Gold Medal',
        ],
        'es': [
          '4x Copa Mundial de la FIFA',
          '2x Eurocopa',
          '1x Medalla de Oro Olímpica',
        ],
      },
      'ar': {
        'fr': [
          '3x Coupe du Monde de la FIFA',
          '15x Copa América',
          '1x Coupe des Confédérations',
          '1x Coupe des Champions CONMEBOL-UEFA',
        ],
        'en': [
          '3x FIFA World Cup',
          '15x Copa América',
          '1x FIFA Confederations Cup',
          '1x CONMEBOL-UEFA Cup of Champions',
        ],
        'es': [
          '3x Copa Mundial de la FIFA',
          '15x Copa América',
          '1x Copa de las Confederaciones',
          '1x Copa de Campeones Conmebol-UEFA',
        ],
      },
      'fr': {
        'fr': [
          '2x Coupe du Monde de la FIFA',
          '2x Championnat d\'Europe (Euro)',
          '2x Coupe des Confédérations',
          '1x Ligue des Nations de l\'UEFA',
        ],
        'en': [
          '2x FIFA World Cup',
          '2x UEFA European Championship',
          '2x FIFA Confederations Cup',
          '1x UEFA Nations League',
        ],
        'es': [
          '2x Copa Mundial de la FIFA',
          '2x Eurocopa',
          '2x Copa de las Confederaciones',
          '1x Liga de Naciones de la UEFA',
        ],
      },
      'es': {
        'fr': [
          '1x Coupe du Monde de la FIFA',
          '3x Championnat d\'Europe (Euro)',
          '1x Ligue des Nations de l\'UEFA',
        ],
        'en': [
          '1x FIFA World Cup',
          '3x UEFA European Championship',
          '1x UEFA Nations League',
        ],
        'es': [
          '1x Copa Mundial de la FIFA',
          '3x Eurocopa',
          '1x Liga de Naciones de la UEFA',
        ],
      },
      'en': {
        'fr': ['1x Coupe du Monde de la FIFA'],
        'en': ['1x FIFA World Cup'],
        'es': ['1x Copa Mundial de la FIFA'],
      },
      'uy': {
        'fr': [
          '2x Coupe du Monde de la FIFA',
          '15x Copa América',
          '2x Médaille d\'Or Olympique (titres mondiaux historiques)',
        ],
        'en': [
          '2x FIFA World Cup',
          '15x Copa América',
          '2x Olympic Gold Medals (recognized as historic world titles)',
        ],
        'es': [
          '2x Copa Mundial de la FIFA',
          '15x Copa América',
          '2x Medallas de Oro Olímpicas (títulos mundiales históricos)',
        ],
      },
      'mx': {
        'fr': ['12x Coupe d\'Or de la CONCACAF', '1x Coupe des Confédérations'],
        'en': ['12x CONCACAF Gold Cup', '1x FIFA Confederations Cup'],
        'es': [
          '12x Copa de Oro de la Concacaf',
          '1x Copa de las Confederaciones',
        ],
      },
      'us': {
        'fr': [
          '7x Coupe d\'Or de la CONCACAF',
          '2x Ligue des Nations CONCACAF',
        ],
        'en': ['7x CONCACAF Gold Cup', '2x CONCACAF Nations League'],
        'es': [
          '7x Copa de Oro de la Concacaf',
          '2x Liga de Naciones de la Concacaf',
        ],
      },
      'jp': {
        'fr': ['4x Coupe d\'Asie des Nations'],
        'en': ['4x AFC Asian Cup'],
        'es': ['4x Copa Asiática de la AFC'],
      },
      'kr': {
        'fr': ['2x Coupe d\'Asie des Nations'],
        'en': ['2x AFC Asian Cup'],
        'es': ['2x Copa Asiática de la AFC'],
      },
      'ma': {
        'fr': [
          '1x Coupe d\'Afrique des Nations (1976)',
          '2x Championnat d\'Afrique des Nations (CHAN)',
        ],
        'en': [
          '1x Africa Cup of Nations (1976)',
          '2x African Nations Championship (CHAN)',
        ],
        'es': [
          '1x Copa Africana de Naciones (1976)',
          '2x Campeonato Africano de Naciones',
        ],
      },
      'sn': {
        'fr': [
          '2x Coupe d\'Afrique des Nations (2021, 2025)',
          '2x Championnat d\'Afrique des Nations (CHAN 2022)',
        ],
        'en': [
          '1x Africa Cup of Nations (2021)',
          '1x African Nations Championship (CHAN 2022)',
        ],
        'es': [
          '1x Copa Africana de Naciones (2021)',
          '1x Campeonato Africano de Naciones',
        ],
      },
      'cm': {
        'fr': [
          '5x Coupe d\'Afrique des Nations',
          '1x Médaille d\'Or Olympique (2000)',
        ],
        'en': ['5x Africa Cup of Nations', '1x Olympic Gold Medal (2000)'],
        'es': [
          '5x Copa Africana de Naciones',
          '1x Medalla de Oro Olímpica (2000)',
        ],
      },
      'ng': {
        'fr': [
          '3x Coupe d\'Afrique des Nations',
          '1x Médaille d\'Or Olympique (1996)',
        ],
        'en': ['3x Africa Cup of Nations', '1x Olympic Gold Medal (1996)'],
        'es': [
          '3x Copa Africana de Naciones',
          '1x Medalla de Oro Olímpica (1996)',
        ],
      },
      'dz': {
        'fr': [
          '2x Coupe d\'Afrique des Nations (1990, 2019)',
          '1x Coupe Arabe de la FIFA (2021)',
        ],
        'en': [
          '2x Africa Cup of Nations (1990, 2019)',
          '1x FIFA Arab Cup (2021)',
        ],
        'es': [
          '2x Copa Africana de Naciones (1990, 2019)',
          '1x Copa Árabe de la FIFA (2021)',
        ],
      },
      'ci': {
        'fr': ['3x Coupe d\'Afrique des Nations (1992, 2015, 2023)'],
        'en': ['3x Africa Cup of Nations (1992, 2015, 2023)'],
        'es': ['3x Copa Africana de Naciones (1992, 2015, 2023)'],
      },
      'cl': {
        'fr': ['2x Copa América (2015, 2016)'],
        'en': ['2x Copa América (2015, 2016)'],
        'es': ['2x Copa América (2015, 2016)'],
      },
      'dk': {
        'fr': [
          '1x Championnat d\'Europe (Euro 1992)',
          '1x Coupe des Confédérations (1995)',
        ],
        'en': [
          '1x UEFA European Championship (1992)',
          '1x FIFA Confederations Cup (1995)',
        ],
        'es': ['1x Eurocopa (1992)', '1x Copa de las Confederaciones (1995)'],
      },
      'gr': {
        'fr': ['1x Championnat d\'Europe (Euro 2004)'],
        'en': ['1x UEFA European Championship (2004)'],
        'es': ['1x Eurocopa (2004)'],
      },
    };

    final entry = trophies[code];
    if (entry != null) {
      return entry[lang] ?? entry['en'] ?? [];
    }

    return [];
  }

  static int getFifaRanking(String code) {
    final Map<String, int> rankings = {
      'fr': 1,
      'es': 2,
      'ar': 3,
      'en': 4,
      'pt': 5,
      'br': 6,
      'nl': 7,
      'ma': 8,
      'be': 9,
      'de': 10,
      'hr': 11,
      'it': 12,
      'co': 13,
      'sn': 14,
      'mx': 15,
      'us': 16,
      'uy': 17,
      'jp': 18,
      'ch': 19,
      'dk': 20,
      'ir': 21,
      'kr': 22,
      'ec': 23,
      'tr': 24,
      'at': 25,
      'ng': 26,
      'au': 27,
      'dz': 28,
      'eg': 29,
      'ca': 30,
      'no': 31,
      'ua': 32,
      'pl': 33,
      'pa': 34,
      'ci': 35,
      'py': 38,
      'rs': 39,
      'sco': 40,
      'se': 41,
      'hu': 42,
      'cz': 43,
      'tn': 44,
      'cm': 45,
      'gr': 46,
      'cd': 48,
      've': 49,
      'uz': 50,
      'cl': 52,
      'pe': 54,
      'ro': 55,
      'qa': 56,
      'iq': 59,
      'za': 60,
      'sa': 61,
      'jo': 64,
      'ba': 66,
      'cv': 69,
      'gh': 74,
      'cw': 82,
      'ht': 83,
      'nz': 85,
      'bg': 86,
    };
    return rankings[code] ?? 999;
  }

  static List<String> get allTeams {
    final Map<String, int> rankings = {
      'fr': 1,
      'es': 2,
      'ar': 3,
      'en': 4,
      'pt': 5,
      'br': 6,
      'nl': 7,
      'ma': 8,
      'be': 9,
      'de': 10,
      'hr': 11,
      'it': 12,
      'co': 13,
      'sn': 14,
      'mx': 15,
      'us': 16,
      'uy': 17,
      'jp': 18,
      'ch': 19,
      'dk': 20,
      'ir': 21,
      'kr': 22,
      'ec': 23,
      'tr': 24,
      'at': 25,
      'ng': 26,
      'au': 27,
      'dz': 28,
      'eg': 29,
      'ca': 30,
      'no': 31,
      'ua': 32,
      'pl': 33,
      'pa': 34,
      'ci': 35,
      'py': 38,
      'rs': 39,
      'sco': 40,
      'se': 41,
      'hu': 42,
      'cz': 43,
      'tn': 44,
      'cm': 45,
      'gr': 46,
      'cd': 48,
      've': 49,
      'uz': 50,
      'cl': 52,
      'pe': 54,
      'ro': 55,
      'qa': 56,
      'iq': 59,
      'za': 60,
      'sa': 61,
      'jo': 64,
      'ba': 66,
      'cv': 69,
      'gh': 74,
      'cu': 82,
      'ht': 83,
      'nz': 85,
      'bg': 86,
    };
    final sorted = rankings.keys.toList()
      ..sort((a, b) => rankings[a]!.compareTo(rankings[b]!));
    return sorted;
  }
}
