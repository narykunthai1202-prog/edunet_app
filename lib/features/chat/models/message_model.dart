import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final String type;
  final bool isSeen;
  final Map<String, String> reactions;
  final String? replyToText;
  final bool isDeleted;
  final bool isForwarded;
  final String? forwardedFromSenderName;
  final Map<String, dynamic>? audio;
  final String? status;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;

  String get id => messageId;

  /// Alias getter so UI elements referencing `content` get the message payload seamlessly
  String get content => text;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    this.type = 'text',
    required this.text,
    required this.timestamp,
    required this.isSeen,
    this.reactions = const {},
    this.replyToText,
    this.isDeleted = false,
    this.isForwarded = false,
    this.forwardedFromSenderName,
    this.audio,
    this.status,
    this.fileUrl,
    this.fileName,
    this.fileSize,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    // 1. Extract message payload across text, content, imageUrl, audioUrl, url, or nested maps
    String extractedText = map['text'] ??
        map['content'] ??
        map['imageUrl'] ??
        map['photoUrl'] ??
        map['audioUrl'] ??
        map['url'] ??
        map['fileUrl'] ?? // NEW: file messages
        '';

    // 2. Extract nested audio map if available
    Map<String, dynamic>? audioMap;
    if (map['audio'] is Map<String, dynamic>) {
      audioMap = Map<String, dynamic>.from(map['audio']);
    }

    // 3. Fallback extraction for legacy or nested audio payloads
    if (extractedText.isEmpty && map['audio'] != null) {
      if (map['audio'] is Map) {
        extractedText = map['audio']['storagePath'] ??
            map['audio']['url'] ??
            map['audio']['audioUrl'] ??
            map['audio']['text'] ??
            '';
      } else if (map['audio'] is String) {
        extractedText = map['audio'];
      }
    }

    // 4. Safely parse timestamps (handles pending server timestamps gracefully)
    DateTime parseTimestamp(dynamic rawValue) {
      if (rawValue is Timestamp) {
        return rawValue.toDate();
      } else if (rawValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(rawValue);
      } else if (rawValue is String) {
        return DateTime.tryParse(rawValue) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return MessageModel(
      messageId: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: extractedText,
      type: map['type'] ?? 'text',
      timestamp: parseTimestamp(map['timestamp'] ?? map['createdAt']),
      isSeen: map['isSeen'] ?? false,
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      replyToText: map['replyToText'] as String?,
      isDeleted: map['isDeleted'] ?? false,
      isForwarded: map['isForwarded'] ?? false,
      forwardedFromSenderName: map['forwardedFromSenderName'] as String?,
      audio: audioMap,
      status: map['status'] as String?,
      // NEW: file fields
      fileUrl: map['fileUrl'] as String?,
      fileName: map['fileName'] as String?,
      fileSize: (map['fileSize'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'content': text, // Duplicate written for backwards compatibility
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSeen': isSeen,
      'reactions': reactions,
      'replyToText': replyToText,
      'isDeleted': isDeleted,
      'isForwarded': isForwarded,
      'forwardedFromSenderName': forwardedFromSenderName,
      'audio': audio,
      'status': status,
      // NEW: file fields
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }
}