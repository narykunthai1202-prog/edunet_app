import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/post/domain/entities/report.dart';

class ReportRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'reports';

  Future<void> createReport(Report report) async {
    await _firestore
        .collection(_collection)
        .doc(report.id)
        .set(report.toJson());
  }

  Future<List<Report>> getReportsForTarget({
    required String targetId,
    required String targetType,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType)
        .get();

    return snapshot.docs
        .map((doc) => Report.fromJson(doc.data()))
        .toList();
  }

  Future<int> getUniqueReporterCount({
    required String targetId,
    required String targetType,
  }) async {
    final reports = await getReportsForTarget(
      targetId: targetId,
      targetType: targetType,
    );

    final uniqueReporters = <String>{};

    for (final report in reports) {
      uniqueReporters.add(report.reporterId);
    }

    return uniqueReporters.length;
  }

  Future<bool> hasUserReported({
    required String targetId,
    required String targetType,
    required String reporterId,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType)
        .where('reporterId', isEqualTo: reporterId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}