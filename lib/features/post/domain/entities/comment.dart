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
  //convert comment ->
  Map<String, dynamic> toJson() {
    return {
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
  }

  //convert json ->comment
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      userName: json['userName'],
      imgurl: json['imgurl'],
      text: json['text'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      userimgurl: json['userimgurl'],
      reactions: List<String>.from(json['reactions'] ?? []),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((replyJson) => Comment.fromJson(replyJson))
              .toList() ??
          [],
    );
  }
}
