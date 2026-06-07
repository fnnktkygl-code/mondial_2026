import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WCFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _uidKey = 'wc2026_firebase_uid';

  /// Get the current cached user ID or create one if it doesn't exist.
  static Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString(_uidKey);

    if (_auth.currentUser == null) {
      try {
        final credential = await _auth.signInAnonymously();
        if (credential.user != null) {
          uid = credential.user!.uid;
          await prefs.setString(_uidKey, uid);
        }
      } catch (_) {
        if (uid == null) {
          uid = _firestore.collection('users').doc().id;
          await prefs.setString(_uidKey, uid);
        }
      }
    } else {
      uid = _auth.currentUser!.uid;
      await prefs.setString(_uidKey, uid);
    }

    if (uid == null) {
      uid = _firestore.collection('users').doc().id;
      await prefs.setString(_uidKey, uid);
    }

    return uid;
  }

  /// Sync the user profile to Firestore.
  static Future<void> syncUserProfile({
    required String username,
    String? supportedTeam,
    required int points,
    int streak = 0,
    int guruCount = 0,
    String avatar = '',
  }) async {
    final uid = await getOrCreateUserId();

    final docRef = _firestore.collection('users').doc(uid);
    await docRef.set({
      'username': username,
      'supportedTeam': supportedTeam,
      'points': points,
      'streak': streak,
      'guruCount': guruCount,
      'avatar': avatar,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Fetch leaderboard stream.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboardStream() {
    return _firestore
        .collection('users')
        .orderBy('points', descending: true)
        .limit(50)
        .snapshots();
  }
}