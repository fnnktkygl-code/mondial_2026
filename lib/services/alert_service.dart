import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/match.dart';

class AlertService {
  static const String _alertsKey = 'wc2026_alerts';

  /// Helper to ensure we have the required permissions on Android 12+
  /// This prevents the app from crashing when scheduling exact alarms.
  static Future<void> _ensurePermissions() async {
    if (!kIsWeb && Platform.isAndroid) {
      // Request standard notification permission (Required for Android 13+)
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // Request exact alarm permission (Required for Android 12+)
      // Without this, scheduling a future match alert will crash the local notifications plugin.
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  /// Load all alerts from SharedPreferences. Returns a Map of matchId -> alertType.
  static Future<Map<String, String>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_alertsKey);
    if (jsonStr == null) return {};

    try {
      final Map<String, dynamic> decoded =
      jsonDecode(jsonStr) as Map<String, dynamic>;
      final Map<String, String> alerts = decoded.map(
            (key, value) => MapEntry(key, value.toString()),
      );

      // Migration logic for old group match IDs
      bool migrated = false;
      final keys = List<String>.from(alerts.keys);
      for (final key in keys) {
        if (key.startsWith('m')) {
          final idNum = int.tryParse(key.substring(1));
          if (idNum != null && idNum <= 72) {
            final val = alerts.remove(key);
            if (val != null) {
              alerts['g_$key'] = val;
              migrated = true;
            }
          }
        }
      }
      if (migrated) {
        await prefs.setString(_alertsKey, jsonEncode(alerts));
      }
      return alerts;
    } catch (_) {
      return {};
    }
  }

  /// Save or remove a match alert.
  static Future<Map<String, String>> saveAlert(
      String matchId,
      String alertType,
      ) async {
    // Ensure permissions are granted before saving an active alert
    if (alertType != 'none') {
      await _ensurePermissions();
    }

    final prefs = await SharedPreferences.getInstance();
    final alerts = await loadAlerts();

    alerts[matchId] = alertType;

    final jsonStr = jsonEncode(alerts);
    await prefs.setString(_alertsKey, jsonStr);
    return alerts;
  }

  /// Automatically set 1hour alerts for a team's matches if no alert exists.
  static Future<Map<String, String>> activateAlertsForTeam(
      String teamCode,
      List<WorldCupMatch> matches,
      ) async {
    // Ensure permissions are granted before mass-activating alerts
    await _ensurePermissions();

    final prefs = await SharedPreferences.getInstance();
    final alerts = await loadAlerts();

    bool changed = false;
    final lowerTeamCode = teamCode.toLowerCase();

    for (final match in matches) {
      if (match.t1.toLowerCase() == lowerTeamCode ||
          match.t2.toLowerCase() == lowerTeamCode) {
        if (!alerts.containsKey(match.id)) {
          alerts[match.id] = '1h'; // Changed to match your standardized '1h' format
          changed = true;
        }
      }
    }

    if (changed) {
      final jsonStr = jsonEncode(alerts);
      await prefs.setString(_alertsKey, jsonStr);
    }
    return alerts;
  }
}