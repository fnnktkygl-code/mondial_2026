import 'package:mondial_2026/l10n/translations.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'insights_service.dart';

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
  final TeamHistory? worldCupRecord;

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
    this.worldCupRecord,
  });
}

class WCTeamProfileService {
  static Map<String, Map<String, dynamic>> _mediaMap = {};

  // List of 48 Qualified Teams for World Cup 2026
  static const Set<String> qualifiedTeams = {
    'mx', 'de', 'us', 'en', 'ca', 'jp', 'fr', 'br', 'sn', 'ar', 
    'ma', 'es', 'pt', 'nl', 'be', 'hr', 'uy', 'co', 'kr', 'cm', 
    'ng', 'se', 'ch', 'dk', 'pl', 'dz', 'eg', 'tn', 'gh', 'ci', 
    'cl', 'pe', 'ec', 've', 'au', 'nz', 'sa', 'ir', 'tr', 'cz', 
    'at', 'ro', 'ba', 'cd', 'cw', 'cv', 'jo', 'uz', 'iq', 'qa', 'za', 'ht', 'pa'
  };

  static Future<void> loadMediaMap() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/team_media.json');
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      _mediaMap = decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {}
  }

  static TeamProfileData getProfile(String code, String lang) {
    final lowerCode = code.toLowerCase();
    final cleanCode = lowerCode.replaceAll('g_', '');
    final lookupCode = cleanCode == 'gb-sct' ? 'sco' : (cleanCode == 'cu' ? 'cw' : cleanCode);

    // Fetch nickname using local method
    final nickname = _getNickname(lookupCode, lang);

    // Localized symbol / emblem description
    final symbol = _getSymbol(lookupCode, lang);

    // Historical WC appearances
    final appearances = _getAppearances(lookupCode);

    // Localized Best WC Finish
    final bestFinish = _getBestFinish(lookupCode, lang);

    // Localized Trophy / Palmarès list
    final trophies = _getTrophies(lookupCode, lang);

    final mediaEntry = _mediaMap[lookupCode];
    final profileUrl = mediaEntry?['profile_url'] ?? 'https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/$lookupCode-team-profile-history';

    // Correction spécifique pour l'Écosse si le lien par défaut est brisé
    String finalProfileUrl = profileUrl;
    if (lookupCode == 'sco' && mediaEntry == null) {
      finalProfileUrl = 'https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/scotland-team-profile-history';
    }
    final mediaUrl = mediaEntry?['media_url'];
    final imageUrl  = mediaEntry?['image_url'] as String?;

    // World Cup historical record (Played/Wins/Draws/Losses/Goals, appearances)
    final worldCupRecord = WCInsightsService.getHistory(lookupCode);

    return TeamProfileData(
      teamCode: lookupCode,
      nickname: nickname.isNotEmpty ? nickname : lookupCode.toUpperCase(),
      symbol: symbol,
      appearances: appearances,
      bestFinish: bestFinish,
      trophies: trophies,
      fifaRanking: getFifaRanking(lookupCode),
      profileUrl: finalProfileUrl,
      mediaUrl: mediaUrl,
      imageUrl: imageUrl,
      worldCupRecord: worldCupRecord,
    );
  }

  static String _getSymbol(String code, String lang) {
    final Map<String, Map<String, String>> symbols = {
      'fr': {'fr': 'Le Coq Gaulois', 'en': 'The Gallic Rooster', 'es': 'El Gallo Galo'},
      'br': {'fr': 'La Croix du Sud & La Constellation', 'en': 'The Southern Cross', 'es': 'La Cruz del Sur'},
      'ar': {'fr': 'Le Soleil de Mai', 'en': 'The Sun of May', 'es': 'El Sol de Mayo'},
      'de': {'fr': 'L\'Aigle Fédéral', 'en': 'The Federal Eagle', 'es': 'El Águila Federal'},
      'it': {'fr': 'L\'Écusson de la FIGC', 'en': 'The FIGC Shield', 'es': 'El Escudo de la FIGC'},
      'es': {'fr': 'Le Lion Rampant & Les Colonnes d\'Hercule', 'en': 'The Rampant Lion', 'es': 'El León Rampante'},
      'en': {'fr': 'Les Trois Lions', 'en': 'The Three Lions', 'es': 'Los Tres Leones'},
      'uy': {'fr': 'Le Soleil de Mai & Quatre Étoiles', 'en': 'The Sun of May & 4 Stars', 'es': 'El Sol de Mayo y 4 Estrellas'},
      'sn': {'fr': 'Le Lion & Le Baobab', 'en': 'The Lion & Baobab', 'es': 'El León y el Baobab'},
      'ma': {'fr': 'La Couronne Royale Chérifienne', 'en': 'The Royal Crown', 'es': 'La Corona Real'},
      'mx': {'fr': 'L\'Aigle Aztèque et le Serpent', 'en': 'The Aztec Eagle & Serpent', 'es': 'El Águila y la Serpiente'},
      'us': {'fr': 'L\'Écu aux Étoiles et Rayures', 'en': 'The Shield with Stars & Stripes', 'es': 'El Escudo con Barras y Estrellas'},
      'ca': {'fr': 'La Feuille d\'Érable', 'en': 'The Maple Leaf', 'es': 'La Hoja de Maple'},
      'jp': {'fr': 'Yatagarasu (Le Corbeau à Trois Pattes)', 'en': 'Yatagarasu (Three-legged Crow)', 'es': 'Yatagarasu (Cuervo de tres patas)'},
      'kr': {'fr': 'Le Tigre Blanc de l\'Est', 'en': 'The White Tiger', 'es': 'El Tigre Blanco'},
      'cm': {'fr': 'Le Lion et l\'Étoile Rouge', 'en': 'The Lion & Red Star', 'es': 'El León y la Estrella Roja'},
      'ng': {'fr': 'L\'Aigle Noir de la NFF', 'en': 'The Eagle', 'es': 'El Águila'},
      'dz': {'fr': 'Le Croissant et l\'Étoile', 'en': 'The Crescent & Star', 'es': 'La Media Luna y la Estrella'},
      'eg': {'fr': 'L\'Aigle de Saladin', 'en': 'The Eagle of Saladin', 'es': 'El Águila de Saladino'},
      'sco': {'fr': 'Le Chardon Écossais et les Lions', 'en': 'The Thistle & Lions', 'es': 'El Cardo y los Leones'},
      'be': {'fr': 'Le Couronne et l\'Union Royale', 'en': 'The Crown & Royal Crest', 'es': 'La Corona y el Escudo Real'},
      'za': {'fr': 'Le Protéa Royal', 'en': 'The King Protea', 'es': 'La Protea Real'},
      'qa': {'fr': 'Les Cimeterres Croisés & Le Dhow', 'en': 'Crossed Scimitars & Dhow', 'es': 'Cimitarras Cruzadas y Dhow'},
      'ch': {'fr': 'La Croix Suisse épurée', 'en': 'The Swiss Cross', 'es': 'La Cruz Suiza'},
      'ht': {'fr': 'Le Palmier et les Armes', 'en': 'The Palm Tree & Arms', 'es': 'La Palmera y las Armas'},
      'au': {'fr': 'Le Kangourou et l\'Émeu', 'en': 'The Kangaroo & Emu', 'es': 'El Canguro y el Emú'},
      'tr': {'fr': 'Le Croissant de l\'Étoile Blanche', 'en': 'The Crescent & Star', 'es': 'La Media Luna y la Estrella'},
      'cw': {'fr': 'Le Bonnet Phrygien et le Palmier', 'en': 'The Phrygian Cap & Palm', 'es': 'El Gorro Frigio y la Palmera'},
      'ci': {'fr': 'L\'Éléphant d\'Afrique', 'en': 'The African Elephant', 'es': 'El Elefante africano'},
      'nl': {'fr': 'Le Lion Rampant Couronné', 'en': 'The Crowned Rampant Lion', 'es': 'El León Rampante Coronado'},
      'se': {'fr': 'Les Trois Couronnes de l\'Armorial', 'en': 'The Three Crowns', 'es': 'Las Tres Coronas'},
      'tn': {'fr': 'Le Navire Punique & Le Lion', 'en': 'The Punic Ship & Lion', 'es': 'El Barco Púnico y le León'},
      'pt': {'fr': 'Les Cinq Écussons Quinas', 'en': 'The Quinas Shields', 'es': 'Las Quinas'},
      'cd': {'fr': 'La Tête de Léopard, Lance et Flèche', 'en': 'The Leopard Head & Spears', 'es': 'La Cabeza de Leopardo y Lanzas'},
      'uz': {'fr': 'L\'Oiseau Humo mythologique', 'en': 'The Khumo Bird', 'es': 'El Ave Humo'},
      'co': {'fr': 'Le Condor des Andes', 'en': 'The Condor of the Andes', 'es': 'El Cóndor de los Andes'},
      'hr': {'fr': 'Le Damier Rouge et Blanc (Šahovnica)', 'en': 'The Red & White Chequy Shield', 'es': 'El Tablero de Ajedrez'},
      'gh': {'fr': 'L\'Étoile Noire de la Liberté', 'en': 'The Black Star', 'es': 'La Estrella Negra'},
      'pa': {'fr': 'L\'Aigle Harpie héraldique', 'en': 'The Harpy Eagle', 'es': 'El Águila Arpía'},
      'no': {'fr': 'Le Lion d\'Or à la Hache d\'Argent', 'en': 'The Golden Lion with Axe', 'es': 'El León de Oro con Hacha'},
      'iq': {'fr': 'L\'Aigle de Saladin aux Couleurs Nationales', 'en': 'The Eagle of Saladin', 'es': 'El Águila de Saladino'},
      'at': {'fr': 'L\'Aigle Noir aux Chaînes Brisées', 'en': 'The Black Eagle', 'es': 'El Águila Negra'},
      'jo': {'fr': 'L\'Aigle Royal sur le Globe', 'en': 'The Royal Eagle on Globe', 'es': 'El Águila Real sobre el Globo'},
      'sa': {'fr': 'Le Palmier et les Deux Épées Croisées', 'en': 'The Palm Tree & Crossed Swords', 'es': 'La Palmera y Dos Espadas'},
      'nz': {'fr': 'La Fougère Argentée', 'en': 'The Silver Fern', 'es': 'El Helecho Plateado'},
      'ir': {'fr': 'Le Guépard Asiatique de la FFIRI', 'en': 'The Asiatic Cheetah', 'es': 'El Guepardo Asiático'},
      'ec': {'fr': 'Le Condor des Andes sur les Armes', 'en': 'The Condor over the Shield', 'es': 'El Cóndor sobre el Escudo'},
      'ba': {'fr': 'Fleur de Lys héraldique', 'en': 'Fleur-de-lis', 'es': 'Flor de Lis'},
      'py': {'fr': 'L\'Étoile Jaune entourée de Palme et d\'Olivier', 'en': 'The Star, Palm & Olive Branch', 'es': 'La Estrella, Palma y Olivo'},
      'pl': {'fr': 'L\'Aigle Blanc Couronné', 'en': 'L\'Aigle Blanc Couronné', 'es': 'El Águila Blanca Coronada'},
      'cv': {'fr': 'Les Dix Étoiles en Cercle', 'en': 'The Ten Stars Circle', 'es': 'Las Diez Estrellas en Círculo'},
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
      'br': {'fr': 'A Seleção / Auriverde', 'en': 'The Canarinho', 'es': 'La Canarinha'},
      'ar': {'fr': 'La Albiceleste', 'en': 'La Albiceleste', 'es': 'La Albiceleste'},
      'de': {'fr': 'Die Mannschaft', 'en': 'Die Mannschaft', 'es': 'Die Mannschaft'},
      'it': {'fr': 'Gli Azzurri', 'en': 'Gli Azzurri', 'es': 'Gli Azzurri'},
      'es': {'fr': 'La Furia Roja', 'en': 'La Furia Roja', 'es': 'La Furia Roja'},
      'en': {'fr': 'The Three Lions', 'en': 'The Three Lions', 'es': 'Los Tres Leones'},
      'uy': {'fr': 'La Celeste', 'en': 'La Celeste', 'es': 'La Celeste'},
      'sn': {'fr': 'Les Lions de la Téranga', 'en': 'The Lions of Teranga', 'es': 'Los Leones de la Teranga'},
      'ma': {'fr': 'Les Lions de l\'Atlas', 'en': 'The Atlas Lions', 'es': 'Los Leones del Atlas'},
      'mx': {'fr': 'El Tri', 'en': 'El Tri', 'es': 'El Tri'},
      'us': {'fr': 'The Stars & Stripes', 'en': 'The Stars & Stripes', 'es': 'The Stars & Stripes'},
      'ca': {'fr': 'Les Canucks / Les Rouges', 'en': 'The Les Rouges', 'es': 'Los Rojos'},
      'jp': {'fr': 'Les Samouraï Bleus', 'en': 'The Blue Samurai', 'es': 'Los Samurái Azules'},
      'kr': {'fr': 'Les Guerriers Taeguk', 'en': 'The Taeguk Warriors', 'es': 'Los Guerreros Taeguk'},
      'cm': {'fr': 'Le Lion Indomptable', 'en': 'The Indomitable Lions', 'es': 'Los Leones Indomables'},
      'ng': {'fr': 'Les Super Aigles', 'en': 'The Super Eagles', 'es': 'Las Súper Águilas'},
      'dz': {'fr': 'Les Fennecs', 'en': 'The Desert Foxes', 'es': 'Los Zorros del Desierto'},
      'eg': {'fr': 'Les Pharaons', 'en': 'The Pharaohs', 'es': 'Los Faraones'},
      'sco': {'fr': 'La Tartan Army', 'en': 'The Tartan Army', 'es': 'La Tartan Army'},
      'be': {'fr': 'Les Diables Rouges', 'en': 'The Red Devils', 'es': 'Los Diablos Rojos'},
      'za': {'fr': 'Bafana Bafana', 'en': 'Bafana Bafana', 'es': 'Bafana Bafana'},
      'qa': {'fr': 'Al-Annabi', 'en': 'The Maroons', 'es': 'Al-Annabi'},
      'ch': {'fr': 'La Nati', 'en': 'La Nati', 'es': 'La Nati'},
      'ht': {'fr': 'Les Grenadiers', 'en': 'The Grenadiers', 'es': 'Los Granaderos'},
      'au': {'fr': 'Les Socceroos', 'en': 'The Socceroos', 'es': 'Los Socceroos'},
      'tr': {'fr': 'Ay-Yıldızlılar', 'en': 'The Crescent-Stars', 'es': 'Ay-Yıldızlılar'},
      'cw': {'fr': 'La Vague Bleue', 'en': 'The Blue Wave', 'es': 'La Ola Azul'},
      'ci': {'fr': 'Les Éléphants', 'en': 'The Elephants', 'es': 'Los Elefantes'},
      'nl': {'fr': 'Les Oranjes', 'en': 'Clockwork Orange', 'es': 'La Naranja Mecánica'},
      'se': {'fr': 'Blågult', 'en': 'The Blue and Yellow', 'es': 'Azul y Amarillo'},
      'tn': {'fr': 'Les Aigles de Carthage', 'en': 'The Eagles of Carthage', 'es': 'Las Águilas de Cartago'},
      'pt': {'fr': 'A Seleção das Quinas', 'en': 'The Selection of the Quinas', 'es': 'La Selección de las Quinas'},
      'cd': {'fr': 'Les Léopards', 'en': 'The Leopards', 'es': 'Los Leopardos'},
      'uz': {'fr': 'Les Loups Blancs', 'en': 'The White Wolves', 'es': 'Los Lobos Blancos'},
      'co': {'fr': 'Los Cafeteros', 'en': 'The Coffee Growers', 'es': 'Los Cafeteros'},
      'hr': {'fr': 'Les Vatreni', 'en': 'The Fiery Ones', 'es': 'Los Ardientes'},
      'gh': {'fr': 'Les Black Stars', 'en': 'The Black Stars', 'es': 'Las Estrellas Negras'},
      'pa': {'fr': 'Los Canaleros', 'en': 'The Canal Men', 'es': 'Los Canaleros'},
      'no': {'fr': 'Løvene', 'en': 'The Lions', 'es': 'Los Leones'},
      'iq': {'fr': 'Les Lions de Mésopotamie', 'en': 'The Lions of Mesopotamia', 'es': 'Los Leones de Mesopotamia'},
      'at': {'fr': 'Das Team', 'en': 'Das Team', 'es': 'Das Team'},
      'jo': {'fr': 'Al-Nashama', 'en': 'The Valiant Knights', 'es': 'Al-Nashama'},
      'sa': {'fr': 'Les Faucons Verts', 'en': 'The Green Falcons', 'es': 'Los Halcones Verdes'},
      'nz': {'fr': 'The All Whites', 'en': 'The All Whites', 'es': 'The All Whites'},
      'ir': {'fr': 'Team Melli', 'en': 'Team Melli', 'es': 'Team Melli'},
      'ec': {'fr': 'La Tri', 'en': 'La Tri', 'es': 'La Tri'},
      'ba': {'fr': 'Zmajevi', 'en': 'The Dragons', 'es': 'Los Dragones'},
      'py': {'fr': 'La Albirroja', 'en': 'La Albirroja', 'es': 'La Albirroja'},
      'pl': {'fr': 'Biało-Czerwoni', 'en': 'The White and Red', 'es': 'Blancos y Rojos'},
      'cv': {'fr': 'Les Requins Bleus', 'en': 'The Blue Sharks', 'es': 'Los Tiburones Azules'},
    };

    final entry = nicknames[code];
    if (entry != null) {
      return entry[lang] ?? entry['en'] ?? '';
    }
    return '';
  }

  static int _getAppearances(String code) {
    final Map<String, int> apps = {
      'br': 22, 'de': 20, 'ar': 18, 'it': 18, 'mx': 17, 'fr': 16, 'es': 16,
      'uy': 14, 'be': 14, 'se': 12, 'ch': 12, 'us': 11, 'nl': 11, 'kr': 11,
      'pl': 9, 'cz': 9, 'cm': 8, 'pt': 8, 'sco': 8,
      'py': 8, 'au': 6, 'sa': 6, 'ir': 6, 'ma': 6, 'co': 6, 'ng': 6, 'dk': 6,
      'at': 7, 'tn': 6, 'dz': 4, 'gh': 4, 'ci': 3, 'eg': 3, 'sn': 3, 'za': 3,
      'nz': 2, 'pa': 1, 'ba': 1, 'cd': 1, 'ht': 1, 'iq': 1, 'qa': 1,
      'cw': 0, 'cv': 0, 'jo': 0, 'uz': 0, 'no': 3,
    };
    return apps[code] ?? 0;
  }

  static String _getBestFinish(String code, String lang) {
    final Map<String, Map<String, String>> finishes = {
      'br': {'fr': 'Vainqueur (1958, 1962, 1970, 1994, 2002)', 'en': 'Winner (1958, 1962, 1970, 1994, 2002)', 'es': 'Campeón (1958, 1962, 1970, 1994, 2002)'},
      'de': {'fr': 'Vainqueur (1954, 1974, 1990, 2014)', 'en': 'Winner (1954, 1974, 1990, 2014)', 'es': 'Campeón (1954, 1974, 1990, 2014)'},
      'it': {'fr': 'Vainqueur (1934, 1938, 1982, 2006)', 'en': 'Winner (1934, 1938, 1982, 2006)', 'es': 'Campeón (1934, 1938, 1982, 2006)'},
      'ar': {'fr': 'Vainqueur (1978, 1986, 2022)', 'en': 'Winner (1978, 1986, 2022)', 'es': 'Campeón (1978, 1986, 2022)'},
      'fr': {'fr': 'Vainqueur (1998, 2018)', 'en': 'Winner (1998, 2018)', 'es': 'Campeón (1998, 2018)'},
      'uy': {'fr': 'Vainqueur (1930, 1950)', 'en': 'Winner (1930, 1950)', 'es': 'Campeón (1930, 1950)'},
      'en': {'fr': 'Vainqueur (1966)', 'en': 'Winner (1966)', 'es': 'Campeón (1966)'},
      'es': {'fr': 'Vainqueur (2010)', 'en': 'Winner (2010)', 'es': 'Campeón (2010)'},
      'nl': {'fr': 'Finaliste (1974, 1978, 2010)', 'en': 'Runner-up (1974, 1978, 2010)', 'es': 'Subcampeón (1974, 1978, 2010)'},
      'cz': {'fr': 'Finaliste (1934, 1962)', 'en': 'Runner-up (1934, 1962)', 'es': 'Subcampeón (1934, 1962)'},
      'se': {'fr': 'Finaliste (1958)', 'en': 'Runner-up (1958)', 'es': 'Subcampeón (1958)'},
      'hr': {'fr': 'Finaliste (2018)', 'en': 'Runner-up (2018)', 'es': 'Subcampeón (2018)'},
      'us': {'fr': '3e place (1930)', 'en': '3rd Place (1930)', 'es': '3er Puesto (1930)'},
      'at': {'fr': '3e place (1954)', 'en': '3rd Place (1954)', 'es': '3er Puesto (1954)'},
      'be': {'fr': '3e place (2018)', 'en': '3rd Place (2018)', 'es': '3er Puesto (2018)'},
      'tr': {'fr': '3e place (2002)', 'en': '3rd Place (2002)', 'es': '3er Puesto (2002)'},
      'pl': {'fr': '3e place (1974, 1982)', 'en': '3rd Place (1974, 1982)', 'es': '3er Puesto (1974, 1982)'},
      'ma': {'fr': '4e place (2022)', 'en': '4th Place (2022)', 'es': '4to Puesto (2022)'},
      'kr': {'fr': '4e place (2002)', 'en': '4th Place (2002)', 'es': '4to Puesto (2002)'},
      'cm': {'fr': 'Quart de finale (1990)', 'en': 'Quarter-final (1990)', 'es': 'Cuartos de final (1990)'},
      'co': {'fr': 'Quart de finale (2014)', 'en': 'Quarter-final (2014)', 'es': 'Cuartos de final (2014)'},
      'sn': {'fr': 'Quart de finale (2002)', 'en': 'Quarter-final (2002)', 'es': 'Cuartos de final (2002)'},
      'gh': {'fr': 'Quart de finale (2010)', 'en': 'Quarter-final (2010)', 'es': 'Cuartos de final (2010)'},
      'ch': {'fr': 'Quart de finale (1934, 1938, 1954)', 'en': 'Quarter-final (1934, 1938, 1954)', 'es': 'Cuartos de final (1934, 1938, 1954)'},
      'py': {'fr': 'Quart de finale (2010)', 'en': 'Quarter-final (2010)', 'es': 'Cuartos de final (2010)'},
      'cw': {'fr': 'Premier Tournoi en 2026', 'en': 'Tournament Debut in 2026', 'es': 'Debut en el Torneo en 2026'},
      'cv': {'fr': 'Premier Tournoi en 2026', 'en': 'Tournament Debut in 2026', 'es': 'Debut en el Torneo en 2026'},
      'jo': {'fr': 'Premier Tournoi en 2026', 'en': 'Tournament Debut in 2026', 'es': 'Debut en el Torneo en 2026'},
      'uz': {'fr': 'Premier Tournoi en 2026', 'en': 'Tournament Debut in 2026', 'es': 'Debut en el Torneo en 2026'},
      'no': {'fr': 'Huitième de finale (1998)', 'en': 'Round of 16 (1998)', 'es': 'Octavos de final (1998)'},
    };

    final entry = finishes[code];
    if (entry != null) {
      return entry[lang] ?? entry['en'] ?? '';
    }

    return AppTranslations.get(lang, "groupStageFilter");
  }

