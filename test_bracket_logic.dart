import 'dart:convert';
import 'dart:io';
import 'lib/models/match.dart';
import 'lib/utils/fifa_rules.dart';

void main() async {
  final file = File('assets/initial_matches_new.json');
  final String contents = await file.readAsString();
  final List<dynamic> jsonList = jsonDecode(contents);
  List<WorldCupMatch> matches = jsonList.map((m) => WorldCupMatch.fromJson(m)).toList();
  
  // Now resolve
  final resolved = FifaRules.resolveKnockoutStage(matches);
  
  // Find m89
  final m89 = resolved.firstWhere((m) => m.id == 'm89');
  print('m89 after resolve: t1=${m89.t1}, t2=${m89.t2}');
}
