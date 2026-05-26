import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String userName;
  final String email;
  final String? avatarUrl;
  final String? houseId;

  UserModel({
    required this.userId,
    required this.userName,
    required this.email,
    this.avatarUrl,
    this.houseId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      userName: data['userName'] as String,
      email: data['email'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      houseId: data['houseId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'email': email,
      'avatarUrl': avatarUrl,
      'houseId': houseId,
    };
  }
}