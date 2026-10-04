import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reporterId;
  final String targetId;
  final String targetType; // post, comment, account
  final String reason;
  final String description;
  final DateTime createdAt;
  final String status; // pending, reviewed, dismissed, action_taken

  Report({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      reporterId: json['reporterId'] ?? '',
      targetId: json['targetId'] ?? '',
      targetType: json['targetType'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: json['status'] ?? 'pending',
    );
  }
}