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
    bool isHidden = false,
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
      'isHidden': isHidden,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Delete the user profile from Firestore.
  static Future<void> deleteUserProfile() async {
    final uid = await getOrCreateUserId();

    // Attempt to delete user doc and its subcollections (simplified clean up)
    try {
      final sub = await _firestore.collection('users').doc(uid).collection('notifications').get();
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
}