import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

/// Shows every file ("type == 'file'") shared in a 1-to-1 chat.
/// Use it inside the "Files" tab of the profile screen.
class SharedFilesList extends StatefulWidget {
  const SharedFilesList({
    super.key,
    required this.currentUserId,
    required this.receiverId,
  });

  final String currentUserId;
  final String receiverId;

  @override
  State<SharedFilesList> createState() => _SharedFilesListState();
}

class _SharedFilesListState extends State<SharedFilesList> {
  late Stream<List<MessageModel>> _stream;
  Timer? _timeoutTimer;
  bool _timedOut = false;

  /// How long we wait for the first data before showing a retry message.
  static const Duration _firstDataTimeout = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startListening() {
    _timedOut = false;
    _stream = ChatService()
        .getMessagesStream(widget.currentUserId, widget.receiverId);

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_firstDataTimeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  void _retry() {
    setState(_startListening);
  }

  String _nameOf(MessageModel m) {
    if (m.fileName != null && m.fileName!.isNotEmpty) return m.fileName!;
    try {
      return Uri.decodeComponent(Uri.parse(m.text).pathSegments.last);
    } catch (_) {
      return 'File';
    }
  }

  String _sizeOf(int? b) {
    if (b == null || b <= 0) return '';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _dateOf(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

  IconData _iconFor(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
      case 'txt':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      case 'php':
      case 'dart':
      case 'js':
      case 'html':
      case 'json':
        return Icons.code_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _message(String text, {bool showRetry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            if (showRetry) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MessageModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        // 1. Show errors instead of spinning forever
        if (snapshot.hasError) {
          debugPrint('SharedFilesList stream error: ${snapshot.error}');
          return _message('Could not load files.\n${snapshot.error}',
              showRetry: true);
        }

        // 2. Still waiting for the first data
        if (!snapshot.hasData) {
          if (_timedOut) {
            return _message(
              'Loading is taking too long.\nCheck your connection and try again.',
              showRetry: true,
            );
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        // Data arrived, no need for the timeout anymore
        _timeoutTimer?.cancel();

        final files = snapshot.data!
            .where((m) => m.type == 'file' && !m.isDeleted)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first

        if (files.isEmpty) {
          return _message('No files shared yet');
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: files.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final m = files[i];
            final name = _nameOf(m);
            final url = (m.fileUrl != null && m.fileUrl!.isNotEmpty)
                ? m.fileUrl!
                : m.text;
            final size = _sizeOf(m.fileSize);
            final subtitle = size.isEmpty
                ? _dateOf(m.timestamp)
                : '$size • ${_dateOf(m.timestamp)}';

            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconFor(name),
                    color: const Color(0xFF2563EB), size: 22),
              ),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: const Icon(Icons.open_in_new_rounded,
                  size: 18, color: Colors.grey),
              onTap: () async {
                if (url.isEmpty) return;
                final ok = await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open file')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}