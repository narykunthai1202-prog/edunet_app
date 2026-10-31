import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final DateTime? suspendedUntil;
  final String role;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.isSuspended = false,
    this.suspensionReason,
    this.suspendedAt,
    this.suspendedUntil,
    this.role = 'user',
    this.createdAt,
  });

  // Convert app user to map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'suspendedAt':
          suspendedAt != null ? Timestamp.fromDate(suspendedAt!) : null,
      'suspendedUntil':
          suspendedUntil != null ? Timestamp.fromDate(suspendedUntil!) : null,
      'role': role,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  // Convert AppUser instance into a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'suspendedAt':
          suspendedAt != null ? Timestamp.fromDate(suspendedAt!) : null,
      'suspendedUntil':
          suspendedUntil != null ? Timestamp.fromDate(suspendedUntil!) : null,
      'role': role,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  // Convert json -> app user
  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return AppUser(
      uid: jsonUser['uid'] ?? '',
      email: jsonUser['email'] ?? '',
      name: jsonUser['name'] ?? '',
      isSuspended: jsonUser['isSuspended'] == true,
      suspensionReason: jsonUser['suspensionReason'],
      suspendedAt: parseDate(jsonUser['suspendedAt']),
      suspendedUntil: parseDate(jsonUser['suspendedUntil']),
      role: jsonUser['role'] ?? 'user',
      createdAt: parseDate(jsonUser['createdAt']),
    );
  }
}
