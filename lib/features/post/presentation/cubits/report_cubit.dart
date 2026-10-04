
import 'package:edunest_app/features/post/data/firebase_report_repos.dart';
import 'package:edunest_app/features/post/domain/entities/report.dart';
import 'package:edunest_app/features/post/presentation/cubits/report_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepo reportRepo;

  ReportCubit({
    required this.reportRepo,
  }) : super(ReportInitial());

  Future<void> submitReport({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
    String description = '',
  }) async {
    try {
      emit(ReportSubmitting());

      // Prevent the same user from reporting the same target twice.
      final alreadyReported = await reportRepo.hasUserReported(
        targetId: targetId,
        targetType: targetType,
        reporterId: reporterId,
      );

      if (alreadyReported) {
        emit(ReportAlreadyReported());
        return;
      }

      final reportId =
          '${reporterId}_${targetType}_$targetId';

      final report = Report(
        id: reportId,
        reporterId: reporterId,
        targetId: targetId,
        targetType: targetType,
        reason: reason,
        description: description,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      await reportRepo.createReport(report);

      final reportCount =
          await reportRepo.getUniqueReporterCount(
        targetId: targetId,
        targetType: targetType,
      );

      emit(
        ReportSubmitted(
          uniqueReportCount: reportCount,
        ),
      );
    } catch (e) {
      emit(
        ReportError(
          message: e.toString(),
        ),
      );
    }
  }
}