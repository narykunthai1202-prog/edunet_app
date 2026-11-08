import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/post/domain/entities/comment.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final List<String> imageUrls;
  final DateTime timestamp;
  final List<String> likes;
  final List<Comment> comments;
  final String privacy;
  final List<String> savedBy;
  final List<String>? taggedUserIds;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    this.imageUrls = const [],
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.privacy,
    required this.savedBy,
    this.taggedUserIds = const [],
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
  });

  Post copyWith({
    List<String>? imageUrls,
    String? text,
    String? privacy,
    List<String>? taggedUserIds,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Post(
      id: id,
      userId: userId,
      userName: userName,
      text: text ?? this.text,
      imageUrls: imageUrls ?? this.imageUrls,
      timestamp: timestamp,
      likes: likes,
      comments: comments,
      privacy: privacy ?? this.privacy,
      savedBy: savedBy,
      taggedUserIds: taggedUserIds ?? this.taggedUserIds,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': userName,
      'text': text,
      'imageUrls': imageUrls,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'privacy': privacy,
      'savedBy': savedBy,
      'taggedUserIds': taggedUserIds,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final List<Comment> comments =
        (json['comments'] as List<dynamic>?)
            ?.map(
              (commentJson) =>
                  Comment.fromJson(Map<String, dynamic>.from(commentJson)),
            )
            .toList() ??
        [];

    List<String> imageUrls = [];

    if (json['imageUrls'] != null) {
      imageUrls = List<String>.from(json['imageUrls']);
    } else if (json['imageUrl'] != null &&
        json['imageUrl'].toString().isNotEmpty) {
      imageUrls = [json['imageUrl'].toString()];
    }

    DateTime timestamp;

    if (json['timestamp'] is Timestamp) {
      timestamp = (json['timestamp'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.now();
    }

    final bool isDeleted =
        json['isDeleted'] is bool ? json['isDeleted'] as bool : false;
    DateTime? deletedAt;
    if (json['deletedAt'] is Timestamp) {
      deletedAt = (json['deletedAt'] as Timestamp).toDate();
    } else if (json['deletedAt'] is String) {
      deletedAt = DateTime.tryParse(json['deletedAt']);
    }
    final String? deletedBy = json['deletedBy'] as String?;

    return Post(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['name'] ?? '',
      text: json['text'] ?? '',
      imageUrls: imageUrls,
      timestamp: timestamp,

      // IMPORTANT: lowercase "likes"
      likes: List<String>.from(json['likes'] ?? []),

      comments: comments,

      privacy: json['privacy'] ?? '',

      // IMPORTANT: must be a List, not ""
      savedBy: List<String>.from(json['savedBy'] ?? []),
      taggedUserIds: List<String>.from(json['taggedUserIds'] ?? []),
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
    );
  }
}
