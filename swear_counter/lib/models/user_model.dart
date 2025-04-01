import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final Timestamp createdAt;
  final String? avatarUrl; // ✅ optional profile picture

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.createdAt,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'createdAt': createdAt,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      username: map['username'],
      createdAt: map['createdAt'],
      avatarUrl: map['avatarUrl'],
    );
  }
}
