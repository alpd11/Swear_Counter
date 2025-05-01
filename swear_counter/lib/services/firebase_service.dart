import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';

// New class for Realtime Database interactions
class RealtimeDbService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Configure the database URL
  RealtimeDbService() {
    _database.databaseURL = 'https://swear-counter-fb94b-default-rtdb.firebaseio.com/';
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Public method to get a reference to a user by uid
  Future<DataSnapshot> getUserSnapshot(String uid) async {
    return await _database.ref('users/$uid').get();
  }
  
  // Public method to get a reference to all users
  Future<DataSnapshot> getAllUsersSnapshot() async {
    return await _database.ref('users').get();
  }
  
  // Create or update user in Realtime Database
  Future<void> saveUser(UserModel user) async {
    await _database.ref('users/${user.uid}').set({
      'uid': user.uid,
      'email': user.email,
      'username': user.username,
      'createdAt': user.createdAt.millisecondsSinceEpoch,
      'avatarUrl': user.avatarUrl,
      'swearCount': user.swearCount,
    });
    print('✅ User saved to Realtime DB: ${user.uid}');
  }
  
  // Fetch user by uid
  Future<UserModel?> fetchUser(String uid) async {
    final snapshot = await _database.ref('users/$uid').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return UserModel(
        uid: data['uid'] as String,
        email: data['email'] as String,
        username: data['username'] as String,
        createdAt: Timestamp.fromMillisecondsSinceEpoch(data['createdAt']),
        avatarUrl: data['avatarUrl'] as String?,
        swearCount: data['swearCount'] as int? ?? 0,
      );
    }
    return null;
  }

  // Create or update user if they don't exist in DB
  Future<void> createUserIfNotExists(User user) async {
    try {
      print('⚠️ Checking if user exists in Realtime DB: ${user.uid}');
      
      final snapshot = await _database.ref('users/${user.uid}').get();
      
      if (!snapshot.exists) {
        // Create new user if they don't exist yet
        print('📝 User does not exist in Realtime DB. Creating new user...');
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          createdAt: Timestamp.now(),
          avatarUrl: user.photoURL,
        );
        await saveUser(newUser);
        print('✅ New user created in Realtime DB: ${user.uid}');
      } else {
        // User exists, update their profile info if needed
        final userData = snapshot.value as Map<dynamic, dynamic>;
        final updates = <String, dynamic>{};
        
        // Update email if it changed
        if (user.email != null && user.email != userData['email']) {
          updates['email'] = user.email;
        }
        
        // Update display name if it changed
        if (user.displayName != null && user.displayName != userData['username']) {
          updates['username'] = user.displayName;
        }
        
        // Update avatar URL if it changed
        if (user.photoURL != null && user.photoURL != userData['avatarUrl']) {
          updates['avatarUrl'] = user.photoURL;
        }
        
        // Apply updates if there are any
        if (updates.isNotEmpty) {
          await _database.ref('users/${user.uid}').update(updates);
          print('✅ Updated existing user in Realtime DB: ${user.uid}');
        }
      }
    } catch (e) {
      print('❌ ERROR in createUserIfNotExists: $e');
      // Fallback save attempt
      try {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          createdAt: Timestamp.now(),
          avatarUrl: user.photoURL,
        );
        
        await saveUser(newUser);
        print('✅ Fallback save successful for user: ${user.uid}');
      } catch (fallbackError) {
        print('❌❌ CRITICAL: Failed fallback save: $fallbackError');
      }
    }
  }

  // Search for users by identifier (email or username)
  Future<Map<String, dynamic>> searchUsersByIdentifier(String identifier) async {
    try {
      print('🔍 Searching for user by identifier in Realtime DB: $identifier');

      final currentUid = currentUserId;
      if (currentUid == null) {
        print('⚠️ No current user logged in during search');
        return {'users': [], 'hasMore': false};
      }

      // Normalize the identifier for case-insensitive search
      final normalizedIdentifier = identifier.toLowerCase().trim();
      
      // Get all users from the database
      final snapshot = await _database.ref('users').get();
      if (!snapshot.exists) {
        return {'users': [], 'hasMore': false};
      }
      
      final allUsers = snapshot.children.map((child) {
        return child.value as Map<dynamic, dynamic>;
      }).toList();
      
      print('📊 Total users in Realtime DB: ${allUsers.length}');
      
      // Filter results manually for case-insensitive search
      final results = allUsers
          .where((userData) => userData['uid'] != currentUid) // Exclude current user
          .where((userData) {
            final email = (userData['email'] ?? '').toString().toLowerCase();
            final username = (userData['username'] ?? '').toString().toLowerCase();
            final match = email.contains(normalizedIdentifier) || username.contains(normalizedIdentifier);
            print('👤 Checking user ${userData['uid']}: email=$email, username=$username, match=$match');
            return match;
          })
          .map((userData) => Map<String, dynamic>.from(userData))
          .toList();
      
      print('🔢 Found ${results.length} matching users');
      return {
        'users': results,
        'hasMore': false,
      };
    } catch (e) {
      print('❌ Error searching users by identifier: $e');
      return {'users': [], 'hasMore': false};
    }
  }
  
  // Force create current user in the database
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
      
      await saveUser(userModel);
      
      print('✅ Successfully forced user creation/update in Realtime DB');
      return true;
    } catch (e) {
      print('❌ Error forcing user creation: $e');
      return false;
    }
  }
  
  // Create test users for easier debugging
  Future<bool> forceCreateUsersCollection() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Cannot create users collection: No user is logged in');
        return false;
      }
      
      print('🏗️ Creating users collection and test users in Realtime DB');
      
      // Create the current user
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
        createdAt: Timestamp.now(),
        avatarUrl: user.photoURL,
        swearCount: 0,
      );
      
      // Create the main user
      await saveUser(userModel);
      
      // Create three test users
      await _database.ref('users/test_user1').set({
        'uid': 'test_user1',
        'email': 'test1@example.com',
        'username': 'Test User 1',
        'createdAt': Timestamp.now().millisecondsSinceEpoch,
        'swearCount': 42,
      });
      
      await _database.ref('users/test_user2').set({
        'uid': 'test_user2',
        'email': 'test2@example.com',
        'username': 'Test User 2',
        'createdAt': Timestamp.now().millisecondsSinceEpoch,
        'swearCount': 24,
      });
      
      await _database.ref('users/test_user3').set({
        'uid': 'test_user3',
        'email': 'test3@example.com',
        'username': 'Test User 3',
        'createdAt': Timestamp.now().millisecondsSinceEpoch,
        'swearCount': 18,
      });
      
      print('✅ Successfully created users collection with test users');
      return true;
    } catch (e) {
      print('❌ Error creating users collection: $e');
      return false;
    }
  }
  
  // Get friends list
  Future<List<FriendModel>> getFriends() async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    try {
      final snapshot = await _database.ref('friends/$userId/friendIds').get();
      
      if (!snapshot.exists) return [];
      
      final friendIds = List<String>.from(snapshot.value as List? ?? []);
      
      if (friendIds.isEmpty) return [];
      
      final friendsList = <FriendModel>[];
      
      // Get user documents for all friends
      for (final friendId in friendIds) {
        final friendSnapshot = await _database.ref('users/$friendId').get();
        if (friendSnapshot.exists) {
          final friendData = friendSnapshot.value as Map<dynamic, dynamic>;
          friendsList.add(FriendModel(
            uid: friendId,
            name: friendData['username'] ?? 'Unknown',
            swearCount: friendData['swearCount'] ?? 0,
            avatarUrl: friendData['avatarUrl'],
          ));
        }
      }
      
      return friendsList;
    } catch (e) {
      print('Error getting friends list: $e');
      return [];
    }
  }
  
  // Send friend request
  Future<void> sendFriendRequest(String recipientUid) async {
    final senderUid = currentUserId;
    if (senderUid == null) throw Exception('User not logged in');
    
    // Check if already friends
    final friendsSnapshot = await _database.ref('friends/$senderUid/friendIds').get();
    if (friendsSnapshot.exists) {
      final friendIds = List<String>.from(friendsSnapshot.value as List? ?? []);
      if (friendIds.contains(recipientUid)) {
        throw Exception('Already friends with this user');
      }
    }
    
    // Check if request already sent
    final sentRequestSnapshot = await _database
        .ref('friendRequests/$senderUid/sent/$recipientUid')
        .get();
        
    if (sentRequestSnapshot.exists) {
      throw Exception('Friend request already sent');
    }
    
    // Get sender user data to include in request
    final senderSnapshot = await _database.ref('users/$senderUid').get();
    if (!senderSnapshot.exists) throw Exception('Sender profile not found');
    
    final senderData = senderSnapshot.value as Map<dynamic, dynamic>;
    
    // Add to sender's sent requests
    await _database
        .ref('friendRequests/$senderUid/sent/$recipientUid')
        .set({
          'timestamp': ServerValue.timestamp,
          'status': 'pending',
        });
    
    // Add to recipient's incoming requests
    await _database
        .ref('friendRequests/$recipientUid/received/$senderUid')
        .set({
          'timestamp': ServerValue.timestamp,
          'status': 'pending',
          'uid': senderUid,
          'username': senderData['username'],
          'email': senderData['email'],
          'avatarUrl': senderData['avatarUrl'],
        });
  }
  
  // Get incoming friend requests
  Stream<List<Map<String, dynamic>>> getIncomingFriendRequests() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _database
        .ref('friendRequests/$userId/received')
        .onValue
        .map((event) {
          final snapshot = event.snapshot;
          if (!snapshot.exists) return <Map<String, dynamic>>[];
          
          final requests = <Map<String, dynamic>>[];
          for (final child in snapshot.children) {
            try {
              final data = child.value as Map<dynamic, dynamic>;
              requests.add({
                'uid': child.key,
                'username': data['username'], // Use username to match UI expectations
                'name': data['username'], // Add name field for compatibility
                'email': data['email'],
                'avatarUrl': data['avatarUrl'],
                'timestamp': data['timestamp'],
              });
            } catch (e) {
              print('Error processing incoming request: $e');
            }
          }
          return requests;
        });
  }
  
  // Get outgoing friend requests
  Stream<List<Map<String, dynamic>>> getOutgoingFriendRequests() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _database
        .ref('friendRequests/$userId/sent')
        .onValue
        .map((event) {
          final snapshot = event.snapshot;
          if (!snapshot.exists) return <Map<String, dynamic>>[];
          
          final requests = <Map<String, dynamic>>[];
          // First, collect all recipient UIDs from the snapshot
          final recipientUids = <String>[];
          for (final child in snapshot.children) {
            if (child.key != null) {
              recipientUids.add(child.key!);
            }
          }
          
          // Return the UIDs as a placeholder, will be resolved in the next step
          return recipientUids;
        })
        .asyncMap((recipientUids) async {
          final requests = <Map<String, dynamic>>[];
          
          // Fetch user data for each recipient
          for (final uid in recipientUids) {
            try {
              final recipientSnapshot = await _database.ref('users/$uid').get();
              if (recipientSnapshot.exists) {
                final userData = recipientSnapshot.value as Map<dynamic, dynamic>;
                requests.add({
                  'uid': uid,
                  'name': userData['username'] ?? 'Unknown',
                  'username': userData['username'] ?? 'Unknown', // Add for consistency
                  'email': userData['email'] ?? '',
                  'avatarUrl': userData['avatarUrl'],
                  'timestamp': DateTime.now().millisecondsSinceEpoch, // Placeholder timestamp
                });
              }
            } catch (e) {
              print('Error fetching recipient data: $e');
            }
          }
          
          return requests;
        });
  }
  
  // Accept friend request
  Future<void> acceptFriendRequest(String senderUid) async {
    final recipientUid = currentUserId;
    if (recipientUid == null) throw Exception('User not logged in');
    
    // Update request status
    await _database
        .ref('friendRequests/$recipientUid/received/$senderUid')
        .update({'status': 'accepted'});
    
    await _database
        .ref('friendRequests/$senderUid/sent/$recipientUid')
        .update({'status': 'accepted'});
    
    // Add to friends collection for recipient
    final recipientFriendsSnapshot = await _database.ref('friends/$recipientUid/friendIds').get();
    List<String> recipientFriendIds = [];
    if (recipientFriendsSnapshot.exists) {
      recipientFriendIds = List<String>.from(recipientFriendsSnapshot.value as List? ?? []);
    }
    recipientFriendIds.add(senderUid);
    await _database.ref('friends/$recipientUid').set({
      'friendIds': recipientFriendIds,
    });
    
    // Add to friends collection for sender
    final senderFriendsSnapshot = await _database.ref('friends/$senderUid/friendIds').get();
    List<String> senderFriendIds = [];
    if (senderFriendsSnapshot.exists) {
      senderFriendIds = List<String>.from(senderFriendsSnapshot.value as List? ?? []);
    }
    senderFriendIds.add(recipientUid);
    await _database.ref('friends/$senderUid').set({
      'friendIds': senderFriendIds,
    });
  }
  
  // Reject friend request
  Future<void> rejectFriendRequest(String senderUid) async {
    final userId = currentUserId;
    if (userId == null) return;

    // Remove the friend request
    await _database.ref('friendRequests/$userId/received/$senderUid').remove();
    await _database.ref('friendRequests/$senderUid/sent/$userId').remove();
  }
  
  // Cancel sent friend request
  Future<void> cancelFriendRequest(String recipientUid) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');
    
    // Remove the friend request from both users
    await _database.ref('friendRequests/$userId/sent/$recipientUid').remove();
    await _database.ref('friendRequests/$recipientUid/received/$userId').remove();
    
    print('✅ Friend request to $recipientUid canceled successfully');
  }
  
  // Delete friend
  Future<void> deleteFriend(String friendUid) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');
    
    // Get current friend IDs for user
    final userFriendsSnapshot = await _database.ref('friends/$userId/friendIds').get();
    if (userFriendsSnapshot.exists) {
      final friendIds = List<String>.from(userFriendsSnapshot.value as List? ?? []);
      friendIds.remove(friendUid);
      await _database.ref('friends/$userId').set({
        'friendIds': friendIds,
      });
    }
    
    // Get current friend IDs for friend
    final friendFriendsSnapshot = await _database.ref('friends/$friendUid/friendIds').get();
    if (friendFriendsSnapshot.exists) {
      final friendIds = List<String>.from(friendFriendsSnapshot.value as List? ?? []);
      friendIds.remove(userId);
      await _database.ref('friends/$friendUid').set({
        'friendIds': friendIds,
      });
    }
  }
  
  // Update user's swear count
  Future<void> updateSwearCount(int count) async {
    final userId = currentUserId;
    if (userId == null) {
      print('Cannot update swear count: User not logged in');
      return;
    }
    
    try {
      await _database.ref('users/$userId').update({
        'swearCount': count,
        'lastUpdated': ServerValue.timestamp,
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
          swearCount: count,
        );
        await saveUser(userModel);
      }
    }
  }
}

