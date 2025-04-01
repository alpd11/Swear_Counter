import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 USER MANAGEMENT
  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> createUserIfNotExists(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        username: user.displayName ?? user.email!.split('@')[0],
        createdAt: Timestamp.now(),
      );
      await saveUser(newUser);
    }
  }

  Future<List<Map<String, dynamic>>> searchUsersByUsername(String username) async {
    final result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return result.docs
        .map((doc) => {
              'uid': doc.id,
              'username': doc['username'],
              'email': doc['email'],
              'avatarUrl': doc['avatarUrl'],
            })
        .toList();
  }

  // 👥 FRIEND MANAGEMENT
  Future<List<FriendModel>> getFriends() async {
    final snapshot = await _firestore.collection("friends").get();
    return snapshot.docs.map((doc) => FriendModel.fromMap(doc.data())).toList();
  }

  Future<void> addFriend(FriendModel friend) async {
    await _firestore.collection("friends").doc(friend.uid).set(friend.toMap());
  }

  Future<void> deleteFriend(String uid) async {
    await _firestore.collection("friends").doc(uid).delete();
  }

  Future<void> updateFriend(FriendModel friend) async {
    await _firestore.collection("friends").doc(friend.uid).update(friend.toMap());
  }

  // 📩 FRIEND REQUESTS
  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    await _firestore
        .collection('friend_requests')
        .doc(toUid)
        .collection('incoming')
        .doc(fromUid)
        .set({
      'from': fromUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getIncomingRequests(String uid) async {
    final snapshot = await _firestore
        .collection('friend_requests')
        .doc(uid)
        .collection('incoming')
        .get();

    List<Map<String, dynamic>> results = [];
    for (var doc in snapshot.docs) {
      final fromUser = await fetchUser(doc.id);
      if (fromUser != null) {
        results.add({
          'uid': doc.id,
          'username': fromUser.username,
          'email': fromUser.email,
          'avatarUrl': fromUser.avatarUrl,
        });
      }
    }
    return results;
  }

  Future<void> approveFriendRequest(String myUid, String requesterUid, String requesterName, {String? avatarUrl}) async {
    final newFriend = FriendModel(
      uid: requesterUid,
      name: requesterName,
      swearCount: 0,
      avatarUrl: avatarUrl,
    );
    await addFriend(newFriend);

    await _firestore
        .collection('friend_requests')
        .doc(myUid)
        .collection('incoming')
        .doc(requesterUid)
        .delete();
  }
}
