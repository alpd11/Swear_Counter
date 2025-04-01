import 'package:swear_counter_app/models/friend_model.dart';

class UserModel {
  final String uid;
  final String name;
  final int swearCount;
  final List<FriendModel> friends;

  UserModel({
    required this.uid,
    required this.name,
    required this.swearCount,
    required this.friends,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'swearCount': swearCount,
        'friends': friends.map((f) => f.toMap()).toList(),
      };

  static UserModel fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'],
        name: map['name'],
        swearCount: map['swearCount'],
        friends: (map['friends'] as List)
            .map((f) => FriendModel.fromMap(f))
            .toList(),
      );
}
