import 'package:edunest_app/features/post/presentation/cubits/report_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/report_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class ReportDialog extends StatefulWidget {
  final String targetId;
  final String targetType;
  final String reporterId;

  const ReportDialog({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.reporterId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? selectedReason;

  final TextEditingController descriptionController =
      TextEditingController();

  final List<String> reasons = [
    'Spam',
    'Harassment or bullying',
    'Hate speech',
    'Inappropriate content',
    'Violence',
    'False information',
    'Scam or fraud',
    'Other',
  ];

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  void submitReport() {
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason.'),
        ),
      );
      return;
    }

    context.read<ReportCubit>().submitReport(
          reporterId: widget.reporterId,
          targetId: widget.targetId,
          targetType: widget.targetType,
          reason: selectedReason!,
          description: descriptionController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportCubit, ReportState>(
      listener: (context, state) {
        if (state is ReportSubmitted) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Thank you. Your report has been submitted.',
              ),
            ),
          );
        }

        if (state is ReportAlreadyReported) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You have already reported this.',
              ),
            ),
          );
        }

        if (state is ReportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to submit report: ${state.message}',
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is ReportSubmitting;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Why are you reporting this ${widget.targetType}?',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 16),

                ...reasons.map(
                  (reason) {
                    return RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                selectedReason = value;
                              });
                            },
                    );
                  },
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Additional details (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : submitReport,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit Report'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}