// Keep the existing FirebaseService class below
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

  Future<Map<String, dynamic>> searchUsersByIdentifier(String identifier) async {
    try {
      print('🔍 Searching for user by identifier: $identifier');

      final currentUid = currentUserId;
      if (currentUid == null) {
        print('⚠️ No current user logged in during identifier search');
        return {'users': [], 'hasMore': false};
      }

      // Normalize the identifier for case-insensitive search
      final normalizedIdentifier = identifier.toLowerCase().trim();
      print('🔤 Normalized search identifier: $normalizedIdentifier');

      // Fetch all users from Firestore
      print('📂 Fetching all users from Firestore');
      final snapshot = await _firestore.collection('users').get();
      print('📊 Total users in database: ${snapshot.docs.length}');

      // Filter results manually for case-insensitive search
      final results = snapshot.docs
          .where((doc) => doc.id != currentUid) // Exclude current user
          .where((doc) {
            final data = doc.data();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final username = (data['username'] ?? '').toString().toLowerCase();
            final match = email.contains(normalizedIdentifier) || username.contains(normalizedIdentifier);
            print('👤 Checking user ${doc.id}: email=$email, username=$username, match=$match');
            return match;
          })
          .map((doc) => doc.data())
          .toList();

      print('🔢 Found ${results.length} matching users');
      return {
        'users': results,
        'hasMore': false,
      };
    } catch (e) {
      print('❌ Error searching users by identifier: $e');
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
