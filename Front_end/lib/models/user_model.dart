import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String field;
  final List<String> skills;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.field,
    required this.skills,
    this.profilePictureUrl,
    required this.createdAt,
    required this.lastActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      field: map['field'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      profilePictureUrl: map['profilePictureUrl'],
      createdAt: (map['created_at'] as Timestamp).toDate(),
      lastActive: (map['last_active'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'field': field,
      'skills': skills,
      'profilePictureUrl': profilePictureUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'last_active': Timestamp.fromDate(lastActive),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? field,
    List<String>? skills,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      field: field ?? this.field,
      skills: skills ?? this.skills,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}