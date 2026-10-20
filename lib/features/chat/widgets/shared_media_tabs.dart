import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_model.dart';

/// "Media / Files / Links" card for ANY chat (group or 1-to-1).
///
/// You give it a stream of messages; it filters them itself:
///   Media  -> messages with type 'image' or 'video'
///   Files  -> messages with type 'file'
///   Links  -> http(s):// and www. links found inside normal text messages
///
/// IMPORTANT: create the stream ONCE (in initState) and pass the same
/// instance every time, otherwise the card reloads on every rebuild.
class SharedMediaTabs extends StatefulWidget {
  const SharedMediaTabs({
    super.key,
    required this.messages,
    required this.currentUserId,
    this.height = 380,
  });

  final Stream<List<MessageModel>> messages;
  final String currentUserId;
  final double height;

  @override
  State<SharedMediaTabs> createState() => _SharedMediaTabsState();
}

class _SharedMediaTabsState extends State<SharedMediaTabs> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _soft = Color(0xFFF1F5F9);
  static final RegExp _urlRegex =
      RegExp(r'((https?:\/\/)|(www\.))[^\s]+', caseSensitive: false);

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MessageModel>>(
      stream: widget.messages,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;

        final all = (snapshot.data ?? [])
            .where((m) => !m.isDeleted)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final media =
            all.where((m) => m.type == 'image' || m.type == 'video').toList();
        final files = all.where((m) => m.type == 'file').toList();
        final links = _extractLinks(all);
        final total = media.length + files.length + links.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(total),
              const SizedBox(height: 14),
              _segments(media.length, files.length, links.length),
              const SizedBox(height: 14),
              SizedBox(
                height: widget.height,
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(_tab),
                          child: _tab == 0
                              ? _mediaGrid(media)
                              : _tab == 1
                                  ? _filesList(files)
                                  : _linksList(links),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- header

  Widget _header(int total) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.perm_media_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Shared media',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$total',
            style: const TextStyle(
                color: _blue, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------- segmented control

  Widget _segments(int media, int files, int links) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _segment(0, Icons.photo_library_rounded, 'Media', media),
          _segment(1, Icons.insert_drive_file_rounded, 'Files', files),
          _segment(2, Icons.link_rounded, 'Links', links),
        ],
      ),
    );
  }

  Widget _segment(int index, IconData icon, String label, int count) {
    final selected = _tab == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? _blue : _muted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? _blue : _muted,
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? _blue.withValues(alpha: 0.7)
                        : _muted.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- helpers

  Widget _empty(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _soft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _muted)),
        ],
      ),
    );
  }

  String _date(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[t.month - 1]} ${t.day}, ${t.year}';
  }

  String _who(String senderId) =>
      senderId == widget.currentUserId ? 'You' : senderId;

  Uri? _toUri(String url) {
    final fixed = url.toLowerCase().startsWith('www.') ? 'https://$url' : url;
    return Uri.tryParse(fixed);
  }

  void _open(String url) {
    final uri = _toUri(url);
    if (uri == null) return;
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ------------------------------------------------------------------ media

  Widget _mediaGrid(List<MessageModel> media) {
    if (media.isEmpty) {
      return _empty(Icons.photo_library_outlined, 'No photos or videos',
          'Photos and videos sent in this chat\nwill show up here.');
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: media.length,
      itemBuilder: (context, i) {
        final m = media[i];
        final isVideo = m.type == 'video';

        return GestureDetector(
          onTap: () => isVideo ? _open(m.text) : _showImage(context, m.text),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isVideo ? _videoTile() : _imageTile(m.text),
          ),
        );
      },
    );
  }

  Widget _imageTile(String url) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
          opacity: (frame == null && !sync) ? 0 : 1,
          duration: const Duration(milliseconds: 350),
          child: child,
        ),
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _videoTile() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'VIDEO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white24),
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ files

  String _fileName(MessageModel m) {
    if (m.fileName != null && m.fileName!.isNotEmpty) return m.fileName!;
    try {
      return Uri.decodeComponent(Uri.parse(m.text).pathSegments.last);
    } catch (_) {
      return 'File';
    }
  }

  String _size(int? b) {
    if (b == null || b <= 0) return '';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Icon + color for each kind of file
  (IconData, Color) _fileStyle(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return (Icons.picture_as_pdf_rounded, const Color(0xFFEF4444));
      case 'doc':
      case 'docx':
      case 'txt':
        return (Icons.description_rounded, const Color(0xFF2563EB));
      case 'xls':
      case 'xlsx':
      case 'csv':
        return (Icons.table_chart_rounded, const Color(0xFF16A34A));
      case 'ppt':
      case 'pptx':
        return (Icons.slideshow_rounded, const Color(0xFFF97316));
      case 'zip':
      case 'rar':
      case '7z':
        return (Icons.folder_zip_rounded, const Color(0xFFF59E0B));
      case 'php':
      case 'dart':
      case 'js':
      case 'html':
      case 'css':
      case 'json':
        return (Icons.code_rounded, const Color(0xFF8B5CF6));
      case 'mp3':
      case 'wav':
      case 'm4a':
        return (Icons.audiotrack_rounded, const Color(0xFFEC4899));
      default:
        return (Icons.insert_drive_file_rounded, const Color(0xFF64748B));
    }
  }

  Widget _filesList(List<MessageModel> files) {
    if (files.isEmpty) {
      return _empty(Icons.folder_open_rounded, 'No files yet',
          'Documents and files sent in this chat\nwill show up here.');
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = files[i];
        final name = _fileName(m);
        final url =
            (m.fileUrl != null && m.fileUrl!.isNotEmpty) ? m.fileUrl! : m.text;
        final size = _size(m.fileSize);
        final (icon, color) = _fileStyle(name);

        return Material(
          color: _soft,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _open(url),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _ink),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (size.isNotEmpty) size,
                            _who(m.senderId),
                            _date(m.timestamp),
                          ].join('  •  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.download_rounded,
                        size: 18, color: _blue),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ links

  List<_Link> _extractLinks(List<MessageModel> messages) {
    final links = <_Link>[];
    for (final m in messages) {
      // images, files, audio, video and stickers also keep a URL in `text`,
      // so only plain text messages are scanned
      if (m.type != 'text' && m.type.isNotEmpty) continue;

      for (final match in _urlRegex.allMatches(m.text)) {
        var url = match.group(0)!;
        url = url.replaceAll(RegExp(r'[)\]}>,.;:!?]+$'), '');
        if (url.isEmpty) continue;
        links.add(_Link(url, m.timestamp, _who(m.senderId)));
      }
    }
    return links; // already newest first
  }

  String _domain(String url) {
    final host = _toUri(url)?.host ?? '';
    if (host.isEmpty) return url;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  Color _colorFor(String text) {
    const palette = [
      Color(0xFF2563EB),
      Color(0xFF8B5CF6),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFF97316),
      Color(0xFFEC4899),
    ];
    return palette[text.hashCode.abs() % palette.length];
  }

  Widget _linksList(List<_Link> links) {
    if (links.isEmpty) {
      return _empty(Icons.link_rounded, 'No links yet',
          'Links sent in this chat\nwill show up here.');
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: links.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final l = links[i];
        final domain = _domain(l.url);
        final color = _colorFor(domain);

        return Material(
          color: _soft,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _open(l.url),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: l.url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied')),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      domain.isEmpty ? '?' : domain[0].toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: _blue),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l.sender}  •  ${_date(l.time)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.open_in_new_rounded,
                        size: 17, color: _blue),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Link {
  final String url;
  final DateTime time;
  final String sender;
  const _Link(this.url, this.time, this.sender);
}