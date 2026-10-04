import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/Library/presentation/components/details.dart';
import 'package:edunest_app/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart' as pdfx;

class SubPage extends StatefulWidget {
  final String subjectId;
  final String categoryName;

  const SubPage({
    super.key,
    required this.subjectId,
    required this.categoryName,
  });

  @override
  State<SubPage> createState() => _SubPageState();
}

// Small internal model so we don't juggle raw Maps everywhere.
class _Lesson {
  final String id;
  final String title;
  final String type; // Book / Slide / Exercise...
  final String generation;
  final String lessonType; // TEXT / IMAGE / PDF
  final String detail;

  _Lesson({
    required this.id,
    required this.title,
    required this.type,
    required this.generation,
    required this.lessonType,
    required this.detail,
  });

  factory _Lesson.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final String title = (data['Title']?.toString().trim().isNotEmpty ?? false)
        ? data['Title'].toString().trim()
        : (data['Type']?.toString() ?? 'Untitled');

    return _Lesson(
      id: doc.id,
      title: title,
      type: data['Type']?.toString().trim().isNotEmpty == true
          ? data['Type'].toString().trim()
          : 'Other',
      generation: data['Generation']?.toString() ??
          data['SubCategory1']?.toString() ??
          '',
      lessonType: data['LessonType']?.toString().trim().toUpperCase() ?? 'TEXT',
      detail: data['Detail']?.toString().trim() ?? '',
    );
  }
}

// ================================================================
// ទំហំ Thumbnail ថេរ ដោយផ្អែកលើ Type (Book / Slide / ផ្សេងទៀត)
//
// - Book & ផ្សេងទៀត -> 150 × 200 (Portrait 3:4)
// - Slide           -> 240 × 135 (Landscape 16:9)
//
// ទំហំទាំងនេះថេរជានិច្ច មិនប្រែប្រួលទៅតាមទំហំពិតរបស់ File ទេ
// (Content ត្រូវបាន Crop ដោយ BoxFit.cover ឲ្យសមនឹងប្រអប់)
// ================================================================
bool isSlideType(String type) {
  return type.toLowerCase().contains('slide') || type.contains('ស្លាយ');
}

({double width, double height}) sizeForType(String type) {
  if (isSlideType(type)) {
    // Landscape 16:9
    return (width: 240.0, height: 135.0);
  }
  // Book & everything else -> Portrait 3:4
  return (width: 150, height: 200);
}

// ================================================================
// SCROLL BEHAVIOR — អនុញ្ញាតឲ្យ Drag ដោយកណ្តុរលើ Web/Desktop
//
// លំនាំដើម Flutter (Web/Desktop) អនុញ្ញាតតែ Touch/Trackpad ក្នុងការ
// អូស ListView ប៉ុណ្ណោះ។ ត្រូវបន្ថែម PointerDeviceKind.mouse ខ្លួនឯង
// ដើម្បីឲ្យអូសដោយកណ្តុរបាន ដោយមិនចាំបាច់ចុចប៊ូតុង ‹ › ជានិច្ច។
// ================================================================
class _DragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

// ================================================================
// PDF THUMBNAIL CACHE
//
// Download + Render ទំព័រទី 1 ជា Image តែម្តងគត់ក្នុងមួយ URL
// (Cache ទុកកុំឲ្យធ្វើម្តងទៀតរាល់ពេល Firestore Update)
// ================================================================
class _PdfThumbnailCache {
  static final Map<String, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> getFirstPageImage(String url) {
    return _cache.putIfAbsent(url, () => _render(url));
  }

  static Future<Uint8List?> _render(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        debugPrint('❌ PDF thumbnail HTTP ${response.statusCode}: $url');
        return null;
      }

      final document = await pdfx.PdfDocument.openData(response.bodyBytes);
      final page = await document.getPage(1);

      final pageImage = await page.render(
        width: page.width * 1.5,
        height: page.height * 1.5,
        format: pdfx.PdfPageImageFormat.png,
      );

      await page.close();
      await document.close();

      return pageImage?.bytes;
    } catch (e) {
      debugPrint('❌ PDF thumbnail render error: $e');
      return null;
    }
  }
}

class _SubPageState extends State<SubPage> {
  Stream<QuerySnapshot>? categoryItemStream;

  // "All" ជា null; បើ User ជ្រើស Type ណាមួយ តម្លៃនោះនឹងស្ថិតនៅទីនេះ
  String? _selectedType;

