import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/match.dart';
import '../app_constants.dart';
import 'firebase_service.dart';

class FriendScore {
  final String userId;
  final String username;
  final String emblem;
  final int points;
  final int rank;
  final bool isUser;

  FriendScore({
    required this.userId,
    required this.username,
    required this.emblem,
    required this.points,
    required this.rank,
    this.isUser = false,
  });
}

class FriendGroup {
  final String name;
  final String code;
  final List<FriendScore> members;
  final String? creatorId;

  FriendGroup({
    required this.name,
    required this.code,
    required this.members,
    this.creatorId,
  });
}

class PredictionService {
  static const String _predsKey = 'user_predictions';

  // ─── LOCAL STORAGE ─────────────────────────────────────────────────────────

  static Future<void> savePredictions(UserPredictions preds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_predsKey, json.encode(preds.toJson()));
  }

  static Future<UserPredictions> getPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_predsKey);
    if (data == null) return UserPredictions(matchPredictions: {});
    return UserPredictions.fromJson(json.decode(data));
  }

  // ─── GROUP MANAGEMENT ──────────────────────────────────────────────────────

  static Future<void> createCustomGroup(String groupName) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    final groupId = firestore.collection('groups').doc().id;
    
    // 1. Create the group
    await firestore.collection('groups').doc(groupId).set({
      'name': groupName,
      'creatorId': uid,
      'members': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Create the first smart invite (100 uses, 7 days)
    await _generateSmartInvite(groupId, uid);
  }

  static Future<String> _generateSmartInvite(String groupId, String creatorId) async {
    final firestore = FirebaseFirestore.instance;
    final token = const Uuid().v4().substring(0, 8);
    final inviteId = const Uuid().v4();
    
    await firestore.collection('invites').doc(inviteId).set({
      'groupId': groupId,
      'token': token,
      'creatorId': creatorId,
      'usesCount': 0,
      'maxUses': 100,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return '${inviteId}_$token';
  }

  static Future<String> getShareLink(String groupId) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    
    try {
      // Get all invites for this group to avoid composite index requirements
      final snapshot = await firestore.collection('invites')
          .where('groupId', isEqualTo: groupId)
          .limit(20)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final now = DateTime.now();
        // Sort in memory by createdAt descending
        final docs = snapshot.docs.toList()
          ..sort((a, b) {
            final tA = a.data()['createdAt'] as Timestamp? ?? Timestamp.now();
            final tB = b.data()['createdAt'] as Timestamp? ?? Timestamp.now();
            return tB.compareTo(tA);
          });

        for (final doc in docs) {
          final data = doc.data();
          final expiry = (data['expiresAt'] as Timestamp).toDate();
          final uses = data['usesCount'] as int;
          final max = data['maxUses'] as int;
          
          if (expiry.isAfter(now) && uses < max) {
            return '${doc.id}_${data['token']}';
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching invite: $e. Falling back to new invite generation.');
    }

    // Otherwise generate a fresh one
    return await _generateSmartInvite(groupId, uid);
  }

  static Future<void> editCustomGroup(String groupId, String newName) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).update({'name': newName});
  }

  static Future<void> deleteCustomGroup(String groupId) async {
    final firestore = FirebaseFirestore.instance;
    
    // Clean up associated invites
    final invites = await firestore.collection('invites').where('groupId', isEqualTo: groupId).get();
    final batch = firestore.batch();
    for (var doc in invites.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(firestore.collection('groups').doc(groupId));
    await batch.commit();
  }

  static Future<void> leaveCustomGroup(String groupId) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }

  static Future<bool> joinCustomGroup(String inviteCode) async {
    final parts = inviteCode.trim().split('_');
    if (parts.length != 2) return false;

    final inviteId = parts[0];
    final token = parts[1];

    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    
    try {
      final inviteRef = firestore.collection('invites').doc(inviteId);
      final inviteSnap = await inviteRef.get();

      if (!inviteSnap.exists) return false;
      final inviteData = inviteSnap.data()!;
      
      // 1. Validate token, expiry and uses
      if (inviteData['token'] != token) return false;
      if (inviteData['usesCount'] >= inviteData['maxUses']) return false;
      if ((inviteData['expiresAt'] as Timestamp).toDate().isBefore(DateTime.now())) return false;

      final groupId = inviteData['groupId'] as String;
      final groupRef = firestore.collection('groups').doc(groupId);
      final groupSnap = await groupRef.get();
      if (!groupSnap.exists) return false;
      
      final List<dynamic> members = groupSnap.data()!['members'] ?? [];
      if (members.contains(uid)) return true; // Already in

      // 2. Atomic Join: Update Invite Count + Update Group Members
      final batch = firestore.batch();
      batch.update(inviteRef, {'usesCount': FieldValue.increment(1)});
      batch.update(groupRef, {'members': FieldValue.arrayUnion([uid])});
      
      await batch.commit();

      // 3. Send notifications (Non-blocking)
      _sendJoinNotifications(groupId, members, uid);
      
      return true;
    } catch (e) {
      debugPrint('Join group error: $e');
      return false;
    }
  }

  static Future<void> _sendJoinNotifications(String groupId, List<dynamic> memberIds, String newMemberUid) async {
    final firestore = FirebaseFirestore.instance;
    try {
      final groupSnap = await firestore.collection('groups').doc(groupId).get();
      final groupName = groupSnap.data()?['name'] ?? 'Group';
      
      final userDoc = await firestore.collection('users').doc(newMemberUid).get();
      final username = userDoc.data()?['username'] ?? 'Someone';

      for (final memberId in memberIds) {
        if (memberId != newMemberUid) {
          firestore.collection('users').doc(memberId as String).collection('notifications').add({
            'title': 'New Group Member',
            'body': '$username joined $groupName!',
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
        }
      }
    } catch (_) {}
  }

  static Future<List<FriendGroup>> loadChallengeGroups(List<WorldCupMatch> matches) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    
    final groupsSnapshot = await firestore
        .collection('groups')
        .where('members', arrayContains: uid)
        .get();

    final List<FriendGroup> groups = [];

    for (final doc in groupsSnapshot.docs) {
      final data = doc.data();
      final name = data['name'] as String;
      final id = doc.id;
      final creatorId = data['creatorId'] as String? ?? '';

      final List<dynamic> memberIds = data['members'] ?? [];
      final List<FriendScore> members = [];

      for (final memberId in memberIds) {
        final isUser = memberId == uid;
        int points = 0;
        String mName = 'Unknown';
        String mEmblem = '👤';

        final userDoc = await firestore.collection('users').doc(memberId as String).get();
        if (userDoc.exists) {
          final uData = userDoc.data()!;
          points = uData['points'] ?? 0;
          mName = uData['username'] ?? 'Anonymous';
          mEmblem = uData['avatar'] ?? '👤';
        }

        members.add(FriendScore(
          userId: memberId as String,
          username: mName,
          emblem: mEmblem,
          points: points,
          rank: 0,
          isUser: isUser,
        ));
      }

      // Sort by points
      members.sort((a, b) => b.points.compareTo(a.points));
      
      // Update ranks
      for (int i = 0; i < members.length; i++) {
        members[i] = FriendScore(
          userId: members[i].userId,
          username: members[i].username,
          emblem: members[i].emblem,
          points: members[i].points,
          rank: i + 1,
          isUser: members[i].isUser,
        );
      }

      groups.add(
        FriendGroup(
          name: name,
          code: id,
          members: members,
          creatorId: creatorId,
        ),
      );
    }

    return groups;
  }

  // ─── STATS & CALCULATIONS ──────────────────────────────────────────────────

  static int calculateActiveStreak(UserPredictions preds, List<WorldCupMatch> allMatches) {
    final playedMatches = allMatches.where((m) => m.isPlayed).toList();
    playedMatches.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    int streak = 0;
    for (final match in playedMatches) {
      final pred = preds.matchPredictions[match.id];
      if (pred != null && match.isPlayed) {
        bool correct = false;
        if (match.t1Score == pred.t1Score && match.t2Score == pred.t2Score) {
          correct = true;
        } else if (match.winnerCode == pred.winnerCode) {
          correct = true;
        }
        
        if (correct) {
          streak++;
        } else {
          break;
        }
      } else {
        break;
      }
    }
    return streak;
  }

  static String generateSharePayload(String inviteId, String token) {
    return '${inviteId}_$token';
  }
}
