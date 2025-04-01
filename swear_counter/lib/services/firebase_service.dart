import 'package:cloud_firestore/cloud_firestore.dart';
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
}