static List<String> _getTrophies(String code, String lang) {
    final Map<String, Map<String, List<String>>> trophies = {
      'de': {
        'fr': [
          'Coupe du Monde (1954, 1974, 1990, 2014)',
          'Euro (1972, 1980, 1996)',
          'Coupe des Confédérations (2017)',
          'Euro Espoirs U21 (2009, 2017, 2021)',
          'Euro U19 (1981, 2008, 2014)',
          'Euro U17 (1984, 1992, 2009, 2023)',
          'Coupe du Monde U20 (1981)',
          'Coupe du Monde U17 (2023)',
        ],
        'en': [
          'FIFA World Cup (1954, 1974, 1990, 2014)',
          'UEFA European Championship (1972, 1980, 1996)',
          'FIFA Confederations Cup (2017)',
          'UEFA Under-21 Championship (2009, 2017, 2021)',
          'UEFA Under-19 Championship (1981, 2008, 2014)',
          'UEFA Under-17 Championship (1984, 1992, 2009, 2023)',
          'FIFA U-20 World Cup (1981)',
          'FIFA U-17 World Cup (2023)',
        ],
        'es': [
          'Copa Mundial de la FIFA (1954, 1974, 1990, 2014)',
          'Eurocopa (1972, 1980, 1996)',
          'Copa de las Confederaciones (2017)',
          'Eurocopa Sub-21 (2009, 2017, 2021)',
          'Eurocopa Sub-19 (1981, 2008, 2014)',
          'Eurocopa Sub-17 (1984, 1992, 2009, 2023)',
          'Copa Mundial Sub-20 (1981)',
          'Copa Mundial Sub-17 (2023)',
        ],
      },
      'en': {
        'fr': [
          'Coupe du Monde (1966)',
          'Euro Espoirs U21 (1982, 1984, 2023)',
          'Euro U19 (11 titres)',
          'Euro U17 (2010, 2014)',
          'Coupe du Monde U20 (2017)',
          'Coupe du Monde U17 (2017)',
        ],
        'en': [
          'FIFA World Cup (1966)',
          'UEFA Under-21 Championship (1982, 1984, 2023)',
          'UEFA Under-19 Championship (11 titles)',
          'UEFA Under-17 Championship (2010, 2014)',
          'FIFA U-20 World Cup (2017)',
          'FIFA U-17 World Cup (2017)',
        ],
        'es': [
          'Copa Mundial de la FIFA (1966)',
          'Eurocopa Sub-21 (1982, 1984, 2023)',
          'Eurocopa Sub-19 (11 títulos)',
          'Eurocopa Sub-17 (2010, 2014)',
          'Copa Mundial Sub-20 (2017)',
          'Copa Mundial Sub-17 (2017)',
        ],
      },
      'ar': {
        'fr': [
          'Coupe du Monde (1978, 1986, 2022)',
          'Copa América (16 titres)',
          'Coupe des Confédérations (1992)',
          'Finalissima (1993, 2022)',
          'Championnat Panaméricain (1960)',
          'Jeux Olympiques U23 (2004, 2008)',
          'Coupe du Monde U20 (6 titres)',
          'Sudaméricain U20 (5 titres)',
          'Sudaméricain U17 (4 titres)',
        ],
        'en': [
          'FIFA World Cup (1978, 1986, 2022)',
          'Copa América (16 titles)',
          'FIFA Confederations Cup (1992)',
          'Finalissima (1993, 2022)',
          'Panamerican Championship (1960)',
          'Olympic Games U23 (2004, 2008)',
          'FIFA U-20 World Cup (6 titles)',
          'South American Under-20 Championship (5 titles)',
          'South American Under-17 Championship (4 titles)',
        ],
        'es': [
          'Copa Mundial de la FIFA (1978, 1986, 2022)',
          'Copa América (16 títulos)',
          'Copa de las Confederaciones (1992)',
          'Finalissima (1993, 2022)',
          'Campeonato Panamericano (1960)',
          'Juegos Olímpicos U23 (2004, 2008)',
          'Copa Mundial Sub-20 (6 títulos)',
          'Campeonato Sudamericano Sub-20 (5 títulos)',
          'Campeonato Sudamericano Sub-17 (4 títulos)',
        ],
      },
      'dz': {
        'fr': [
          'Coupe d\'Afrique des Nations (1990, 2019)',
          'Coupe Arabe de la FIFA (2021)',
          'Championnat d\'Afrique U20 (1979)',
          'Coupe Arabe U17 (2022)',
        ],
        'en': [
          'Africa Cup of Nations (1990, 2019)',
          'FIFA Arab Cup (2021)',
          'CAF Under-20 Championship (1979)',
          'Arab Under-17 Cup (2022)',
        ],
        'es': [
          'Copa Africana de Naciones (1990, 2019)',
          'Copa Árabe de la FIFA (2021)',
          'Campeonato Africano Sub-20 (1979)',
          'Copa Árabe Sub-17 (2022)',
        ],
      },
      'au': {
        'fr': [
          'Coupe d\'Asie (2015)',
          'Coupe d\'Océanie OFC (1980, 1996, 2000, 2004)',
          'Championnat d\'Asie U19 (2019, 2023)',
          'Championnat d\'Océanie U20 (12 titres)',
          'Championnat d\'Océanie U17 (10 titres)',
        ],
        'en': [
          'AFC Asian Cup (2015)',
          'OFC Nations Cup (1980, 1996, 2000, 2004)',
          'AFC Under-19 Championship (2019, 2023)',
          'OFC Under-20 Championship (12 titles)',
          'OFC Under-17 Championship (10 titles)',
        ],
        'es': [
          'Copa Asiática de la AFC (2015)',
          'Copa de las Naciones de la OFC (1980, 1996, 2000, 2004)',
          'Campeonato Asiático Sub-19 (2019, 2023)',
          'Campeonato Sub-20 de la OFC (12 títulos)',
          'Campeonato Sub-17 de la OFC (10 títulos)',
        ],
      },
      'at': {
        'fr': [
          'Aucun titre majeur en A',
          'Coupe de l\'UEFA Amateur (1931)',
        ],
        'en': [
          'No major senior titles',
          'UEFA Amateur Cup (1931)',
        ],
        'es': [
          'Sin títulos mayores en absoluta',
          'Copa de la UEFA Amateur (1931)',
        ],
      },
      'be': {
        'fr': [
          'Aucun titre majeur en A',
          'Jeux Olympiques (1920)',
          'Euro U19 (1977)',
        ],
        'en': [
          'No major senior titles',
          'Olympic Games (1920)',
          'UEFA Under-19 Championship (1977)',
        ],
        'es': [
          'Sin títulos mayores en absoluta',
          'Juegos Olímpicos (1920)',
          'Eurocopa Sub-19 (1977)',
        ],
      },
      'ba': {
        'fr': [
          'Aucun titre international',
          'Aucun titre international',
        ],
        'en': [
          'No international titles',
          'No international titles',
        ],
        'es': [
          'Sin títulos internacionales',
          'Sin títulos internacionales',
        ],
      },
      'br': {
        'fr': [
          'Coupe du Monde (1958, 1962, 1970, 1994, 2002)',
          'Copa América (9 titres)',
          'Coupe des Confédérations (1997, 2005, 2009, 2013)',
          'Jeux Olympiques U23 (2016, 2020)',
          'Coupe du Monde U20 (5 titres)',
          'Coupe du Monde U17 (4 titres)',
          'Sudaméricain U20 (12 titres)',
          'Sudaméricain U17 (13 titres)',
        ],
        'en': [
          'FIFA World Cup (1958, 1962, 1970, 1994, 2002)',
          'Copa América (9 titles)',
          'FIFA Confederations Cup (1997, 2005, 2009, 2013)',
          'Olympic Games U23 (2016, 2020)',
          'FIFA U-20 World Cup (5 titles)',
          'FIFA U-17 World Cup (4 titles)',
          'South American Under-20 Championship (12 titles)',
          'South American Under-17 Championship (13 titles)',
        ],
        'es': [
          'Copa Mundial de la FIFA (1958, 1962, 1970, 1994, 2002)',
          'Copa América (9 títulos)',
          'Copa de las Confederaciones (1997, 2005, 2009, 2013)',
          'Juegos Olímpicos U23 (2016, 2020)',
          'Copa Mundial Sub-20 (5 títulos)',
          'Copa Mundial Sub-17 (4 títulos)',
          'Campeonato Sudamericano Sub-20 (12 títulos)',
          'Campeonato Sudamericano Sub-17 (13 títulos)',
        ],
      },
      'cm': {
        'fr': [
          'Coupe d\'Afrique des Nations (1984, 1988, 2000, 2002, 2017)',
          'Jeux Olympiques (2000)',
          'Jeux Africains (4 titres)',
          'CAN U20 (1995, 2019)',
          'CAN U17 (2003, 2019)',
        ],
        'en': [
          'Africa Cup of Nations (1984, 1988, 2000, 2002, 2017)',
          'Olympic Games (2000)',
          'African Games (4 titles)',
          'CAF Under-20 Championship (1995, 2019)',
          'CAF Under-17 Championship (2003, 2019)',
        ],
        'es': [
          'Copa Africana de Naciones (1984, 1988, 2000, 2002, 2017)',
          'Juegos Olímpicos (2000)',
          'Juegos Africanos (4 títulos)',
          'Campeonato Africano Sub-20 (1995, 2019)',
          'Campeonato Africano Sub-17 (2003, 2019)',
        ],
      },
      'ca': {
        'fr': [
          'Gold Cup / Champ. CONCACAF (1985, 2000)',
          'Championnat CONCACAF U20 (1986, 1996)',
        ],
        'en': [
          'CONCACAF Gold Cup / Champ. CONCACAF (1985, 2000)',
          'CONCACAF Under-20 Championship (1986, 1996)',
        ],
        'es': [
          'Copa de Oro de la CONCACAF / Champ. CONCACAF (1985, 2000)',
          'Campeonato Sub-20 de la CONCACAF (1986, 1996)',
        ],
      },
      'cv': {
        'fr': [
          'Coupe Amílcar Cabral (2007)',
          'Jeux de la Lusophonie (2006)',
        ],
        'en': [
          'Amílcar Cabral Cup (2007)',
          'Lusophony Games (2006)',
        ],
        'es': [
          'Copa Amílcar Cabral (2007)',
          'Juegos de la Lusofonía (2006)',
        ],
      },
      'co': {
        'fr': [
          'Copa América (2001)',
          'Championnat Sudaméricain U20 (1987, 2005, 2013)',
          'Sudaméricain U17 (1993)',
        ],
        'en': [
          'Copa América (2001)',
          'South American Under-20 Championship (1987, 2005, 2013)',
          'South American Under-17 Championship (1993)',
        ],
        'es': [
          'Copa América (2001)',
          'Campeonato Sudamericano Sub-20 (1987, 2005, 2013)',
          'Campeonato Sudamericano Sub-17 (1993)',
        ],
      },
      'kr': {
        'fr': [
          'Coupe d\'Asie (1956, 1960)',
          'Coupe d\'Asie de l\'Est (6 titres)',
          'Jeux Asiatiques (5 titres)',
          'Champ. d\'Asie U20 (12 titres)',
          'Champ. d\'Asie U17 (1986, 2002)',
        ],
        'en': [
          'AFC Asian Cup (1956, 1960)',
          'EAFF East Asian Cup (6 titles)',
          'Asian Games (5 titles)',
          'AFC U-20 Asian Cup (12 titles)',
          'AFC Under-17 Championship (1986, 2002)',
        ],
        'es': [
          'Copa Asiática de la AFC (1956, 1960)',
          'Copa de Asia Oriental de la EAFF (6 títulos)',
          'Juegos Asiáticos (5 títulos)',
          'Copa Asiática Sub-20 de la AFC (12 títulos)',
          'Campeonato Asiático Sub-17 (1986, 2002)',
        ],
      },
      'ci': {
        'fr': [
          'Coupe d\'Afrique des Nations (1992, 2015, 2024)',
          'Tournoi de Toulon (2010)',
          'CAN U17 (2013)',
        ],
        'en': [
          'Africa Cup of Nations (1992, 2015, 2024)',
          'Toulon Tournament (2010)',
          'CAF Under-17 Championship (2013)',
        ],
        'es': [
          'Copa Africana de Naciones (1992, 2015, 2024)',
          'Torneo de Toulon (2010)',
          'Campeonato Africano Sub-17 (2013)',
        ],
      },
      'hr': {
        'fr': [
          'Aucun titre majeur en A',
          'Aucun titre en catégories jeunes',
        ],
        'en': [
          'No major senior titles',
          'No youth titles',
        ],
        'es': [
          'Sin títulos mayores en absoluta',
          'Sin títulos en categorías juveniles',
        ],
      },
      'cw': {
        'fr': [
          'Coupe de la Solidarité des Caraïbes (2017)',
          'Aucun titre en catégories jeunes',
        ],
        'en': [
          'Caribbean Solidarity Cup (2017)',
          'No youth titles',
        ],
        'es': [
          'Copa de la Solidaridad del Caribe (2017)',
          'Sin títulos en categorías juveniles',
        ],
      },
      'sco': {
        'fr': [
          'British Home Championship (24 titres)',
          'Aucun titre en catégories jeunes',
        ],
        'en': [
          'British Home Championship (24 titles)',
          'No youth titles',
        ],
        'es': [
          'British Home Championship (24 títulos)',
          'Sin títulos en categorías juveniles',
        ],
      },
      'eg': {
        'fr': [
          'Coupe d\'Afrique des Nations (1957, 1959, 1986, 1998, 2006, 2008, 2010)',
          'Coupe Arabe des Nations (1992)',
          'CAN U20 (1981, 1991, 2003, 2013)',
          'CAN U23 (2019)',
          'CAN U17 (1997)',
        ],
        'en': [
          'Africa Cup of Nations (1957, 1959, 1986, 1998, 2006, 2008, 2010)',
          'FIFA Arab Cup (1992)',
          'CAF Under-20 Championship (1981, 1991, 2003, 2013)',
          'CAF Under-23 Championship (2019)',
          'CAF Under-17 Championship (1997)',
        ],
        'es': [
          'Copa Africana de Naciones (1957, 1959, 1986, 1998, 2006, 2008, 2010)',
          'Copa Árabe de la FIFA (1992)',
          'Campeonato Africano Sub-20 (1981, 1991, 2003, 2013)',
          'Campeonato Africano Sub-23 (2019)',
          'Campeonato Africano Sub-17 (1997)',
        ],
      },
      'ec': {
        'fr': [
          'Aucun titre majeur en A',
          'Championnat Sudaméricain U20 (2019)',
        ],
        'en': [
          'No major senior titles',
          'South American Under-20 Championship (2019)',
        ],
        'es': [
          'Sin títulos mayores en absoluta',
          'Campeonato Sudamericano Sub-20 (2019)',
        ],
      },
      'es': {
        'fr': [
          'Coupe du Monde (2010)',
          'Euro (1964, 2008, 2012, 2024)',
          'Ligue des Nations (2023)',
          'Jeux Olympiques (1992)',
          'Euro Espoirs U21 (5 titres)',
          'Euro U19 (11 titres)',
          'Euro U17 (9 titres)',
        ],
        'en': [
          'FIFA World Cup (2010)',
          'UEFA European Championship (1964, 2008, 2012, 2024)',
          'UEFA Nations League (2023)',
          'Olympic Games (1992)',
          'UEFA Under-21 Championship (5 titles)',
          'UEFA Under-19 Championship (11 titles)',
          'UEFA Under-17 Championship (9 titles)',
        ],
        'es': [
          'Copa Mundial de la FIFA (2010)',
          'Eurocopa (1964, 2008, 2012, 2024)',
          'Liga de Naciones de la UEFA (2023)',
          'Juegos Olímpicos (1992)',
          'Eurocopa Sub-21 (5 títulos)',
          'Eurocopa Sub-19 (11 títulos)',
          'Eurocopa Sub-17 (9 títulos)',
        ],
      },
      'us': {
        'fr': [
          'Gold Cup (7 titres)',
          'Ligue des Nations CONCACAF (2020, 2023, 2024)',
          'Championnat CONCACAF U20 (3 titres)',
          'Championnat CONCACAF U17 (3 titres)',
        ],
        'en': [
          'CONCACAF Gold Cup (7 titles)',
          'CONCACAF Nations League (2020, 2023, 2024)',
          'CONCACAF Under-20 Championship (3 titles)',
          'CONCACAF Under-17 Championship (3 titles)',
        ],
        'es': [
          'Copa de Oro de la CONCACAF (7 títulos)',
          'Liga de Naciones de la CONCACAF (2020, 2023, 2024)',
          'Campeonato Sub-20 de la CONCACAF (3 títulos)',
          'Campeonato Sub-17 de la CONCACAF (3 títulos)',
        ],
      },
      'fr': {
        'fr': [
          'Coupe du Monde (1998, 2018)',
          'Euro (1984, 2000)',
          'Ligue des Nations (2021)',
          'Coupe des Confédérations (2001, 2003)',
          'Coupe Artemio-Franchi (1985)',
          'Jeux Olympiques (1984)',
          'Euro Espoirs U21 (1988)',
          'Euro U19 (8 titres)',
          'Euro U17 (2004, 2015, 2022)',
          'Coupe du Monde U20 (2013)',
          'Coupe du Monde U17 (2001)',
        ],
        'en': [
          'FIFA World Cup (1998, 2018)',
          'UEFA European Championship (1984, 2000)',
          'UEFA Nations League (2021)',
          'FIFA Confederations Cup (2001, 2003)',
          'Artemio Franchi Cup (1985)',
          'Olympic Games (1984)',
          'UEFA Under-21 Championship (1988)',
          'UEFA Under-19 Championship (8 titles)',
          'UEFA Under-17 Championship (2004, 2015, 2022)',
          'FIFA U-20 World Cup (2013)',
          'FIFA U-17 World Cup (2001)',
        ],
        'es': [
          'Copa Mundial de la FIFA (1998, 2018)',
          'Eurocopa (1984, 2000)',
          'Liga de Naciones de la UEFA (2021)',
          'Copa de las Confederaciones (2001, 2003)',
          'Copa Artemio Franchi (1985)',
          'Juegos Olímpicos (1984)',
          'Eurocopa Sub-21 (1988)',
          'Eurocopa Sub-19 (8 títulos)',
          'Eurocopa Sub-17 (2004, 2015, 2022)',
          'Copa Mundial Sub-20 (2013)',
          'Copa Mundial Sub-17 (2001)',
        ],
      },
      'gh': {
        'fr': [
          'Coupe d\'Afrique des Nations (1963, 1965, 1978, 1982)',
          'Coupe d\'Afrique de l\'Ouest (5 titres)',
          'Coupe du Monde U20 (2009)',
          'Coupe du Monde U17 (1991, 1995)',
          'CAN U20 (4 titres)',
          'CAN U17 (1995, 1999)',
        ],
        'en': [
          'Africa Cup of Nations (1963, 1965, 1978, 1982)',
          'West African Nations Cup (5 titles)',
          'FIFA U-20 World Cup (2009)',
          'FIFA U-17 World Cup (1991, 1995)',
          'CAF Under-20 Championship (4 titles)',
          'CAF Under-17 Championship (1995, 1999)',
        ],
        'es': [
          'Copa Africana de Naciones (1963, 1965, 1978, 1982)',
          'Copa de África Occidental (5 títulos)',
          'Copa Mundial Sub-20 (2009)',
          'Copa Mundial Sub-17 (1991, 1995)',
          'Campeonato Africano Sub-20 (4 títulos)',
          'Campeonato Africano Sub-17 (1995, 1999)',
        ],
      },
      'ht': {
        'fr': [
          'Championnat de la CONCACAF (1973)',
          'Coupe de la Caraïbe (2007)',
          'Aucun titre en catégories jeunes',
        ],
        'en': [
          'CONCACAF Championship (1973)',
          'Caribbean Cup (2007)',
          'No youth titles',
        ],
        'es': [
          'Campeonato de la CONCACAF (1973)',
          'Copa del Caribe (2007)',
          'Sin títulos en categorías juveniles',
        ],
      },
      'ir': {
        'fr': [
          'Coupe d\'Asie (1968, 1972, 1976)',
          'Jeux Asiatiques (4 titres)',
          'Championnat d\'Asie de l\'Ouest (4 titres)',
          'Champ. d\'Asie U19 (4 titres)',
          'Champ. d\'Asie U17 (2008)',
        ],
        'en': [
          'AFC Asian Cup (1968, 1972, 1976)',
          'Asian Games (4 titles)',
          'WAFF Championship (4 titles)',
          'AFC Under-19 Championship (4 titles)',
          'AFC Under-17 Championship (2008)',
        ],
        'es': [
          'Copa Asiática de la AFC (1968, 1972, 1976)',
          'Juegos Asiáticos (4 títulos)',
          'Campeonato de Asia Occidental (4 títulos)',
          'Campeonato Asiático Sub-19 (4 títulos)',
          'Campeonato Asiático Sub-17 (2008)',
        ],
      },
      'iq': {
        'fr': [
          'Coupe d\'Asie (2007)',
          'Coupe Arabe des Nations (4 titres)',
          'Coupe du Golfe des Nations (4 titres)',
          'Champ. d\'Asie U19 (5 titres)',
          'Champ. d\'Asie U17 (2016)',
          'Champ. d\'Asie U23 (2014)',
        ],
        'en': [
          'AFC Asian Cup (2007)',
          'FIFA Arab Cup (4 titles)',
          'Gulf Cup of Nations (4 titles)',
          'AFC Under-19 Championship (5 titles)',
          'AFC Under-17 Championship (2016)',
          'AFC Under-23 Championship (2014)',
        ],
        'es': [
          'Copa Asiática de la AFC (2007)',
          'Copa Árabe de la FIFA (4 títulos)',
          'Copa del Golfo (4 títulos)',
          'Campeonato Asiático Sub-19 (5 títulos)',
          'Campeonato Asiático Sub-17 (2016)',
          'Campeonato Asiático Sub-23 (2014)',
        ],
      },
      'jp': {
        'fr': [
          'Coupe d\'Asie (1992, 2000, 2004, 2011)',
          'Coupe d\'Asie de l\'Est (2013, 2022)',
          'Jeux Asiatiques U23 (2010)',
          'Champ. d\'Asie U19 (2016)',
          'Champ. d\'Asie U17 (4 titres)',
        ],
        'en': [
          'AFC Asian Cup (1992, 2000, 2004, 2011)',
          'EAFF East Asian Cup (2013, 2022)',
          'Asian Games U23 (2010)',
          'AFC Under-19 Championship (2016)',
          'AFC Under-17 Championship (4 titles)',
        ],
        'es': [
          'Copa Asiática de la AFC (1992, 2000, 2004, 2011)',
          'Copa de Asia Oriental de la EAFF (2013, 2022)',
          'Juegos Asiáticos U23 (2010)',
          'Campeonato Asiático Sub-19 (2016)',
          'Campeonato Asiático Sub-17 (4 títulos)',
        ],
      },
      'jo': {
        'fr': [
          'Jeux Panarabes (1997, 1999)',
          'Championnat d\'Asie de l\'Ouest U16 (2022)',
        ],
        'en': [
          'Pan Arab Games (1997, 1999)',
          'WAFF Under-16 Championship (2022)',
        ],
        'es': [
          'Juegos Panarábicos (1997, 1999)',
          'Campeonato WAFF Sub-16 (2022)',
        ],
      },
      'ma': {
        'fr': [
          'Coupe d\'Afrique des Nations (1976)',
          'CHAN (2018, 2020)',
          'Coupe Arabe des Nations (2012)',
          'CAN U23 (2023)',
          'CAN U20 (1997)',
          'Jeux de la Francophonie (3 titres)',
        ],
        'en': [
          'Africa Cup of Nations (1976)',
          'African Nations Championship (CHAN) (2018, 2020)',
          'FIFA Arab Cup (2012)',
          'CAF Under-23 Championship (2023)',
          'CAF Under-20 Championship (1997)',
          'Francophonie Games (3 titles)',
        ],
        'es': [
          'Copa Africana de Naciones (1976)',
          'Campeonato Africano de Naciones (CHAN) (2018, 2020)',
          'Copa Árabe de la FIFA (2012)',
          'Campeonato Africano Sub-23 (2023)',
          'Campeonato Africano Sub-20 (1997)',
          'Juegos de la Francofonía (3 títulos)',
        ],
      },
      'mx': {
        'fr': [
          'Gold Cup / Champ. CONCACAF (12 titres)',
          'Coupe des Confédérations (1999)',
          'Coupe CONCACAF (2015)',
          'Jeux Olympiques U23 (2012)',
          'Coupe du Monde U17 (2005, 2011)',
          'Champ. CONCACAF U20 (13 titres)',
          'Champ. CONCACAF U17 (9 titres)',
        ],
        'en': [
          'CONCACAF Gold Cup / Champ. CONCACAF (12 titles)',
          'FIFA Confederations Cup (1999)',
          'Coupe CONCACAF (2015)',
          'Olympic Games U23 (2012)',
          'FIFA U-17 World Cup (2005, 2011)',
          'CONCACAF Under-20 Championship (13 titles)',
          'CONCACAF Under-17 Championship (9 titles)',
        ],
        'es': [
          'Copa de Oro de la CONCACAF / Champ. CONCACAF (12 títulos)',
          'Copa de las Confederaciones (1999)',
          'Coupe CONCACAF (2015)',
          'Juegos Olímpicos U23 (2012)',
          'Copa Mundial Sub-17 (2005, 2011)',
          'Campeonato Sub-20 de la CONCACAF (13 títulos)',
          'Campeonato Sub-17 de la CONCACAF (9 títulos)',
        ],
      },
      'no': {
        'fr': [
          'Aucun titre majeur en A',
          'Aucun titre en catégories jeunes',
        ],
        'en': [
          'No major senior titles',
          'No youth titles',
        ],
        'es': [
          'Sin títulos mayores en absoluta',
          'Sin títulos en categorías juveniles',
        ],
      },
      'nz': {
        'fr': [
          'Coupe d\'Océanie OFC (6 titres)',
          'Champ. Océanie U20 (7 titres)',
          'Champ. Océanie U17 (9 titres)',
        ],
        'en': [
          'OFC Nations Cup (6 titles)',
          'OFC Under-20 Championship (7 titles)',
          'OFC Under-17 Championship (9 titles)',
        ],
        'es': [
          'Copa de las Naciones de la OFC (6 títulos)',
          'Campeonato Sub-20 de la OFC (7 títulos)',
          'Campeonato Sub-17 de la OFC (9 títulos)',
        ],
      },
      'nl': {
        'fr': [
          'Euro (1988)',
          'Euro Espoirs U21 (2006, 2007)',
          'Euro U17 (2011, 2012, 2018, 2019)',
        ],
        'en': [
          'UEFA European Championship (1988)',
          'UEFA Under-21 Championship (2006, 2007)',
          'UEFA Under-17 Championship (2011, 2012, 2018, 2019)',
        ],
        'es': [
          'Eurocopa (1988)',
          'Eurocopa Sub-21 (2006, 2007)',
          'Eurocopa Sub-17 (2011, 2012, 2018, 2019)',
        ],
      },
      'pa': {
        'fr': [
          'Coupe d\'Amérique Centrale (2009)',
          'Championnat de la CONCACAF U17 (2024)',
        ],
        'en': [
          'Coupe d\'Amérique Centrale (2009)',
          'CONCACAF Under-17 Championship (2024)',
        ],
        'es': [
          'Coupe d\'Amérique Centrale (2009)',
          'Campeonato Sub-17 de la CONCACAF (2024)',
        ],
      },
      'py': {
        'fr': [
          'Copa América (1953, 1979)',
          'Championnat Sudaméricain U20 (1971)',
        ],
        'en': [
          'Copa América (1953, 1979)',
          'South American Under-20 Championship (1971)',
        ],
        'es': [
          'Copa América (1953, 1979)',
          'Campeonato Sudamericano Sub-20 (1971)',
        ],
      },
      'pt': {
        'fr': [
          'Euro (2016)',
          'Ligue des Nations (2019)',
          'Coupe du Monde U20 (1989, 1991)',
          'Euro U19 (4 titres)',
          'Euro U17 (6 titres)',
        ],
        'en': [
          'UEFA European Championship (2016)',
          'UEFA Nations League (2019)',
          'FIFA U-20 World Cup (1989, 1991)',
          'UEFA Under-19 Championship (4 titles)',
          'UEFA Under-17 Championship (6 titles)',
        ],
        'es': [
          'Eurocopa (2016)',
          'Liga de Naciones de la UEFA (2019)',
          'Copa Mundial Sub-20 (1989, 1991)',
          'Eurocopa Sub-19 (4 títulos)',
          'Eurocopa Sub-17 (6 títulos)',
        ],
      },
      'qa': {
        'fr': [
          'Coupe d\'Asie (2019, 2023)',
          'Coupe du Golfe des Nations (1992, 2004, 2014)',
          'Championnat d\'Asie U19 (2014)',
        ],
        'en': [
          'AFC Asian Cup (2019, 2023)',
          'Gulf Cup of Nations (1992, 2004, 2014)',
          'AFC Under-19 Championship (2014)',
        ],
        'es': [
          'Copa Asiática de la AFC (2019, 2023)',
          'Copa del Golfo (1992, 2004, 2014)',
          'Campeonato Asiático Sub-19 (2014)',
        ],
      },
      'cz': {
        'fr': [
          'Euro (1976 - sous la Tchécoslovaquie)',
          'Euro Espoirs U21 (2002)',
          'Euro U19 (1968, 1990)',
        ],
        'en': [
          'UEFA European Championship (1976 - as Czechoslovakia)',
          'UEFA Under-21 Championship (2002)',
          'UEFA Under-19 Championship (1968, 1990)',
        ],
        'es': [
          'Eurocopa (1976 - como Checoslovaquia)',
          'Eurocopa Sub-21 (2002)',
          'Eurocopa Sub-19 (1968, 1990)',
        ],
      },
      'sa': {
        'fr': [
          'Coupe d\'Asie (1984, 1988, 1996)',
          'Coupe du Golfe (3 titres)',
          'Coupe Arabe des Nations (1998, 2002)',
          'Coupe du Monde U17 (1989)',
          'Champ. d\'Asie U19 (3 titres)',
          'Champ. d\'Asie U17 (1985, 1988)',
          'Champ. d\'Asie U23 (2022)',
        ],
        'en': [
          'AFC Asian Cup (1984, 1988, 1996)',
          'Gulf Cup of Nations (3 titles)',
          'FIFA Arab Cup (1998, 2002)',
          'FIFA U-17 World Cup (1989)',
          'AFC Under-19 Championship (3 titles)',
          'AFC Under-17 Championship (1985, 1988)',
          'AFC Under-23 Championship (2022)',
        ],
        'es': [
          'Copa Asiática de la AFC (1984, 1988, 1996)',
          'Copa del Golfo (3 títulos)',
          'Copa Árabe de la FIFA (1998, 2002)',
          'Copa Mundial Sub-17 (1989)',
          'Campeonato Asiático Sub-19 (3 títulos)',
          'Campeonato Asiático Sub-17 (1985, 1988)',
          'Campeonato Asiático Sub-23 (2022)',
        ],
      },
      'sn': {
        'fr': [
          'Coupe d\'Afrique des Nations (2021, 2025)',
          'CHAN (2022)',
          'Coupe Amílcar Cabral (8 titres)',
          'Coupe de l\'UEMOA (3 titres)',
          'CAN U20 (2023)',
          'CAN U17 (2023)',
          'Jeux Africains U23 (2015)',
        ],
        'en': [
          'Africa Cup of Nations (2021, 2025)',
          'African Nations Championship (CHAN) (2022)',
          'Amílcar Cabral Cup (8 titles)',
          'UEMOA Tournament (3 titles)',
          'CAF Under-20 Championship (2023)',
          'CAF Under-17 Championship (2023)',
          'African Games U23 (2015)',
        ],
        'es': [
          'Copa Africana de Naciones (2021, 2025)',
          'Campeonato Africano de Naciones (CHAN) (2022)',
          'Copa Amílcar Cabral (8 títulos)',
          'Torneo de la UEMOA (3 títulos)',
          'Campeonato Africano Sub-20 (2023)',
          'Campeonato Africano Sub-17 (2023)',
          'Juegos Africanos U23 (2015)',
        ],
      },
      'za': {
        'fr': [
          'Coupe d\'Afrique des Nations (1996)',
          'Coupe COSAFA (5 titres)',
          'Championnat COSAFA U20 (8 titres)',
        ],
        'en': [
          'Africa Cup of Nations (1996)',
          'COSAFA Cup (5 titles)',
          'COSAFA Under-20 Championship (8 titles)',
        ],
        'es': [
          'Copa Africana de Naciones (1996)',
          'Copa COSAFA (5 títulos)',
          'Campeonato COSAFA Sub-20 (8 títulos)',
        ],
      },
      'se': {
        'fr': [
          'Aucun titre majeur en A',
          'Jeux Olympiques (1948)',
          'Euro Espoirs U21 (2015)',
        ],
        'en': [
          'No major senior titles',
          'Olympic Games (1948)',
          'UEFA Under-21 Championship (2015)',
        ],
        'es': [
          'Sin títulos mayores en absoluta',
          'Juegos Olímpicos (1948)',
          'Eurocopa Sub-21 (2015)',
        ],
      },
      'ch': {
        'fr': [
          'Aucun titre majeur en A',
          'Coupe du Monde U17 (2009)',
          'Euro U17 (2002)',
        ],
        'en': [
          'No major senior titles',
          'FIFA U-17 World Cup (2009)',
          'UEFA Under-17 Championship (2002)',
        ],
        'es': [
          'Sin títulos mayores en absoluta',
          'Copa Mundial Sub-17 (2009)',
          'Eurocopa Sub-17 (2002)',
        ],
      },
      'tn': {
        'fr': [
          'Coupe d\'Afrique des Nations (2004)',
          'CHAN (2011)',
          'Coupe Arabe des Nations (1963)',
          'Championnat arabe des moins de 20 ans (2020, 2021)',
        ],
        'en': [
          'Africa Cup of Nations (2004)',
          'African Nations Championship (CHAN) (2011)',
          'FIFA Arab Cup (1963)',
          'Arab Under-20 Championship (2020, 2021)',
        ],
        'es': [
          'Copa Africana de Naciones (2004)',
          'Campeonato Africano de Naciones (CHAN) (2011)',
          'Copa Árabe de la FIFA (1963)',
          'Campeonato Árabe Sub-20 (2020, 2021)',
        ],
      },
      'tr': {
        'fr': [
          'Aucun titre majeur en A',
          'Euro U19 (1992)',
        ],
        'en': [
          'No major senior titles',
          'UEFA Under-19 Championship (1992)',
        ],
        'es': [
          'Sin títulos mayores en absoluta',
          'Eurocopa Sub-19 (1992)',
        ],
      },
      'uy': {
        'fr': [
          'Coupe du Monde (1930, 1950)',
          'Copa América (15 titres)',
          'Coupe du Monde U20 (2023)',
          'Championnat Sudaméricain U20 (8 titres)',
        ],
        'en': [
          'FIFA World Cup (1930, 1950)',
          'Copa América (15 titles)',
          'FIFA U-20 World Cup (2023)',
          'South American Under-20 Championship (8 titles)',
        ],
        'es': [
          'Copa Mundial de la FIFA (1930, 1950)',
          'Copa América (15 títulos)',
          'Copa Mundial Sub-20 (2023)',
          'Campeonato Sudamericano Sub-20 (8 títulos)',
        ],
      },
      'uz': {
        'fr': [
          'Jeux Asiatiques (1994)',
          'Championnat d\'Asie U20 (2023)',
          'Championnat d\'Asie U17 (2012)',
        ],
        'en': [
          'Asian Games (1994)',
          'AFC U-20 Asian Cup (2023)',
          'AFC Under-17 Championship (2012)',
        ],
        'es': [
          'Juegos Asiáticos (1994)',
          'Copa Asiática Sub-20 de la AFC (2023)',
          'Campeonato Asiático Sub-17 (2012)',
        ],
      },
      'cd': {
        'fr': [
          '2x Coupe d\'Afrique des Nations (1968, 1974)',
          '2x Championnat d\'Afrique des Nations (CHAN 2009, 2016)',
        ],
        'en': [
          '2x Africa Cup of Nations (1968, 1974)',
          '2x African Nations Championship (CHAN 2009, 2016)',
        ],
        'es': [
          '2x Copa Africana de Naciones (1968, 1974)',
          '2x Campeonato Africano de Naciones (CHAN 2009, 2016)',
        ],
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
      'fr': 1, 'es': 2, 'ar': 3, 'en': 4, 'pt': 5,
      'br': 6, 'nl': 7, 'ma': 8, 'be': 9, 'de': 10,
      'hr': 11, 'it': 12, 'co': 13, 'sn': 14, 'mx': 15,
      'us': 16, 'uy': 17, 'jp': 18, 'ch': 19, 'dk': 20,
      'ir': 21, 'kr': 22, 'ec': 23, 'tr': 24, 'at': 25,
      'ng': 26, 'au': 27, 'dz': 28, 'eg': 29, 'ca': 30,
      'no': 31, 'pl': 33, 'pa': 34, 'ci': 35,
      'py': 38, 'sco': 40, 'se': 41,
      'cz': 43, 'tn': 44, 'cm': 45, 'cd': 48,
      'uz': 50, 'qa': 56, 'iq': 59, 'za': 60, 'sa': 61, 'jo': 64,
      'ba': 66, 'cv': 69, 'gh': 74, 'cw': 82, 'ht': 83,
      'nz': 85,
    };
    return rankings[code] ?? 999;
  }

  static List<String> get allTeams {
    final List<String> qualified48 = [
      'ar', 'at', 'au', 'ba', 'be', 'br', 'ca', 'cd', 'ch', 'ci', 'co', 'cv', 'cw', 'cz', 'de', 'dz', 
      'ec', 'eg', 'en', 'es', 'fr', 'gh', 'hr', 'ht', 'iq', 'ir', 'jo', 'jp', 'kr', 'ma', 'mx', 'nl', 
      'no', 'nz', 'pa', 'pt', 'py', 'qa', 'sa', 'sco', 'se', 'sn', 'tn', 'tr', 'us', 'uy', 'uz', 'za'
    ];
    
    qualified48.sort((a, b) => getFifaRanking(a).compareTo(getFifaRanking(b)));
    return qualified48;
  }
}
