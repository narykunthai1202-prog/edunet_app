import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Reads every file inside assets/stickers/ (no hard-coded names needed).
Future<List<String>> _loadStickerPaths() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final paths = manifest
      .listAssets()
      .where((p) => p.startsWith('assets/stickers/'))
      .toList()
    ..sort();
  return paths;
}

/// Emoji + Sticker panel shown under the input field.
class EmojiStickerPanel extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onStickerSelected;

  const EmojiStickerPanel({
    super.key,
    required this.controller,
    required this.onStickerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xFF2563EB),
              unselectedLabelColor: Color(0xFF94A3B8),
              indicatorColor: Color(0xFF2563EB),
              tabs: [
                Tab(icon: Icon(Icons.emoji_emotions_outlined)),
                Tab(icon: Icon(Icons.sticky_note_2_outlined)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // 1. Emoji
                  EmojiPicker(
                    textEditingController: controller,
                    config: const Config(height: 256),
                  ),

                  // 2. Stickers (loaded from the asset folder)
                  FutureBuilder<List<String>>(
                    future: _loadStickerPaths(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final stickers = snap.data!;
                      if (stickers.isEmpty) {
                        return const Center(
                          child: Text(
                            'No stickers found',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: stickers.length,
                        itemBuilder: (_, i) => InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onStickerSelected(stickers[i]),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              stickers[i],
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticker message: image without a bubble background.
class StickerBubble extends StatelessWidget {
  final String path;
  const StickerBubble({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: 130,
      height: 130,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox(
        width: 130,
        height: 130,
        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }
}

/// Video message: thumbnail with play button, tap to open full player.
class VideoBubble extends StatefulWidget {
  final String url;
  const VideoBubble({super.key, required this.url});

  @override
  State<VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<VideoBubble> {
  late final VideoPlayerController _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPlayerPage(url: widget.url)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 220,
          height: 220,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_ready)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _c.value.size.width,
                    height: _c.value.size.height,
                    child: VideoPlayer(_c),
                  ),
                )
              else
                const CircularProgressIndicator(color: Colors.white),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 34),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen video player.
class VideoPlayerPage extends StatefulWidget {
  final String url;
  const VideoPlayerPage({super.key, required this.url});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerController _c;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _c.play();
        }
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _c.value.isInitialized
            ? AspectRatio(
                aspectRatio: _c.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_c),
                    VideoProgressIndicator(_c, allowScrubbing: true),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () =>
            setState(() => _c.value.isPlaying ? _c.pause() : _c.play()),
        child: Icon(_c.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}