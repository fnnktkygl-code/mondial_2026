import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WCFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _uidKey = 'wc2026_firebase_uid';

  /// Get the current cached user ID or create one if it doesn't exist.
  static Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString(_uidKey);
    if (uid == null) {
      final randNum = DateTime.now().millisecondsSinceEpoch % 1000000;
      uid = 'user_$randNum';
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
  }) async {
    final uid = await getOrCreateUserId();

    final docRef = _firestore.collection('users').doc(uid);
    await docRef.set({
      'username': username,
      'supportedTeam': supportedTeam,
      'points': points,
      'streak': streak,
      'guruCount': guruCount,
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
