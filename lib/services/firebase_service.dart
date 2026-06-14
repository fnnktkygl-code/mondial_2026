import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'prediction_service.dart';
import '../models/match.dart';
import '../app_constants.dart';

class WCFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _uidKey = 'wc2026_firebase_uid';

  /// Get the current persistent user ID or create one if it doesn't exist.
  /// Uses Firebase Anonymous Auth which persists across reinstalls on the same device.
  static Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. If we are already signed in to Firebase, return that UID
    if (_auth.currentUser != null) {
      final uid = _auth.currentUser!.uid;
      await prefs.setString(_uidKey, uid);
      return uid;
    }

    // 2. Try to sign in anonymously (Firebase restores the same ID on the same device)
    try {
      final credential = await _auth.signInAnonymously().timeout(const Duration(seconds: 10));
      if (credential.user != null) {
        final uid = credential.user!.uid;
        await prefs.setString(_uidKey, uid);
        return uid;
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
    }

    // 3. Fallback to SharedPreferences only if Auth fails
    String? localUid = prefs.getString(_uidKey);
    if (localUid == null) {
      localUid = _firestore.collection('users').doc().id;
      await prefs.setString(_uidKey, localUid);
    }
    return localUid;
  }

  /// Sync the user profile to Firestore.
  static Future<void> syncUserProfile({
    String? username,
    String? supportedTeam,
    int? points,
    int streak = 0,
    int guruCount = 0,
    String avatar = '',
    bool isHidden = false,
  }) async {
    final uid = await getOrCreateUserId();
    final deviceId = await _getStableDeviceId();

    final docRef = _firestore.collection('users').doc(uid);
    final Map<String, dynamic> data = {
      'streak': streak,
      'guruCount': guruCount,
      'avatar': avatar,
      'isHidden': isHidden,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (deviceId.isNotEmpty) {
      data['deviceId'] = deviceId;
    }

    if (username != null) data['username'] = username;
    if (supportedTeam != null) data['supportedTeam'] = supportedTeam;
    if (points != null) data['points'] = points;

    await docRef.set(data, SetOptions(merge: true));
  }

  /// Delete the user profile from Firestore.
  static Future<void> deleteUserProfile() async {
    final uid = await getOrCreateUserId();

    // Attempt to delete user doc and its subcollections (simplified clean up)
    try {
      final sub = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get();
      for (final doc in sub.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('users').doc(uid).delete();
    } catch (_) {}

    // Attempt to delete user from Firebase Auth
    if (_auth.currentUser != null) {
      try {
        await _auth.currentUser!.delete();
      } catch (_) {}
    }

    // Clear local prefs related to ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uidKey);
  }

  /// Set the profile visibility
  static Future<void> setProfileVisibility(bool isHidden) async {
    final uid = await getOrCreateUserId();
    await _firestore.collection('users').doc(uid).set({
      'isHidden': isHidden,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get the profile visibility
  static Future<bool> getProfileVisibility() async {
    final uid = await getOrCreateUserId();
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['isHidden'] as bool? ?? false;
    }
    return false;
  }

  /// Fetch leaderboard stream.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboardStream() {
    return _firestore
        .collection('users')
        .orderBy('points', descending: true)
        .limit(100) // Increase limit since we filter client side
        .snapshots();
  }

  static Future<String> _getStableDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        return '';
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // SSAID - stable across reinstalls
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? ''; // stable across reinstalls
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.systemGUID ?? ''; // stable
      }
    } catch (e) {
      debugPrint("Error getting stable device ID: $e");
    }
    return '';
  }

  /// Attempts to restore user predictions and profile from a previous installation
  /// by querying Firestore for a document matching the device ID.
  static Future<bool> restoreProfileFromDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    // Only attempt recovery if we haven't done it for this installation
    if (prefs.getBool('wc2026_device_restored') == true) {
      return false;
    }

    final deviceId = await _getStableDeviceId();
    if (deviceId.isEmpty) {
      // Mark as restored so we don't keep trying on web
      await prefs.setBool('wc2026_device_restored', true);
      return false;
    }

    try {
      final query = await _firestore
          .collection('users')
          .where('deviceId', isEqualTo: deviceId)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final uid = await getOrCreateUserId();
        
        // If the found document is our current one, just mark as restored
        if (doc.id == uid) {
          await prefs.setBool('wc2026_device_restored', true);
          return true;
        }

        debugPrint("RECOVERY: Found previous installation profile: ${doc.id}");
        
        // 1. Restore Profile details locally
        final username = data['username'] as String? ?? '';
        final supportedTeam = data['supportedTeam'] as String?;
        final avatar = data['avatar'] as String? ?? '';
        final points = data['points'] as int? ?? 0;
        final streak = data['streak'] as int? ?? 0;
        final guruCount = data['guruCount'] as int? ?? 0;
        final isHidden = data['isHidden'] as bool? ?? false;

        // 2. Restore Predictions
        final remotePreds = data['predictions'] as Map<String, dynamic>? ?? {};
        final Map<String, MatchPrediction> predsMap = {};
        remotePreds.forEach((key, val) {
          try {
            predsMap[key] = MatchPrediction.fromJson(Map<String, dynamic>.from(val));
          } catch (e) {
            debugPrint("RECOVERY: Error parsing prediction $key: $e");
          }
        });

        final championCode = data['championCode'] as String?;
        final goldenBootPlayer = data['goldenBootPlayer'] as String?;

        // Save locally in SharedPreferences for PredictionData
        final PredictionData restoredPredData = PredictionData(
          username: username,
          avatar: avatar,
          supportedTeam: supportedTeam,
          championCode: championCode,
          goldenBootPlayer: goldenBootPlayer,
          preds: predsMap,
        );

        // Save local predictions
        final jsonStr = jsonEncode(restoredPredData.toJson());
        await prefs.setString(kPredictionsKey, jsonStr);

        // Sync user profile to Firestore (updates users/{new_uid})
        await syncUserProfile(
          username: username,
          supportedTeam: supportedTeam,
          points: points,
          streak: streak,
          guruCount: guruCount,
          avatar: avatar,
          isHidden: isHidden,
        );

        // Write the predictions sub-object to Firestore users/{new_uid} too
        await _firestore.collection('users').doc(uid).set({
          'predictions': remotePreds,
          'championCode': championCode,
          'goldenBootPlayer': goldenBootPlayer,
        }, SetOptions(merge: true));

        // Mark as restored successfully
        await prefs.setBool('wc2026_device_restored', true);
        debugPrint("RECOVERY: Successfully restored predictions and profile for user $uid");
        return true;
      }
    } catch (e) {
      debugPrint("RECOVERY ERROR: $e");
    }

    // If no document found, mark as done so we don't query Firestore on every startup
    await prefs.setBool('wc2026_device_restored', true);
    return false;
  }
}