  final Map<String, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    categoryItemStream = FirebaseFirestore.instance
        .collection('library')
        .doc(widget.subjectId)
        .collection('Lessons')
        .snapshots();
  }

  @override
  void dispose() {
    for (final c in _scrollControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  ScrollController _controllerFor(String group) {
    return _scrollControllers.putIfAbsent(group, () => ScrollController());
  }

  void _scrollBy(String group, double delta) {
    final controller = _controllerFor(group);
    if (!controller.hasClients) return;

    final target = (controller.offset + delta).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );

    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  ({IconData icon, Color color, Color bg}) _formatStyle(String lessonType) {
    switch (lessonType.toUpperCase()) {
      case 'PDF':
        return (
          icon: Icons.picture_as_pdf_outlined,
          color: const Color(0xFFD9534F),
          bg: const Color(0xFFFDECEA),
        );
      case 'IMAGE':
        return (
          icon: Icons.image_outlined,
          color: const Color(0xFF2E9E5B),
          bg: const Color(0xFFEAFAF1),
        );
      default:
        return (
          icon: Icons.article_outlined,
          color: const Color(0xFF3B6FD6),
          bg: const Color(0xFFEAF1FD),
        );
    }
  }

  IconData _typeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('book') || type.contains('សៀវភៅ')) {
      return Icons.menu_book_rounded;
    }
    if (isSlideType(type)) {
      return Icons.slideshow_rounded;
    }
    if (t.contains('exercise') || type.contains('លំហាត់')) {
      return Icons.edit_note_rounded;
    }
    return Icons.folder_rounded;
  }

  // ស្លាយសម្រាប់ Grid ពេលមាន Filter ជ្រើសរើស (មិនមែន All)៖
  // ប៉ាន់ស្មាន Ratio សរុប (រូបភាព + កន្លែងអត្ថបទ ~44px ជា Buffer
  // ដើម្បីការពារ Bottom Overflow) ដោយផ្អែកលើទទឹងគំរូនៃប្រភេទនីមួយៗ
  double _gridAspectRatio(String type) {
    if (isSlideType(type)) {
      // 16:9 image (240×135) + text block
      return 240 / (135 + 44);
    }
    // 3:4 image (150×200) + text block
    return 150 / (200 + 44);
  }

  // Slide បង្ហាញតែ ១ ជួរឈរ (ធំពេញទទឹង) ចំណែក Book/ផ្សេងទៀត បង្ហាញ ២ ជួរឈរ
  int _gridColumnsFor(String type) => isSlideType(type) ? 1 : 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: AppWidget.HeadLineTextFeildStyle(),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: categoryItemStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyan),
              );
            }

            if (snapshot.hasError) {
              debugPrint('Firestore Error: ${snapshot.error}');
              return _buildMessage(
                icon: Icons.error_outline,
                message: 'មានបញ្ហាក្នុងការទាញយកទិន្នន័យ',
                color: Colors.redAccent,
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildMessage(
                icon: Icons.menu_book_outlined,
                message: 'មិនមានទិន្នន័យទេ!',
                color: Colors.grey,
              );
            }

            final lessons =
                snapshot.data!.docs.map(_Lesson.fromDoc).toList();

            final Map<String, List<_Lesson>> grouped = {};
            for (final lesson in lessons) {
              grouped.putIfAbsent(lesson.type, () => []).add(lesson);
            }

            final List<String> allTypes = grouped.keys.toList();

            final String? activeFilter =
                (_selectedType != null && grouped.containsKey(_selectedType))
                    ? _selectedType
                    : null;

            final List<String> visibleTypes =
                activeFilter == null ? allTypes : [activeFilter];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lessons.length} files',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 74,
                          child: ScrollConfiguration(
                            behavior: _DragScrollBehavior(),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _FilterChip(
                                  label: 'All',
                                  icon: Icons.grid_view_rounded,
                                  selected: activeFilter == null,
                                  onTap: () =>
                                      setState(() => _selectedType = null),
                                ),
                                ...allTypes.map(
                                  (type) => _FilterChip(
                                    label: type,
                                    icon: _typeIcon(type),
                                    selected: activeFilter == type,
                                    onTap: () =>
                                        setState(() => _selectedType = type),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (activeFilter == null) ...[
                  // "All" ជ្រើសរើស -> បង្ហាញជា Section ដោយឡែកៗ អូសឆ្វេង/ស្តាំ
                  for (final type in visibleTypes)
                    SliverToBoxAdapter(
                      child: _LessonGroupSection(
                        title: type,
                        lessons: grouped[type]!,
                        categoryName: widget.categoryName,
                        formatStyle: _formatStyle,
                        controller: _controllerFor(type),
                        onScrollLeft: () => _scrollBy(type, -320),
                        onScrollRight: () => _scrollBy(type, 320),
                        onOpen: (lesson) => _openLesson(lesson),
                      ),
                    ),
                ] else ...[
                  // ជ្រើសរើស Filter ណាមួយ (Book / ស្លាយ ...) -> បង្ហាញជា
                  // Grid ២ជួរឈរ អូសលើក្រោមតែម៉្យាង
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridColumnsFor(activeFilter),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: _gridAspectRatio(activeFilter),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final lesson = grouped[activeFilter]![index];
                          return _LessonCard(
                            lesson: lesson,
                            categoryName: widget.categoryName,
                            style: _formatStyle(lesson.lessonType),
                            aspectRatio:
                                isSlideType(activeFilter) ? 16 / 9 : 3 / 4,
                            onTap: () => _openLesson(lesson),
                          );
                        },
                        childCount: grouped[activeFilter]!.length,
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openLesson(_Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Details(
          lessonName: lesson.title,
          typeName: lesson.type,
          generation: lesson.generation,
          detailType: lesson.lessonType,
          lessonText: lesson.lessonType == 'TEXT' ? lesson.detail : '',
          fileUrl: (lesson.lessonType == 'IMAGE' || lesson.lessonType == 'PDF')
              ? lesson.detail
              : '',
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(message, style: TextStyle(color: color, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FILTER CHIP (All / Books / Slides ...)
// ================================================================
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? Colors.cyan.shade50 : Colors.white;
    final Color fg = selected ? Colors.cyan.shade700 : Colors.black54;
    final Color border = selected ? Colors.cyan : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ONE SECTION: "Books" / "Slides" ... + horizontal carousel + ‹ ›
// ================================================================
class _LessonGroupSection extends StatelessWidget {
  final String title;
  final List<_Lesson> lessons;
  final String categoryName;
  final ({IconData icon, Color color, Color bg}) Function(String) formatStyle;
  final ScrollController controller;
  final VoidCallback onScrollLeft;
  final VoidCallback onScrollRight;
  final void Function(_Lesson) onOpen;

  const _LessonGroupSection({
    required this.title,
    required this.lessons,
    required this.categoryName,
    required this.formatStyle,
    required this.controller,
    required this.onScrollLeft,
    required this.onScrollRight,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final size = sizeForType(title);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    _ArrowButton(icon: Icons.chevron_left, onTap: onScrollLeft),
                    const SizedBox(width: 6),
                    _ArrowButton(icon: Icons.chevron_right, onTap: onScrollRight),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // កម្ពស់សរុប = Thumbnail + Spacing + Overline + Title (2 lines)
          SizedBox(
            height: size.height + 70,
            child: ScrollConfiguration(
              behavior: _DragScrollBehavior(),
              child: ListView.separated(
                controller: controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: lessons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  return _LessonCard(
                    lesson: lesson,
                    categoryName: categoryName,
                    style: formatStyle(lesson.lessonType),
                    width: size.width,
                    height: size.height,
                    onTap: () => onOpen(lesson),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 18, color: Colors.black54),
      ),
    );
  }
}

// ================================================================
// ONE CARD: fixed-size thumbnail (per Type) + text below
// ================================================================
class _LessonCard extends StatelessWidget {
  final _Lesson lesson;
  final String categoryName;
  final ({IconData icon, Color color, Color bg}) style;
  final VoidCallback onTap;

  // ប្រើមួយក្នុងចំណោមពីរ៖
  // - width/height ថេរ (pixel) -> សម្រាប់ Carousel អូសឆ្វេង/ស្តាំ (All)
  // - aspectRatio -> សម្រាប់ Grid (ពេលជ្រើស Filter) ដែលទទឹងបត់តាម Column
  final double? width;
  final double? height;
  final double? aspectRatio;

  const _LessonCard({
    required this.lesson,
    required this.categoryName,
    required this.style,
    required this.onTap,
    this.width,
    this.height,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageBox = aspectRatio != null
        ? AspectRatio(
            aspectRatio: aspectRatio!,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _content(),
            ),
          )
        : SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _content(),
            ),
          );

    final Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imageBox,
        const SizedBox(height: 8),
        Text(
          categoryName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.cyan),
        ),
        Text(
          lesson.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      // ពេលមាន width ថេរ (Carousel) ត្រូវរុំ Column ក្នុង SizedBox ដើម្បី
      // កំណត់ទទឹងឲ្យត្រូវនឹងកាត។ ពេល Grid (aspectRatio) ទទឹងបានមកពី Column
      // របស់ Grid រួចហើយ គ្មានតម្រូវការកំណត់ទទឹងទៀតទេ។
      child: width != null ? SizedBox(width: width, child: column) : column,
    );
  }

  // ទំហំ Box ថេររួចហើយ (width × height ពី parent) — Content គ្រាន់តែ
  // Crop ដោយ BoxFit.cover ឲ្យសមតែប៉ុណ្ណោះ គ្មាន Aspect Ratio Detect ទេ
  Widget _content() {
    if (lesson.lessonType == 'IMAGE' && lesson.detail.startsWith('http')) {
      return Image.network(
        lesson.detail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _iconPlaceholder(),
      );
    }

    if (lesson.lessonType == 'PDF' && lesson.detail.startsWith('http')) {
      return FutureBuilder<Uint8List?>(
        future: _PdfThumbnailCache.getFirstPageImage(lesson.detail),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Container(
              color: style.bg,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: style.color,
                  ),
                ),
              ),
            );
          }

          final bytes = snapshot.data;
          if (bytes == null) return _iconPlaceholder();

          return Image.memory(bytes, fit: BoxFit.cover);
        },
      );
    }

    return _iconPlaceholder();
  }

  Widget _iconPlaceholder() {
    return Container(
      color: style.bg,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(style.icon, size: 30, color: style.color),
          const SizedBox(height: 8),
          for (int i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Container(
                height: 4,
                width: i.isEven ? double.infinity : 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}