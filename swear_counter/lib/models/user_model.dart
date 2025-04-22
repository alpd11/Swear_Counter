import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final Timestamp createdAt;
  final String? avatarUrl; // ✅ optional profile picture
  final int swearCount; // Add swear count field

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.createdAt,
    this.avatarUrl,
    this.swearCount = 0, // Default to 0
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'createdAt': createdAt,
      'avatarUrl': avatarUrl,
      'swearCount': swearCount, // Include in map
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      username: map['username'],
      createdAt: map['createdAt'],
      avatarUrl: map['avatarUrl'],
      swearCount: map['swearCount'] ?? 0, // Parse from map with default
    );
  }
}
