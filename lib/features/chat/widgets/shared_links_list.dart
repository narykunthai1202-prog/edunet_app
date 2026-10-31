import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class _SharedLink {
  final String url;
  final DateTime time;
  final bool sentByMe;
  const _SharedLink(this.url, this.time, this.sentByMe);
}

/// Shows every link (http://, https:// or www.) found in the TEXT messages
/// of a 1-to-1 chat. Use it inside the "Links" tab of the profile screen.
class SharedLinksList extends StatefulWidget {
  const SharedLinksList({
    super.key,
    required this.currentUserId,
    required this.receiverId,
  });

  final String currentUserId;
  final String receiverId;

  @override
  State<SharedLinksList> createState() => _SharedLinksListState();
}

class _SharedLinksListState extends State<SharedLinksList> {
  late final Stream<List<MessageModel>> _stream;

  static final RegExp _urlRegex = RegExp(
    r'((https?:\/\/)|(www\.))[^\s]+',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _stream = ChatService()
        .getMessagesStream(widget.currentUserId, widget.receiverId);
  }

  List<_SharedLink> _extract(List<MessageModel> messages) {
    final links = <_SharedLink>[];

    for (final m in messages) {
      // Only normal text messages. Images, files, audio, video and stickers
      // also store a URL in `text`, so they must be skipped.
      if (m.isDeleted) continue;
      if (m.type != 'text' && m.type.isNotEmpty) continue;

      for (final match in _urlRegex.allMatches(m.text)) {
        var url = match.group(0)!;
        // remove punctuation that is usually not part of the link
        url = url.replaceAll(RegExp(r'[)\]}>,.;:!?]+$'), '');
        if (url.isEmpty) continue;
        links.add(_SharedLink(url, m.timestamp, m.senderId == widget.currentUserId));
      }
    }

    links.sort((a, b) => b.time.compareTo(a.time)); // newest first
    return links;
  }

  Uri? _toUri(String url) {
    final fixed = url.toLowerCase().startsWith('www.') ? 'https://$url' : url;
    return Uri.tryParse(fixed);
  }

  String _domainOf(String url) {
    final uri = _toUri(url);
    final host = uri?.host ?? '';
    if (host.isEmpty) return url;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  String _dateOf(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MessageModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final links = _extract(snapshot.data ?? []);

        if (links.isEmpty) {
          return const Center(
            child: Text(
              'No links shared yet',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: links.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final link = links[i];

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
                child: const Icon(Icons.link_rounded,
                    color: Color(0xFF2563EB), size: 22),
              ),
              title: Text(
                _domainOf(link.url),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                '${link.url}\n${link.sentByMe ? 'You' : 'Them'} • ${_dateOf(link.time)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.open_in_new_rounded,
                  size: 18, color: Colors.grey),
              onTap: () {
                final uri = _toUri(link.url);
                if (uri == null) return;
                launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: link.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')),
                );
              },
            );
          },
        );
      },
    );
  }
}