import 'dart:math';
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
    try {
      print('⚠️ Attempting to create/update user in Firestore: ${user.uid}, email: ${user.email}');
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        // Create new user if they don't exist yet
        print('📝 User does not exist in Firestore. Creating new user...');
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          createdAt: Timestamp.now(),
          avatarUrl: user.photoURL,
        );
        await saveUser(newUser);
        print('✅ New user created in Firestore: ${user.uid}');
      } else {
        // User exists, update their profile info in case it changed
        print('🔄 User exists in Firestore. Updating profile if needed...');
        final userData = doc.data()!;
        final updates = <String, dynamic>{
          'lastLoginAt': Timestamp.now(),
        };
        
        // Update email if it changed
        if (user.email != null && user.email != userData['email']) {
          updates['email'] = user.email;
          print('📧 Updating email from ${userData['email']} to ${user.email}');
        }
        
        // Update display name if it changed
        if (user.displayName != null && user.displayName != userData['username']) {
          updates['username'] = user.displayName;
          print('👤 Updating username from ${userData['username']} to ${user.displayName}');
        }
        
        // Update avatar URL if it changed
        if (user.photoURL != null && user.photoURL != userData['avatarUrl']) {
          updates['avatarUrl'] = user.photoURL;
          print('🖼️ Updating avatar URL');
        }
        
        // Apply updates if there are any
        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update(updates);
          print('✅ Updated existing user in Firestore: ${user.uid}');
        } else {
          print('ℹ️ No updates needed for user: ${user.uid}');
        }
      }
    } catch (e) {
      print('❌ ERROR in createUserIfNotExists: $e');
      // Try to save basic user info as a fallback
      try {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          createdAt: Timestamp.now(),
          avatarUrl: user.photoURL,
        );
        
        print('🔄 Attempting fallback save for user: ${user.uid}');
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        print('✅ Fallback save successful for user: ${user.uid}');
      } catch (fallbackError) {
        print('❌❌ CRITICAL: Failed fallback save: $fallbackError');
      }
    }
  }

  Future<Map<String, dynamic>> searchUsersByUsername(String username, {DocumentSnapshot? lastDocument}) async {
    try {
      print('🔍 Searching for user by username: $username');
      
      final currentUid = currentUserId;
      if (currentUid == null) {
        print('⚠️ No current user logged in during username search');
        return {'users': [], 'hasMore': false};
      }
      
      // Normalize the search term
      final lowercaseUsername = username.toLowerCase().trim();
      print('🔤 Normalized search username: $lowercaseUsername');
      
      // Get all users and filter manually for better search
      print('📂 Fetching all users from Firestore');
      final snapshot = await _firestore
          .collection('users')
          .get();
      
      print('📊 Total users in database: ${snapshot.docs.length}');
      
      // Filter results manually for case-insensitive and contains search
      final List<DocumentSnapshot> matchingDocs = snapshot.docs
          .where((doc) => doc.id != currentUid) // Exclude current user 
          .where((doc) {
            final userName = (doc.data() as Map<String, dynamic>)['username'] ?? '';
            final match = userName.toString().toLowerCase().contains(lowercaseUsername);
            print('👤 Checking user ${doc.id}: username=$userName, match=$match');
            return match;
          })
          .toList();
      
      print('🔢 Found ${matchingDocs.length} matching users');
      
      // Handle pagination if needed
      List<DocumentSnapshot> paginatedDocs = matchingDocs;
      if (lastDocument != null) {
        print('📄 Pagination requested, last document ID: ${lastDocument.id}');
        final lastDocIndex = matchingDocs.indexWhere((doc) => doc.id == lastDocument.id);
        if (lastDocIndex != -1 && lastDocIndex < matchingDocs.length - 1) {
          paginatedDocs = matchingDocs.sublist(lastDocIndex + 1, 
              min(lastDocIndex + 11, matchingDocs.length));
          print('📑 Returning documents ${lastDocIndex+1} to ${min(lastDocIndex + 11, matchingDocs.length)}');
        } else {
          paginatedDocs = [];
          print('📭 No more documents after the last one');
        }
      } else {
        paginatedDocs = matchingDocs.take(10).toList();
        print('1️⃣ Taking first 10 documents of ${matchingDocs.length}');
      }
      
      if (paginatedDocs.isNotEmpty) {
        print('✓ First matching user: ${(paginatedDocs.first.data() as Map<String, dynamic>)['username'] ?? 'No username'}');
      }
      
      return {
        'users': paginatedDocs.map((doc) => (doc.data() as Map<String, dynamic>)).toList(),
        'hasMore': lastDocument == null ? matchingDocs.length > 10 : 
            matchingDocs.length > matchingDocs.indexWhere((doc) => doc.id == lastDocument.id) + 11,
        'lastDocument': paginatedDocs.isNotEmpty ? paginatedDocs.last : null,
      };
    } catch (e) {
      print('❌ Error searching users by username: $e');
      return {'users': [], 'hasMore': false};
    }
  }
  
  Future<Map<String, dynamic>> searchUsersByEmail(String email) async {
    try {
      print('🔍 Searching for user by email: $email');
      
      final currentUid = currentUserId;
      if (currentUid == null) {
        print('⚠️ No current user logged in during email search');
        return {'users': [], 'hasMore': false};
      }
      
      // Convert the email to lowercase for comparison
      final lowercaseEmail = email.toLowerCase().trim();
      print('🔤 Normalized search email: $lowercaseEmail');
      
      // Get all users
      print('📂 Fetching all users from Firestore');
      final snapshot = await _firestore
          .collection('users')
          .get();
          
      print('📊 Total users in database: ${snapshot.docs.length}');
      
      // Filter results manually for case-insensitive search
      final results = snapshot.docs
          .where((doc) => doc.id != currentUid) // Exclude current user
          .where((doc) {
            final userEmail = (doc.data()['email'] ?? '').toString().toLowerCase();
            final match = userEmail.contains(lowercaseEmail);
            print('👤 Checking user ${doc.id}: email=$userEmail, match=$match');
            return match;
          })
          .map((doc) => doc.data())
          .toList();
      
      print('🔢 Found ${results.length} matching users');
      if (results.isNotEmpty) {
        print('✓ First matching user: ${results.first['email'] ?? 'No email'}, ${results.first['username'] ?? 'No username'}');
      }
      
      return {
        'users': results,
        'hasMore': false,
      };
    } catch (e) {
      print('❌ Error searching users by email: $e');
      return {'users': [], 'hasMore': false};
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

  // Force save the current user to Firestore
  Future<bool> forceCreateCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Cannot force create user: No user is logged in');
        return false;
      }
      
      print('🔨 Forcing user creation for ${user.uid}, ${user.email}');
      
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
        createdAt: Timestamp.now(),
        avatarUrl: user.photoURL,
        swearCount: 0,
      );
      
      // Set with merge option to avoid overwriting existing data
      await _firestore.collection('users').doc(user.uid).set(
        userModel.toMap(),
        SetOptions(merge: true)
      );
      
      print('✅ Successfully forced user creation/update');
      return true;
    } catch (e) {
      print('❌ Error forcing user creation: $e');
      return false;
    }
  }

  // Force create users collection and add current user
  Future<bool> forceCreateUsersCollection() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Cannot create users collection: No user is logged in');
        return false;
      }
      
      print('🏗️ Creating users collection and adding current user');
      
      // Create a batch to ensure atomicity
      final batch = _firestore.batch();
      
      // Create a user document
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
        createdAt: Timestamp.now(),
        avatarUrl: user.photoURL,
        swearCount: 0,
      );
      
      // Add the user document to the batch
      final userRef = _firestore.collection('users').doc(user.uid);
      batch.set(userRef, userModel.toMap());
      
      // Create a test user document to ensure there's more than one user
      // This makes it easier to test search functionality
      final testUserRef = _firestore.collection('users').doc('test_user');
      batch.set(testUserRef, {
        'uid': 'test_user',
        'email': 'test@example.com',
        'username': 'Test User',
        'createdAt': Timestamp.now(),
        'swearCount': 42,
      });
      
      // Commit the batch
      await batch.commit();
      
      print('✅ Successfully created users collection and added users');
      return true;
    } catch (e) {
      print('❌ Error creating users collection: $e');
      return false;
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

  Stream<List<Map<String, dynamic>>> getIncomingFriendRequests() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('friendRequests')
        .doc(userId)
        .collection('received')
        .snapshots()
        .asyncMap((snapshot) async {
      final requests = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final senderUid = doc.id;
        final userData = await getUserData(senderUid);
        if (userData != null) {
          requests.add({
            'uid': senderUid,
            'name': userData.username,
            'photoURL': userData.avatarUrl,
            'timestamp': doc.data()['timestamp'],
          });
        }
      }
      return requests;
    });
  }
  
  Stream<List<Map<String, dynamic>>> getOutgoingFriendRequests() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('friendRequests')
        .doc(userId)
        .collection('sent')
        .snapshots()
        .asyncMap((snapshot) async {
      final requests = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final recipientUid = doc.id;
        final userData = await getUserData(recipientUid);
        if (userData != null) {
          requests.add({
            'uid': recipientUid,
            'name': userData.username,
            'photoURL': userData.avatarUrl,
            'timestamp': doc.data()['timestamp'],
          });
        }
      }
      return requests;
    });
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
    final userId = currentUserId;
    if (userId == null) return;

    // Remove the friend request
    final batch = _firestore.batch();
    batch.delete(
      _firestore
          .collection('friendRequests')
          .doc(userId)
          .collection('received')
          .doc(senderUid),
    );
    batch.delete(
      _firestore
          .collection('friendRequests')
          .doc(senderUid)
          .collection('sent')
          .doc(userId),
    );
    await batch.commit();
  }

  Future<void> cancelFriendRequest(String recipientUid) async {
    final userId = currentUserId;
    if (userId == null) return;

    // Remove the friend request from both collections
    final batch = _firestore.batch();
    batch.delete(
      _firestore
          .collection('friendRequests')
          .doc(userId)
          .collection('sent')
          .doc(recipientUid),
    );
    batch.delete(
      _firestore
          .collection('friendRequests')
          .doc(recipientUid)
          .collection('received')
          .doc(userId),
    );
    await batch.commit();
  }
  
  // Second implementations removed to resolve duplicate method declarations
  
  // Update user's swear count
  Future<void> updateSwearCount(int count) async {
    final userId = currentUserId;
    if (userId == null) {
      print('Cannot update swear count: User not logged in');
      return;
    }
    
    try {
      await _firestore.collection('users').doc(userId).update({
        'swearCount': count,
        'lastUpdated': Timestamp.now(),
      });
      print('Swear count updated successfully: $count');
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
        
        // Retry the update after creating the user
        try {
          await _firestore.collection('users').doc(userId).update({
            'swearCount': count,
            'lastUpdated': Timestamp.now(),
          });
          print('Swear count updated successfully after creating user: $count');
        } catch (retryError) {
          print('Failed to update swear count after creating user: $retryError');
        }
      }
    }
  }
}
