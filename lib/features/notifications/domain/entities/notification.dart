import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String receiverId;
  final String senderId;
  final String type;
  final String title;
  final String message;
  final String? postId;
  final bool isRead;
  final String? senderProfileImageurl;
  final Timestamp createdAt;

  Notification({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.message,
    this.postId,
    required this.isRead,
    this.senderProfileImageurl,
    required this.createdAt,
  });

  Notification copyWith({
    String? id,
    String? receiverId,
    String? senderId,
    String? type,
    String? title,
    String? message,
    String? postId,
    bool? isRead,
    String? senderProfileImageurl,
    Timestamp? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      postId: postId ?? this.postId,
      isRead: isRead ?? this.isRead,
      senderProfileImageurl:
          senderProfileImageurl ?? this.senderProfileImageurl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiverId': receiverId,
      'senderId': senderId,
      'type': type,
      'title': title,
      'message': message,
      'postId': postId,
      'isRead': isRead,
      'senderProfileImageurl': senderProfileImageurl,
      'createdAt': createdAt,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderId: map['senderId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      postId: map['postId'],
      isRead: map['isRead'] ?? false,
      senderProfileImageurl: map['senderProfileImageurl'],
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt']
          : Timestamp.now(),
    );
  }
}
