import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../services/team_profile_service.dart';
import '../services/firebase_service.dart';
import '../l10n/translations.dart';

class WCNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static int generateStableId(String matchId) {
    // E.g. 'm12' -> 12, 'm12_ht' -> 121, 'm12_ft' -> 122
    final RegExp digitRegex = RegExp(r'\d+');
    final match = digitRegex.firstMatch(matchId);
    
    int baseId = 0;
    if (match != null) {
      baseId = int.parse(match.group(0)!);
    } else {
      // Fallback hash
      int hash = 0;
      for (int i = 0; i < matchId.length; i++) {
        hash = 31 * hash + matchId.codeUnitAt(i);
      }
      baseId = hash.abs() % 100000;
    }

    if (matchId.endsWith('_ht')) return (baseId * 10) + 1;
    if (matchId.endsWith('_ft')) return (baseId * 10) + 2;
    return baseId * 10;
  }

  static String _getFlagEmoji(String code) {
    const Map<String, String> flags = {
      'mx': '🇲🇽',
      'de': '🇩🇪',
      'us': '🇺🇸',
      'en': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'ca': '🇨🇦',
      'jp': '🇯🇵',
      'fr': '🇫🇷',
      'br': '🇧🇷',
      'sn': '🇸🇳',
      'ar': '🇦🇷',
      'ma': '🇲🇦',
      'es': '🇪🇸',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'nl': '🇳🇱',
      'be': '🇧🇪',
      'hr': '🇭🇷',
      'uy': '🇺🇾',
      'co': '🇨🇴',
      'kr': '🇰🇷',
      'cm': '🇨🇲',
      'ng': '🇳🇬',
      'se': '🇸🇪',
      'ch': '🇨🇭',
      'dk': '🇩🇰',
      'pl': '🇵🇱',
      'ua': '🇺🇦',
      'dz': '🇩🇿',
      'eg': '🇪🇬',
      'tn': '🇹🇳',
      'gh': '🇬🇭',
      'ci': '🇨🇮',
      'cl': '🇨🇱',
      'pe': '🇵🇪',
      'ec': '🇪🇨',
      've': '🇻🇪',
      'au': '🇦🇺',
      'nz': '🇳🇿',
      'sa': '🇸🇦',
      'ir': '🇮🇷',
      'tr': '🇹🇷',
      'gr': '🇬🇷',
      'cz': '🇨🇿',
      'at': '🇦🇹',
      'ro': '🇷🇴',
      'hu': '🇭🇺',
      'bg': '🇧🇬',
      'rs': '🇷🇸',
      'za': '🇿🇦',
      'ba': '🇧🇦',
      'cd': '🇨🇩',
      'cw': '🇨🇼',
      'cv': '🇨🇻',
      'sco': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
      'ht': '🇭🇹',
      'iq': '🇮🇶',
      'jo': '🇯🇴',
      'no': '🇳🇴',
      'pa': '🇵🇦',
      'py': '🇵🇾',
      'qa': '🇶🇦',
      'uz': '🇺🇿',
    };
    return flags[code.toLowerCase()] ?? '⚽';
  }

  static String getTeamNickname(String code, String lang) {
    try {
      final cleanCode = code.toLowerCase().replaceAll('g_', '');
      final profile = WCTeamProfileService.getProfile(cleanCode, lang);
      return profile.nickname.isNotEmpty
          ? profile.nickname
          : AppTranslations.getTeam(lang, cleanCode);
    } catch (_) {
      return AppTranslations.getTeam(lang, code.toLowerCase());
    }
  }

  // ─── Init & Permissions ─────────────────────────────────────────────────────

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      if (!kIsWeb) {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      }
    } catch (e) {
      debugPrint('Could not get local timezone: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse _) {},
      );

      _setupFirebaseMessaging();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  static void _setupFirebaseMessaging() {
    FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showInstantNotification(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification!.title ?? 'Prono Challenge',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Optionally save the token to Firestore for the backend
    FirebaseMessaging.instance.getToken().then((token) async {
      if (token != null) {
        try {
          final uid = await WCFirebaseService.getOrCreateUserId();
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'fcmToken': token,
            'fcmUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    });

    // Keeping Firestore listener as a fallback for specific in-app notifications
    // if backend isn't sending direct FCM. However, FCM is preferred.
    _startFirestoreListener();
  }

  static void _startFirestoreListener() async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                final title = data['title'] as String? ?? 'Notification';
                final body = data['body'] as String? ?? '';
                showInstantNotification(
                  id: change.doc.id,
                  title: title,
                  body: body,
                );

                // Mark as read so we don't show it again
                change.doc.reference.update({'read': true});
              }
            }
          }
        });
  }

  static Future<bool> requestPermissions() async {
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (granted == true) return true;
      }

      final mac = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (mac != null) {
        final granted = await mac.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (granted == true) return true;
      }

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        if (granted == true) return true;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  // ─── Core send methods ──────────────────────────────────────────────────────

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'match_alerts',
      'Match Alerts',
      channelDescription: 'Notifications for match starts and results',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await showInstantNotification(id: id.toString(), title: title, body: body);
  }

  static Future<void> showInstantNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    try {
      final int stableId = generateStableId(id);
      await _plugin.show(
        id: stableId,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }

  static Future<void> scheduleMatchNotification({
    required String matchId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return; // flutter_local_notifications doesn't support Web
    
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      final int stableId = generateStableId(matchId);
      await _plugin.zonedSchedule(
        id: stableId,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  static Future<void> cancelNotification(String matchId) async {
    if (kIsWeb) return;
    
    try {
      await _plugin.cancel(generateStableId(matchId));
      await _plugin.cancel(generateStableId('${matchId}_ht'));
      await _plugin.cancel(generateStableId('${matchId}_ft'));
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // ─── Scheduled HT / FT ──────────────────────────────────────────────────────

  static Future<void> scheduleHalfTimeAndFullTimeNotifications({
    required List<WorldCupMatch> matches,
    required String lang,
  }) async {
    final now = DateTime.now();
    for (final match in matches) {
      if (match.isPlayed || match.date.isBefore(now)) continue;

      final htTime = match.date.add(const Duration(minutes: 45));
      final ftTime = match.date.add(const Duration(minutes: 105));

      await scheduleMatchNotification(
        matchId: '${match.id}_ht',
        title: AppTranslations.get(lang, 'halfTimeTitle'),
        body: AppTranslations.get(lang, 'halfTimeBody'),
        scheduledDate: htTime,
      );

      await scheduleMatchNotification(
        matchId: '${match.id}_ft',
        title: AppTranslations.get(lang, 'fullTimeTitle'),
        body: AppTranslations.get(lang, "fullTimeBody"),
        scheduledDate: ftTime,
      );
    }
  }

  // ─── Notification body formatter ────────────────────────────────────────────

  static String formatScoreNotificationBody({
    required String lang,
    required String t1Code,
    required String t2Code,
    required int t1Score,
    required int t2Score,
    required bool isFinished,
  }) {
    final cleanT1 = t1Code.toLowerCase().replaceAll('g_', '');
    final cleanT2 = t2Code.toLowerCase().replaceAll('g_', '');

    final f1 = _getFlagEmoji(cleanT1);
    final f2 = _getFlagEmoji(cleanT2);
    final n1 = getTeamNickname(cleanT1, lang);
    final n2 = getTeamNickname(cleanT2, lang);

    final int diff = (t1Score - t2Score).abs();
    final bool isDraw = t1Score == t2Score;
    final bool t1Wins = t1Score > t2Score;
    final String winner = t1Wins ? n1 : n2;
    final String loser = t1Wins ? n2 : n1;
    final String wFlag = t1Wins ? f1 : f2;
    final String lFlag = t1Wins ? f2 : f1;
    final int wScore = t1Wins ? t1Score : t2Score;
    final int lScore = t1Wins ? t2Score : t1Score;

    final int seed =
        (DateTime.now().millisecond + t1Score * 7 + t2Score * 13) % 8;

    // ── FRANÇAIS ──────────────────────────────────────────────────────────────
    if (lang == 'fr') {
      if (isFinished) {
        if (isDraw && t1Score == 0) {
          return [
            '🥱 0-0. $n1 $f1 et $n2 $f2 ont soigneusement évité de se faire du mal.',
            '😴 Zéro but, zéro frisson — $n1 $f1 0-0 $n2 $f2. Le gardien peut rentrer à pied.',
            '🧱 Deux défenses de fer, zéro inspiration — $n1 $f1 0-0 $n2 $f2.',
            '😐 $n1 $f1 et $n2 $f2 se quittent sans s\'être dit bonjour. 0-0.',
            '🏜️ Un désert offensif. $n1 $f1 0-0 $n2 $f2. Même les supporters bâillent.',
            '🤷 0-0. $n1 $f1 et $n2 $f2 ont joué la sécurité… trop la sécurité.',
            '💤 Blanc-blanc. $n1 $f1 et $n2 $f2 n\'ont rien voulu se dire ce soir.',
            '🔒 Match verrouillé. $n1 $f1 0-0 $n2 $f2. Les filets sont restés froids.',
          ][seed];
        }
        if (isDraw) {
          return [
            '🤝 $n1 $f1 $t1Score-$t2Score $n2 $f2. Bons amis, points partagés.',
            '😤 Ni vainqueur ni vaincu — $n1 $f1 $t1Score-$t2Score $n2 $f2. Le foot est parfois cruel.',
            '⚖️ Équilibre parfait ce soir : $n1 $f1 $t1Score-$t2Score $n2 $f2.',
            '🔥 Du spectacle mais pas de décision — $n1 $f1 $t1Score-$t2Score $n2 $f2.',
            '😮‍💨 On repart avec un point chacun. $n1 $f1 $t1Score-$t2Score $n2 $f2.',
            '🎭 Même scénario, même score — $n1 $f1 et $n2 $f2 dos à dos $t1Score partout.',
            '🤔 Tout ça pour ça ? $n1 $f1 $t1Score-$t2Score $n2 $f2. Match nul frustrant.',
            '💬 $n1 $f1 et $n2 $f2 ne se départagent pas — $t1Score-$t2Score. Rendez-vous au prochain tour ?',
          ][seed];
        }
        if (diff >= 4) {
          return [
            '💀 Naufrage total pour $loser $lFlag — $winner $wFlag les coule $wScore-$lScore.',
            '🔥 $winner $wFlag met le feu ! $wScore-$lScore, $loser $lFlag n\'a rien pu faire.',
            '😱 Humiliation complète — $winner $wFlag $wScore-$lScore $loser $lFlag. Sans discussion.',
            '⚡ $winner $wFlag a tout écrasé sur son passage. $wScore-$lScore face à $loser $lFlag.',
            '🚀 $winner $wFlag en mode galactique — $wScore-$lScore, $loser $lFlag KO debout.',
            '💥 Démolition en règle ! $winner $wFlag $wScore-$lScore $loser $lFlag. Impitoyable.',
            '🌊 $loser $lFlag submergé sous les buts — $winner $wFlag $wScore-$lScore. Correction.',
            '😤 $winner $wFlag a tout simplement écrasé $loser $lFlag $wScore-$lScore. Pas de débat.',
          ][seed];
        }
        if (diff == 3) {
          return [
            '💪 Belle maîtrise de $winner $wFlag — $wScore-$lScore face à $loser $lFlag.',
            '🎯 $winner $wFlag efficace et solide. $wScore-$lScore, $loser $lFlag n\'a rien trouvé.',
            '🔥 $winner $wFlag prend le large — $wScore-$lScore contre $loser $lFlag. Impressionnant.',
            '😤 $loser $lFlag a tenté, mais $winner $wFlag était trop fort ce soir. $wScore-$lScore.',
            '⚡ Net et sans bavure : $winner $wFlag $wScore-$lScore $loser $lFlag.',
            '🏆 $winner $wFlag régale — $wScore-$lScore ! $loser $lFlag rentre avec des questions.',
            '💥 $winner $wFlag dominant de bout en bout. $wScore-$lScore face à $loser $lFlag.',
            '🚀 $winner $wFlag trop fort pour $loser $lFlag ce soir — $wScore-$lScore !',
          ][seed];
        }
        if (diff == 2) {
          return [
            '✅ $winner $wFlag s\'impose proprement $wScore-$lScore face à $loser $lFlag.',
            '🎉 $winner $wFlag prend les 3 points — $wScore-$lScore. $loser $lFlag repartent frustrés.',
            '💪 $winner $wFlag a fait le job : $wScore-$lScore contre $loser $lFlag.',
            '😤 $loser $lFlag a essayé — $winner $wFlag a été plus fort. $wScore-$lScore.',
            '🏆 Belle victoire de $winner $wFlag sur $loser $lFlag — $wScore-$lScore ce soir.',
            '⚡ $winner $wFlag conclut bien : $wScore-$lScore. $loser $lFlag laisse passer l\'occasion.',
            '🎯 $winner $wFlag ne tremble pas — $wScore-$lScore contre $loser $lFlag. Sérieux.',
            '✨ $winner $wFlag $wScore-$lScore $loser $lFlag. Propre, efficace, mérité.',
          ][seed];
        }
        // diff == 1
        return [
          '😅 Victoire courte mais précieuse — $winner $wFlag $wScore-$lScore $loser $lFlag.',
          '💨 $winner $wFlag arrache les 3 points $wScore-$lScore. $loser $lFlag à deux doigts de l\'égalisation.',
          '🫀 $winner $wFlag s\'en sort de justesse — $wScore-$lScore face à $loser $lFlag. Cœur qui bat.',
          '😮‍💨 $wScore-$lScore — $winner $wFlag souffre mais gagne. $loser $lFlag méritait mieux.',
          '🔒 $winner $wFlag tient bon jusqu\'au bout — $wScore-$lScore contre $loser $lFlag.',
          '🎭 Thriller jusqu\'au bout ! $winner $wFlag $wScore-$lScore $loser $lFlag. Court mais suffisant.',
          '💪 Un but d\'écart, mais 3 points entiers pour $winner $wFlag — $wScore-$lScore.',
          '⚽ $winner $wFlag ne lâche rien — $wScore-$lScore face à $loser $lFlag. Bataille gagnée.',
        ][seed];
      }

      // Mi-temps FR
      if (isDraw && t1Score == 0) {
        return [
          '😴 0-0 à la pause. $n1 $f1 et $n2 $f2 cherchent encore leurs jambes.',
          '🧱 Zéro but à la mi-temps — $n1 $f1 et $n2 $f2 se méfient.',
          '🤷 Pause : 0-0. Ça manque de piment entre $n1 $f1 et $n2 $f2.',
          '😬 Mi-temps : $n1 $f1 0-0 $n2 $f2. Quelqu\'un va devoir se lancer.',
          '🏜️ Premier acte stérile — $n1 $f1 0-0 $n2 $f2. La deuxième sera-t-elle meilleure ?',
          '🔒 0-0 à la pause. Les défenses dominent pour l\'instant.',
          '💤 $n1 $f1 et $n2 $f2 à 0-0. Il va falloir se réveiller.',
          '⏸️ Rien à signaler à la mi-temps — $n1 $f1 0-0 $n2 $f2.',
        ][seed];
      }
      if (isDraw) {
        return [
          '⏸️ Mi-temps : $n1 $f1 $t1Score-$t2Score $n2 $f2. Tout reste à jouer.',
          '🔥 Match animé ! $n1 $f1 $t1Score-$t2Score $n2 $f2 à la pause. La suite promet.',
          '😤 Égalité à la pause — $n1 $f1 et $n2 $f2 $t1Score-$t2Score. Qui va craquer ?',
          '⚽ $t1Score-$t2Score à la mi-temps. $n1 $f1 et $n2 $f2 se tiennent à la gorge.',
          '😬 Pause : $n1 $f1 $t1Score-$t2Score $n2 $f2. La deuxième mi-temps s\'annonce chaude.',
          '🤔 $n1 $f1 et $n2 $f2 à égalité $t1Score partout. Les vestiaires vont parler.',
          '⏱️ Mi-temps engagée — $n1 $f1 $t1Score-$t2Score $n2 $f2. Loin d\'être plié.',
          '🎭 Accrochés à $t1Score-$t2Score — $n1 $f1 et $n2 $f2 se rendent coup pour coup.',
        ][seed];
      }
      return [
        '⏸️ Mi-temps : $winner $wFlag mène $wScore-$lScore. $loser $lFlag doit réagir.',
        '🔔 Pause ! $winner $wFlag en tête $wScore-$lScore face à $loser $lFlag.',
        '😤 $winner $wFlag $wScore-$lScore $loser $lFlag à la mi-temps. Ça tient ?',
        '⚽ $wScore-$lScore pour $winner $wFlag. $loser $lFlag revient des vestiaires dos au mur.',
        '🔥 $winner $wFlag domine $wScore-$lScore à la pause. $loser $lFlag en difficulty.',
        '😬 Mi-temps : $loser $lFlag est mené $lScore-$wScore par $winner $wFlag. Retournement possible ?',
        '💪 $winner $wFlag prend l\'avantage — $wScore-$lScore à la mi-temps contre $loser $lFlag.',
        '⏱️ La pause arrive avec $winner $wFlag devant — $wScore-$lScore. $loser $lFlag en mode survie.',
      ][seed];
    }

    // ── ESPAÑOL ───────────────────────────────────────────────────────────────
    if (lang == 'es') {
      if (isFinished) {
        if (isDraw && t1Score == 0) {
          return [
            '🥱 0-0. $n1 $f1 y $n2 $f2 no quisieron arriesgar. Nada de nada.',
            '😴 Sin goles, sin emociones — $n1 $f1 0-0 $n2 $f2. El portero podría haberse quedado en casa.',
            '🧱 Dos defensas infranqueables. $n1 $f1 0-0 $n2 $f2. Aburrimiento total.',
            '😐 $n1 $f1 y $n2 $f2 se despiden sin haberse dicho nada. 0-0.',
            '🏜️ Un desierto ofensivo. $n1 $f1 0-0 $n2 $f2. Los aficionados suspiran.',
            '🤷 0-0. Demasiada precaución entre $n1 $f1 y $n2 $f2.',
            '💤 Blanco y blanco. $n1 $f1 0-0 $n2 $f2. El partido que nunca arrancó.',
            '🔒 A cero. $n1 $f1 0-0 $n2 $f2. Las redes se quedaron frías.',
          ][seed];
        }
        if (isDraw) {
          return [
            '🤝 ¡Empate! $n1 $f1 $t1Score-$t2Score $n2 $f2. Un punto para cada uno.',
            '😤 Nadie gana, nadie pierde — $n1 $f1 $t1Score-$t2Score $n2 $f2. El fútbol es así.',
            '⚖️ $n1 $f1 y $n2 $f2 se reparten el botín. $t1Score-$t2Score.',
            '🔥 Partido intenso sin ganador — $n1 $f1 $t1Score-$t2Score $n2 $f2.',
            '😮‍💨 Tablas. $n1 $f1 $t1Score-$t2Score $n2 $f2. Un punto que puede valer mucho.',
            '🎭 Mismo marcador, distintas sensaciones — $n1 $f1 $t1Score-$t2Score $n2 $f2.',
            '🤔 ¿Para esto 90 minutos? $n1 $f1 $t1Score-$t2Score $n2 $f2. Empate decepcionante.',
            '💬 $n1 $f1 y $n2 $f2 no se pueden separar — $t1Score-$t2Score. ¿Próxima cita?',
          ][seed];
        }
        if (diff >= 4) {
          return [
            '💀 Naufragio total para $loser $lFlag — $winner $wFlag los hunde $wScore-$lScore.',
            '🔥 ¡$winner $wFlag en llamas! $wScore-$lScore, $loser $lFlag sin respuesta.',
            '😱 ¡Humillación! $winner $wFlag $wScore-$lScore $loser $lFlag. Sin discusión.',
            '⚡ $winner $wFlag arrasó con todo. $wScore-$lScore frente a $loser $lFlag.',
            '🚀 $winner $wFlag en modo galáctico — $wScore-$lScore, $loser $lFlag KO.',
            '💥 ¡Demolición! $winner $wFlag $wScore-$lScore $loser $lFlag. Sin piedad.',
            '🌊 $loser $lFlag ahogado en goles — $winner $wFlag $wScore-$lScore. Corrección.',
            '😤 $winner $wFlag aplastó a $loser $lFlag $wScore-$lScore. No hay debate.',
          ][seed];
        }
        if (diff == 3) {
          return [
            '💪 Gran dominio de $winner $wFlag — $wScore-$lScore ante $loser $lFlag.',
            '🎯 $winner $wFlag eficaz y sólido. $wScore-$lScore, $loser $lFlag sin solución.',
            '🔥 $winner $wFlag se escapa — $wScore-$lScore contra $loser $lFlag. Impresionante.',
            '😤 $loser $lFlag lo intentó, pero $winner $wFlag fue superior. $wScore-$lScore.',
            '⚡ Claro y contundente: $winner $wFlag $wScore-$lScore $loser $lFlag.',
            '🏆 $winner $wFlag deleita — $wScore-$lScore. $loser $lFlag vuelve con dudas.',
            '💥 $winner $wFlag dominador de principio a fin. $wScore-$lScore ante $loser $lFlag.',
            '🚀 $winner $wFlag demasiado para $loser $lFlag esta noche — $wScore-$lScore.',
          ][seed];
        }
        if (diff == 2) {
          return [
            '✅ $winner $wFlag gana con claridad $wScore-$lScore frente a $loser $lFlag.',
            '🎉 ¡Tres puntos para $winner $wFlag! $wScore-$lScore ante $loser $lFlag.',
            '💪 $winner $wFlag cumple: $wScore-$lScore contra $loser $lFlag.',
            '😤 $loser $lFlag lo intentó — $winner $wFlag fue más. $wScore-$lScore.',
            '🏆 Buen triunfo de $winner $wFlag sobre $loser $lFlag — $wScore-$lScore.',
            '⚡ $winner $wFlag cierra bien: $wScore-$lScore. $loser $lFlag deja escapar la oportunidad.',
            '🎯 $winner $wFlag no falla — $wScore-$lScore contra $loser $lFlag. Serio.',
            '✨ $winner $wFlag $wScore-$lScore $loser $lFlag. Limpio, eficaz, merecido.',
          ][seed];
        }
        return [
          '😅 Victoria corta pero valiosa — $winner $wFlag $wScore-$lScore $loser $lFlag.',
          '💨 $winner $wFlag roba los tres puntos $wScore-$lScore. $loser $lFlag cerca del empate.',
          '🫀 $winner $wFlag lo sufre pero lo gana — $wScore-$lScore ante $loser $lFlag. Corazón.',
          '😮‍💨 $wScore-$lScore — $winner $wFlag aguanta. $loser $lFlag se merecía más.',
          '🔒 $winner $wFlag resiste hasta el final — $wScore-$lScore contra $loser $lFlag.',
          '🎭 ¡Thriller! $winner $wFlag $wScore-$lScore $loser $lFlag. Justo pero suficiente.',
          '💪 Un gol de ventaja, tres puntos enteros para $winner $wFlag — $wScore-$lScore.',
          '⚽ $winner $wFlag no suelta — $wScore-$lScore ante $loser $lFlag. Batalla ganada.',
        ][seed];
      }

      // Descanso ES
      if (isDraw && t1Score == 0) {
        return [
          '😴 0-0 al descanso. $n1 $f1 y $n2 $f2 aún buscan el camino.',
          '🧱 Cero goles en el primer tempo — $n1 $f1 y $n2 $f2 se miden.',
          '🤷 Descanso: 0-0. Le falta chispa a esto entre $n1 $f1 y $n2 $f2.',
          '😬 Mitad: $n1 $f1 0-0 $n2 $f2. Alguien tiene que lanzarse.',
          '🏜️ Primera parte estéril — $n1 $f1 0-0 $n2 $f2. ¿Mejorará la second?',
          '🔒 0-0 al descanso. Las defenses mandan por ahora.',
          '💤 $n1 $f1 y $n2 $f2 a 0-0. Hay que despertarse.',
          '⏸️ Sin goles al descanso — $n1 $f1 0-0 $n2 $f2.',
        ][seed];
      }
      if (isDraw) {
        return [
          '⏸️ Descanso: $n1 $f1 $t1Score-$t2Score $n2 $f2. Todo por decidir.',
          '🔥 ¡Partido vivo! $n1 $f1 $t1Score-$t2Score $n2 $f2. La segunda parte promete.',
          '😤 Igualados al descanso — $n1 $f1 y $n2 $f2 $t1Score-$t2Score. ¿Quién cede?',
          '⚽ $t1Score-$t2Score al descanso. $n1 $f1 y $n2 $f2 van a degüello.',
          '😬 Pausa: $n1 $f1 $t1Score-$t2Score $n2 $f2. La segunda parte se calienta.',
          '🤔 $n1 $f1 y $n2 $f2 igualados $t1Score. Los vestiarios van a hablar.',
          '⏱️ Primera parte intensa — $n1 $f1 $t1Score-$t2Score $n2 $f2. Lejos de acabar.',
          '🎭 Enganchados a $t1Score-$t2Score — $n1 $f1 y $n2 $f2 se golpean sin parar.',
        ][seed];
      }
      return [
        '⏸️ Descanso: $winner $wFlag manda $wScore-$lScore. $loser $lFlag debe reaccionar.',
        '🔔 ¡Pausa! $winner $wFlag por delante $wScore-$lScore ante $loser $lFlag.',
        '😤 $winner $wFlag $wScore-$lScore $loser $lFlag al descanso. ¿Aguantará?',
        '⚽ $wScore-$lScore para $winner $wFlag. $loser $lFlag vuelve con la espalda contra la pared.',
        '🔥 $winner $wFlag domina $wScore-$lScore al descanso. $loser $lFlag en apuros.',
        '😬 Descanso: $loser $lFlag va perdiendo $lScore-$wScore ante $winner $wFlag. ¿Remontada?',
        '💪 $winner $wFlag toma ventaja — $wScore-$lScore al descanso frente a $loser $lFlag.',
        '⏱️ $winner $wFlag al frente — $wScore-$lScore. $loser $lFlag en modo supervivencia.',
      ][seed];
    }

    // ── ENGLISH fallback ──────────────────────────────────────────────────────
    if (isFinished) {
      if (isDraw && t1Score == 0) {
        return [
          '🥱 0-0. $n1 $f1 and $n2 $f2 played it safe. Very safe.',
          '😴 No goals, no thrills — $n1 $f1 0-0 $n2 $f2. The keepers barely broke a sweat.',
          '🧱 Two walls, zero holes — $n1 $f1 0-0 $n2 $f2. Football at its most stubborn.',
          '😐 $n1 $f1 and $n2 $f2 part without saying a word. 0-0.',
          '🏜️ Offensive wasteland. $n1 $f1 0-0 $n2 $f2. The fans are still waiting.',
          '🤷 0-0. Caution won tonight between $n1 $f1 and $n2 $f2.',
          '💤 Goalless. $n1 $f1 0-0 $n2 $f2. The match that never really started.',
          '🔒 Locked out at both ends. $n1 $f1 0-0 $n2 $f2. The nets stayed cold.',
        ][seed];
      }
      if (isDraw) {
        return [
          '🤝 $n1 $f1 and $n2 $f2 share the spoils — $t1Score-$t2Score. Honours even.',
          '😤 Neither side blinks — $n1 $f1 $t1Score-$t2Score $n2 $f2. Football can be harsh.',
          '⚖️ Perfect balance tonight: $n1 $f1 $t1Score-$t2Score $n2 $f2.',
          '🔥 End-to-end drama, no winner — $n1 $f1 $t1Score-$t2Score $n2 $f2.',
          '😮‍💨 One point each. $n1 $f1 $t1Score-$t2Score $n2 $f2. Could have been more.',
          '🎭 Same script, same score — $n1 $f1 and $n2 $f2 level at $t1Score-$t2Score.',
          '🤔 90 minutes for that? $n1 $f1 $t1Score-$t2Score $n2 $f2. Frustrating draw.',
          '💬 $n1 $f1 and $n2 $f2 inseparable again — $t1Score-$t2Score. See you next time.',
        ][seed];
      }
      if (diff >= 4) {
        return [
          '💀 Total collapse for $loser $lFlag — $winner $wFlag sinks them $wScore-$lScore.',
          '🔥 $winner $wFlag on fire! $wScore-$lScore, $loser $lFlag had no answers.',
          '😱 Humiliation. $winner $wFlag $wScore-$lScore $loser $lFlag. Absolutely ruthless.',
          '⚡ $winner $wFlag steamrolled everything. $wScore-$lScore vs $loser $lFlag.',
          '🚀 $winner $wFlag in another galaxy — $wScore-$lScore, $loser $lFlag shell-shocked.',
          '💥 Demolition job! $winner $wFlag $wScore-$lScore $loser $lFlag. No mercy.',
          '🌊 $loser $lFlag swamped by goals — $winner $wFlag $wScore-$lScore. A statement.',
          '😤 $winner $wFlag had it all their own way. $wScore-$lScore vs $loser $lFlag. Case closed.',
        ][seed];
      }
      if (diff == 3) {
        return [
          '💪 Commanding from $winner $wFlag — $wScore-$lScore over $loser $lFlag.',
          '🎯 $winner $wFlag clinical and controlled. $wScore-$lScore, $loser $lFlag outclassed.',
          '🔥 $winner $wFlag pulls clear — $wScore-$lScore against $loser $lFlag. Impressive.',
          '😤 $loser $lFlag tried hard. $winner $wFlag was simply better tonight. $wScore-$lScore.',
          '⚡ Clean and clinical: $winner $wFlag $wScore-$lScore $loser $lFlag.',
          '🏆 $winner $wFlag puts on a show — $wScore-$lScore! $loser $lFlag left with questions.',
          '💥 $winner $wFlag dominant start to finish. $wScore-$lScore vs $loser $lFlag.',
          '🚀 $winner $wFlag too good for $loser $lFlag tonight — $wScore-$lScore.',
        ][seed];
      }
      if (diff == 2) {
        return [
          '✅ $winner $wFlag wins it cleanly $wScore-$lScore against $loser $lFlag.',
          '🎉 Three points for $winner $wFlag! $wScore-$lScore over $loser $lFlag.',
          '💪 $winner $wFlag gets the job done — $wScore-$lScore vs $loser $lFlag.',
          '😤 $loser $lFlag pushed hard. $winner $wFlag pushed harder. $wScore-$lScore.',
          '🏆 Solid victory for $winner $wFlag over $loser $lFlag — $wScore-$lScore.',
          '⚡ $winner $wFlag closes it out: $wScore-$lScore. $loser $lFlag left frustrated.',
          '🎯 $winner $wFlag doesn\'t waver — $wScore-$lScore vs $loser $lFlag. Professional.',
          '✨ $winner $wFlag $wScore-$lScore $loser $lFlag. Clean, efficient, deserved.',
        ][seed];
      }
      // diff == 1
      return [
        '😅 Narrow but precious — $winner $wFlag $wScore-$lScore $loser $lFlag.',
        '💨 $winner $wFlag snatches three points $wScore-$lScore. $loser $lFlag so close.',
        '🫀 $winner $wFlag suffers but survives — $wScore-$lScore vs $loser $lFlag. Heart in mouth.',
        '😮‍💨 $wScore-$lScore — $winner $wFlag holds on. $loser $lFlag deserved more.',
        '🔒 $winner $wFlag digs in and wins — $wScore-$lScore against $loser $lFlag.',
        '🎭 What a finish! $winner $wFlag $wScore-$lScore $loser $lFlag. Barely, but beautifully.',
        '💪 One goal the difference, three points the reward. $winner $wFlag $wScore-$lScore.',
        '⚽ $winner $wFlag won\'t let go — $wScore-$lScore vs $loser $lFlag. Battle won.',
      ][seed];
    }

    // Half-time EN
    if (isDraw && t1Score == 0) {
      return [
        '😴 0-0 at the break. $n1 $f1 and $n2 $f2 still searching.',
        '🧱 No goals at half-time — $n1 $f1 and $n2 $f2 locked in.',
        '🤷 Half-time: 0-0. $n1 $f1 and $n2 $f2 need to wake up.',
        '😬 Break: $n1 $f1 0-0 $n2 $f2. Someone has to go for it.',
        '🏜️ Barren first half — $n1 $f1 0-0 $n2 $f2. Second half must be better.',
        '🔒 0-0 at the break. The defenses are winning so far.',
        '💤 $n1 $f1 and $n2 $f2 goalless. Time to step it up.',
        '⏸️ Nothing to show at half-time — $n1 $f1 0-0 $n2 $f2.',
      ][seed];
    }
    if (isDraw) {
      return [
        '⏸️ Half-time: $n1 $f1 $t1Score-$t2Score $n2 $f2. All still to play for.',
        '🔥 Lively first half! $n1 $f1 $t1Score-$t2Score $n2 $f2. Second half will be spicy.',
        '😤 Level at the break — $n1 $f1 and $n2 $f2 $t1Score-$t2Score. Who cracks?',
        '⚽ $t1Score-$t2Score at half-time. $n1 $f1 and $n2 $f2 going hammer and tongs.',
        '😬 Break: $n1 $f1 $t1Score-$t2Score $n2 $f2. Second half incoming.',
        '🤔 $n1 $f1 and $n2 $f2 level at $t1Score. The dressing rooms will be buzzing.',
        '⏱️ Intense first 45 — $n1 $f1 $t1Score-$t2Score $n2 $f2. Far from over.',
        '🎭 Locked at $t1Score-$t2Score — $n1 $f1 and $n2 $f2 trading blows.',
      ][seed];
    }
    return [
      '⏸️ Half-time: $winner $wFlag lead $wScore-$lScore. $loser $lFlag must respond.',
      '🔔 Break! $winner $wFlag ahead $wScore-$lScore. $loser $lFlag need a plan.',
      '😤 $winner $wFlag $wScore-$lScore $loser $lFlag at the break. Can they hold on?',
      '⚽ $wScore-$lScore to $winner $wFlag at half-time. $loser $lFlag with backs against the wall.',
      '🔥 $winner $wFlag dominating $wScore-$lScore. $loser $lFlag in real trouble.',
      '😬 $loser $lFlag trail $lScore-$wScore to $winner $wFlag. Massive second half needed.',
      '💪 $winner $wFlag in control — $wScore-$lScore at half-time vs $loser $lFlag.',
      '⏱️ $winner $wFlag in front — $wScore-$lScore. $loser $lFlag in survival mode.',
    ][seed];
  }
}
