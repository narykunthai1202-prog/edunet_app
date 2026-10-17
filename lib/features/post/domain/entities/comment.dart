import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? imgurl;
  final String text;
  final DateTime timestamp;
  final String? userimgurl;
  final List<String> reactions;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.imgurl,
    required this.text,
    required this.timestamp,
    required this.userimgurl,
    required this.reactions,
    required this.replies,
  });

  Comment CopyWith({
    String? imageUrl,
    String? text,
    List<String>? reactions,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id,
      postId: postId,
      userId: userId,
      userName: userName,
      text: text ?? this.text,
      imgurl: imageUrl ?? imgurl,
      timestamp: timestamp,
      userimgurl: userimgurl,
      reactions: reactions ?? this.reactions,
      replies: replies ?? this.replies,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'userId': userId,
    'userName': userName,
    'imgurl': imgurl,
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
    'userimgurl': userimgurl,
    'reactions': reactions,
    'replies': replies.map((reply) => reply.toJson()).toList(),
  };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id']?.toString() ?? '',
    postId: json['postId']?.toString() ?? '',
    userId: json['userId']?.toString() ?? '',
    userName: json['userName']?.toString() ?? 'User',
    imgurl: json['imgurl']?.toString(),
    text: json['text']?.toString() ?? '',
    timestamp: json['timestamp'] is Timestamp
        ? (json['timestamp'] as Timestamp).toDate()
        : DateTime.tryParse('${json['timestamp']}') ?? DateTime.now(),
    userimgurl: json['userimgurl']?.toString(),
    reactions: List<String>.from(json['reactions'] ?? []),
    replies:
        (json['replies'] as List<dynamic>?)
            ?.map(
              (item) =>
                  Comment.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList() ??
        [],
  );
}
