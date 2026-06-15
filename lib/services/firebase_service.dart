import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'prediction_service.dart';
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
    String? pronouns,
    List<Map<String, dynamic>>? pronounsHistory,
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
    if (pronouns != null) data['pronouns'] = pronouns;
    if (pronounsHistory != null) data['pronounsHistory'] = pronounsHistory;

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

  /// Fetches a user's full profile and predictions by UID.
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
    return null;
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
    
    final bool alreadyRestored = prefs.getBool('wc2026_device_restored') == true;
    
    // We only skip if already restored AND the local profile is NOT empty.
    // If the local profile IS empty (e.g. no predictions, no username, no team),
    // we should still try to restore it to heal the empty profile state.
    if (alreadyRestored) {
      final localPredsJson = prefs.getString(kPredictionsKey);
      bool isLocalEmpty = true;
      if (localPredsJson != null) {
        try {
          final localData = PredictionData.fromJson(jsonDecode(localPredsJson));
          final hasUsername = localData.username.isNotEmpty &&
              localData.username != 'Tactitien' &&
              localData.username != 'User';
          final hasPreds = localData.matchPredictions.isNotEmpty;
          final hasTeam = localData.supportedTeam != null && localData.supportedTeam!.isNotEmpty;
          final hasChamp = localData.championCode != null && localData.championCode!.isNotEmpty;
          if (hasUsername || hasPreds || hasTeam || hasChamp) {
            isLocalEmpty = false;
          }
        } catch (_) {}
      }
      
      if (!isLocalEmpty) {
        return false;
      }
    }

    final deviceId = await _getStableDeviceId();
    if (deviceId.isEmpty) {
      // Mark as restored so we don't keep trying on web
      await prefs.setBool('wc2026_device_restored', true);
      return false;
    }

    try {
      // Fetch all documents matching this deviceId.
      // We don't limit(1) or orderBy(updatedAt) because we want to perform client-side ranking.
      final query = await _firestore
          .collection('users')
          .where('deviceId', isEqualTo: deviceId)
          .get()
          .timeout(const Duration(seconds: 8));

      if (query.docs.isNotEmpty) {
        final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(query.docs);
        
        // Sort documents client-side to find the "best" profile.
        docs.sort((a, b) {
          final aData = a.data();
          final bData = b.data();

          // 1. Rank by predictions count
          final aPreds = aData['predictions'] as Map<String, dynamic>? ?? {};
          final bPreds = bData['predictions'] as Map<String, dynamic>? ?? {};
          if (aPreds.length != bPreds.length) {
            return bPreds.length.compareTo(aPreds.length); // Descending (more is better)
          }

          // 2. Rank by points
          final aPoints = aData['points'] as int? ?? 0;
          final bPoints = bData['points'] as int? ?? 0;
          if (aPoints != bPoints) {
            return bPoints.compareTo(aPoints); // Descending (more is better)
          }

          // 3. Rank by presence of username (non-empty & not default)
          final aUser = aData['username'] as String? ?? '';
          final bUser = bData['username'] as String? ?? '';
          final aHasRealUser = aUser.isNotEmpty && aUser != 'User' && aUser != 'Tactitien';
          final bHasRealUser = bUser.isNotEmpty && bUser != 'User' && bUser != 'Tactitien';
          if (aHasRealUser && !bHasRealUser) return -1;
          if (!aHasRealUser && bHasRealUser) return 1;

          // 4. Rank by presence of supported team
          final aTeam = aData['supportedTeam'] as String? ?? '';
          final bTeam = bData['supportedTeam'] as String? ?? '';
          if (aTeam.isNotEmpty && bTeam.isEmpty) return -1;
          if (aTeam.isEmpty && bTeam.isNotEmpty) return 1;

          // 5. Fallback to updatedAt timestamp (most recent is better)
          final aTime = aData['updatedAt'] as Timestamp?;
          final bTime = bData['updatedAt'] as Timestamp?;
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime); // Descending (most recent is better)
          }
          if (aTime != null) return -1;
          if (bTime != null) return 1;

          return 0;
        });

        final doc = docs.first;
        final data = doc.data();
        final uid = await getOrCreateUserId();
        
        // If the best found document is our current one, just mark as restored
        if (doc.id == uid) {
          await prefs.setBool('wc2026_device_restored', true);
          return true;
        }

        debugPrint("RECOVERY: Found previous installation profile: ${doc.id} (matching deviceId: $deviceId)");
        
        // 1. Restore Profile details locally
        final username = data['username'] as String? ?? '';
        final supportedTeam = data['supportedTeam'] as String?;
        final avatar = data['avatar'] as String? ?? '';
        final points = data['points'] as int? ?? 0;
        final streak = data['streak'] as int? ?? 0;
        final guruCount = data['guruCount'] as int? ?? 0;
        final isHidden = data['isHidden'] as bool? ?? false;
        final pronouns = data['pronouns'] as String?;
        final rawPronounsHistory = data['pronounsHistory'] as List<dynamic>?;
        final List<PronounsHistoryItem> pronounsHistory = [];
        if (rawPronounsHistory != null) {
          for (final item in rawPronounsHistory) {
            try {
              pronounsHistory.add(PronounsHistoryItem.fromJson(Map<String, dynamic>.from(item as Map)));
            } catch (e) {
              debugPrint("RECOVERY: Error parsing pronouns history item: $e");
            }
          }
        }

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
          pronouns: pronouns,
          pronounsHistory: pronounsHistory,
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
          pronouns: pronouns,
          pronounsHistory: rawPronounsHistory != null
              ? List<Map<String, dynamic>>.from(rawPronounsHistory.map((e) => Map<String, dynamic>.from(e as Map)))
              : null,
        );

        // Write the predictions sub-object to Firestore users/{new_uid} too
        await _firestore.collection('users').doc(uid).set({
          'predictions': remotePreds,
          'championCode': championCode,
          'goldenBootPlayer': goldenBootPlayer,
        }, SetOptions(merge: true));

        // 3. Find and copy group memberships from old UID to new UID
        try {
          final oldUid = doc.id;
          final groupsSnapshot = await _firestore
              .collection('groups')
              .where('members', arrayContains: oldUid)
              .get()
              .timeout(const Duration(seconds: 8));
          
          for (final groupDoc in groupsSnapshot.docs) {
            await groupDoc.reference.update({
              'members': FieldValue.arrayUnion([uid])
            });
            // If the old user was the creator, also update creatorId to new UID
            final creatorId = groupDoc.data()['creatorId'] as String?;
            if (creatorId == oldUid) {
              await groupDoc.reference.update({
                'creatorId': uid
              });
            }
            debugPrint("RECOVERY: Copied group membership for group ${groupDoc.id} from $oldUid to $uid");
          }
        } catch (groupError) {
          debugPrint("RECOVERY: Error copying group memberships: $groupError");
        }

        // 4. Clean up: Delete the old profile document and its notifications to avoid duplicates on the leaderboard
        try {
          final oldUid = doc.id;
          final sub = await _firestore
              .collection('users')
              .doc(oldUid)
              .collection('notifications')
              .get();
          for (final notificationDoc in sub.docs) {
            await notificationDoc.reference.delete();
          }
          await _firestore.collection('users').doc(oldUid).delete();
          debugPrint("RECOVERY: Deleted old profile document $oldUid to avoid duplicates.");
        } catch (cleanupError) {
          debugPrint("RECOVERY: Error cleaning up old profile document: $cleanupError");
        }

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
