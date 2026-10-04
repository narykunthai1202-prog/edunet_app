abstract class ReportState {}

class ReportInitial extends ReportState {}

class ReportSubmitting extends ReportState {}

class ReportSubmitted extends ReportState {
  final int uniqueReportCount;

  ReportSubmitted({
    required this.uniqueReportCount,
  });
}

class ReportAlreadyReported extends ReportState {}

class ReportError extends ReportState {
  final String message;

  ReportError({
    required this.message,
  });
}