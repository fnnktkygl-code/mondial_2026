import 'package:flutter/material.dart';

class TeamColors {
  TeamColors._();

  static const Map<String, List<Color>> flagColors = {
    'sn': [Color(0xFF00853F), Color(0xFFFDEF42), Color(0xFFE31B23)], // Senegal
    'ar': [Color(0xFF74ACDF), Colors.white, Color(0xFF74ACDF)], // Argentina
    'es': [Color(0xFFC60B1E), Color(0xFFFFC400), Color(0xFFC60B1E)], // Spain
    'fr': [Color(0xFF002395), Colors.white, Color(0xFFED2939)], // France
    'br': [Color(0xFF009B3A), Color(0xFFFEDF00), Color(0xFF002776)], // Brazil
    'de': [Colors.black, Color(0xFFFF0000), Color(0xFFFFCC00)], // Germany
    'it': [Color(0xFF009246), Colors.white, Color(0xFFCE2B37)], // Italy
    'pt': [Color(0xFF006600), Color(0xFFFF0000)], // Portugal
    'ma': [Color(0xFFC1272D), Color(0xFF006233)], // Morocco
    'nl': [Color(0xFFAE1C28), Colors.white, Color(0xFF21468B)], // Netherlands
    'be': [Colors.black, Color(0xFFFDDA24), Color(0xFFEF3340)], // Belgium
    'hr': [Color(0xFFFF0000), Colors.white, Color(0xFF171796)], // Croatia
    'en': [Colors.white, Color(0xFFCE1126)], // England
    'mx': [Color(0xFF006847), Colors.white, Color(0xFFCE1126)], // Mexico
    'us': [Color(0xFFB22234), Colors.white, Color(0xFF3C3B6E)], // USA
    'uy': [Color(0xFF0038A8), Colors.white, Color(0xFFFCD116)], // Uruguay
    'jp': [Colors.white, Color(0xFFBC002D)], // Japan
    'ch': [Color(0xFFFF0000), Colors.white], // Switzerland
    'cm': [Color(0xFF007A5E), Color(0xFFCE1126), Color(0xFFFCD116)], // Cameroon
    'dz': [Color(0xFF006233), Colors.white, Color(0xFFD21034)], // Algeria
    'eg': [Color(0xFFCE1126), Colors.white, Colors.black], // Egypt
    'ng': [Color(0xFF008751), Colors.white], // Nigeria
    'ci': [Color(0xFFFF8200), Colors.white, Color(0xFF009E60)], // Ivory Coast
    'ca': [Color(0xFFFF0000), Colors.white], // Canada
    'au': [Color(0xFF00008B), Colors.white, Color(0xFFFF0000)], // Australia
    'kr': [Colors.white, Colors.black, Color(0xFFCD2E3A), Color(0xFF0047A0)], // South Korea
    'tr': [Color(0xFFE30A17), Colors.white], // Turkey
    'at': [Color(0xFFEF3340), Colors.white], // Austria
    'co': [Color(0xFFFCD116), Color(0xFF0038A8), Color(0xFFCE1126)], // Colombia
    'ec': [Color(0xFFFFDD00), Color(0xFF034EA2), Color(0xFFED1C24)], // Ecuador
    'pe': [Color(0xFFD91023), Colors.white], // Peru
    'cl': [Colors.white, Color(0xFF0039A6), Color(0xFFD52B1E)], // Chile
    'sa': [Color(0xFF006C35), Colors.white], // Saudi Arabia
    'qa': [Color(0xFF8D1B3D), Colors.white], // Qatar
    'ir': [Color(0xFF239F40), Colors.white, Color(0xFFDA0000)], // Iran
    'pl': [Colors.white, Color(0xFFDC143C)], // Poland
    'se': [Color(0xFF006AA7), Color(0xFFFECC00)], // Sweden
    'dk': [Color(0xFFC60C30), Colors.white], // Denmark
    'no': [Color(0xFFBA0C2F), Color(0xFF00205B), Colors.white], // Norway
    'fi': [Colors.white, Color(0xFF003580)], // Finland
    'sc': [Colors.white, Color(0xFFCE1126)], // Scotland (using 'sc' or 'sco'?)
    'sco': [Color(0xFF005EB8), Colors.white], // Scotland
    'wa': [Colors.white, Color(0xFF00AB39), Color(0xFFD30731)], // Wales
    'rs': [Color(0xFFC6363C), Color(0xFF0C4076), Colors.white], // Serbia
    'ba': [Color(0xFF002395), Color(0xFFFECB00)], // Bosnia
    'ua': [Color(0xFF0057B7), Color(0xFFFFD700)], // Ukraine
    'ro': [Color(0xFF002B7F), Color(0xFFFCD116), Color(0xFFCE1126)], // Romania
    'hu': [Color(0xFF436F4D), Colors.white, Color(0xFFCD2A3E)], // Hungary
    'cz': [Colors.white, Color(0xFF11457E), Color(0xFFD7141A)], // Czechia
    'sk': [Colors.white, Color(0xFF0B4EA2), Color(0xFFEE1C25)], // Slovakia
    'si': [Colors.white, Color(0xFF0000FF), Color(0xFFFF0000)], // Slovenia
    'gr': [Color(0xFF0D5EAF), Colors.white], // Greece
  };

  static List<Color> getColors(String code) {
    return flagColors[code.toLowerCase()] ?? [Colors.white, Colors.amber, Colors.grey];
  }
}
