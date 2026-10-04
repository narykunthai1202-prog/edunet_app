
import 'package:edunest_app/features/post/domain/entities/report.dart';

abstract class ReportRepos {
  Future<void> createReport(Report report);
  Future<List<Report>> getReportsForTarget(String targetid, String targetType);
  Future<int> getUniqueReportCount(String targetId, targetType);
  Future<bool> hasUserReported(String targetId, String targetType, String reporterId);
  
}