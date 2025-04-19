import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

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
    try {
      final currentUid = currentUserId;
      if (currentUid == null) return [];
      
      // Firebase doesn't support case-insensitive search directly
      // Simple approach: get docs where username starts with the search term
      final snapshot = await _firestore
          .collection('users')
          .orderBy('username')
          .startAt([username])
          .endAt([username + '\uf8ff']) // Add Unicode suffix to match "starts with"
          .where('uid', isNotEqualTo: currentUid)
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error searching users by username: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> searchUsersByEmail(String email) async {
    try {
      final currentUid = currentUserId;
      if (currentUid == null) return [];
      
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('uid', isNotEqualTo: currentUid) // Don't include current user
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error searching users by email: $e');
      return [];
    }
  }

  // Create new user document in Firestore
  Future<void> createNewUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  // Get user document
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // 👥 FRIEND MANAGEMENT
  Future<List<FriendModel>> getFriends() async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    try {
      final friendsDoc = await _firestore
          .collection('friends')
          .doc(userId)
          .get();
          
      if (!friendsDoc.exists) return [];
      
      final friendIds = List<String>.from(friendsDoc.data()?['friendIds'] ?? []);
      
      if (friendIds.isEmpty) return [];
      
      // Get user documents for all friends
      final friendDocs = await _firestore
          .collection('users')
          .where('uid', whereIn: friendIds)
          .get();
          
      return friendDocs.docs.map((doc) {
        final data = doc.data();
        return FriendModel(
          uid: doc.id,
          name: data['username'] ?? 'Unknown',
          swearCount: data['swearCount'] ?? 0,
          avatarUrl: data['avatarUrl'],
        );
      }).toList();
    } catch (e) {
      print('Error getting friends list: $e');
      return [];
    }
  }

  Future<void> addFriend(FriendModel friend) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    await _firestore
        .collection("users")
        .doc(currentUser.uid)
        .collection("friends")
        .doc(friend.uid)
        .set(friend.toMap());
        
    // Also add the current user to their friend's list
    final currentUserData = await fetchUser(currentUser.uid);
    if (currentUserData != null) {
      final reverseFriend = FriendModel(
        uid: currentUser.uid,
        name: currentUserData.username,
        swearCount: 0, // They'll see your swear count
        avatarUrl: currentUserData.avatarUrl,
      );
      
      await _firestore
          .collection("users")
          .doc(friend.uid)
          .collection("friends")
          .doc(currentUser.uid)
          .set(reverseFriend.toMap());
    }
  }

  Future<void> deleteFriend(String friendUid) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');
    
    // Remove from both users' friend lists
    await _firestore.collection('friends').doc(userId).update({
      'friendIds': FieldValue.arrayRemove([friendUid]),
    });
    
    await _firestore.collection('friends').doc(friendUid).update({
      'friendIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> updateFriend(FriendModel friend) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    await _firestore
        .collection("users")
        .doc(currentUser.uid)
        .collection("friends")
        .doc(friend.uid)
        .update(friend.toMap());
  }

  // 📩 FRIEND REQUESTS
  Future<void> sendFriendRequest(String recipientUid) async {
    final senderUid = currentUserId;
    if (senderUid == null) throw Exception('User not logged in');
    
    // Check if already friends
    final friendsDoc = await _firestore.collection('friends').doc(senderUid).get();
    if (friendsDoc.exists) {
      final friendIds = List<String>.from(friendsDoc.data()?['friendIds'] ?? []);
      if (friendIds.contains(recipientUid)) {
        throw Exception('Already friends with this user');
      }
    }
    
    // Check if request already sent
    final sentRequestsDoc = await _firestore
        .collection('friendRequests')
        .doc(senderUid)
        .collection('sent')
        .doc(recipientUid)
        .get();
        
    if (sentRequestsDoc.exists) {
      throw Exception('Friend request already sent');
    }
    
    // Get sender user data to include in request
    final senderDoc = await _firestore.collection('users').doc(senderUid).get();
    if (!senderDoc.exists) throw Exception('Sender profile not found');
    
    final senderData = senderDoc.data() as Map<String, dynamic>;
    
    // Add to sender's sent requests
    await _firestore
        .collection('friendRequests')
        .doc(senderUid)
        .collection('sent')
        .doc(recipientUid)
        .set({
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
    
    // Add to recipient's incoming requests
    await _firestore
        .collection('friendRequests')
        .doc(recipientUid)
        .collection('received')
        .doc(senderUid)
        .set({
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'uid': senderUid,
          'username': senderData['username'],
          'email': senderData['email'],
          'avatarUrl': senderData['avatarUrl'],
        });
  }

  Future<List<Map<String, dynamic>>> getIncomingFriendRequests() async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .doc(userId)
          .collection('received')
          .where('status', isEqualTo: 'pending')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'username': data['username'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'avatarUrl': data['avatarUrl'],
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('Error getting friend requests: $e');
      return [];
    }
  }

  Future<void> acceptFriendRequest(String senderUid) async {
    final recipientUid = currentUserId;
    if (recipientUid == null) throw Exception('User not logged in');
    
    // Update request status
    await _firestore
        .collection('friendRequests')
        .doc(recipientUid)
        .collection('received')
        .doc(senderUid)
        .update({'status': 'accepted'});
    
    await _firestore
        .collection('friendRequests')
        .doc(senderUid)
        .collection('sent')
        .doc(recipientUid)
        .update({'status': 'accepted'});
    
    // Add to friends collections (for both users)
    await _firestore.collection('friends').doc(recipientUid).set({
      'friendIds': FieldValue.arrayUnion([senderUid]),
    }, SetOptions(merge: true));
    
    await _firestore.collection('friends').doc(senderUid).set({
      'friendIds': FieldValue.arrayUnion([recipientUid]),
    }, SetOptions(merge: true));
  }
  
  Future<void> rejectFriendRequest(String senderUid) async {
    final recipientUid = currentUserId;
    if (recipientUid == null) throw Exception('User not logged in');
    
    // Delete request documents
    await _firestore
        .collection('friendRequests')
        .doc(recipientUid)
        .collection('received')
        .doc(senderUid)
        .delete();
    
    await _firestore
        .collection('friendRequests')
        .doc(senderUid)
        .collection('sent')
        .doc(recipientUid)
        .delete();
  }
  
  // Update user's swear count
  Future<void> updateSwearCount(int count) async {
    final userId = currentUserId;
    if (userId == null) return;
    
    try {
      await _firestore.collection('users').doc(userId).update({
        'swearCount': count,
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating swear count: $e');
      // If document doesn't exist, create it with basic info
      final user = _auth.currentUser;
      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          username: user.displayName ?? 'User',
          createdAt: Timestamp.now(),
          avatarUrl: user.photoURL,
        );
        await createNewUser(userModel);
      }
    }
  }
}
