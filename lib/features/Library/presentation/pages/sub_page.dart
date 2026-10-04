import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/Library/presentation/components/details.dart';
import 'package:edunest_app/widget/widget_support.dart';
import 'package:flutter/material.dart';

class SubPage extends StatefulWidget {
  final String subjectId;
  final String categoryName;
  final int level;

  const SubPage({
    super.key,
    required this.subjectId,
    required this.categoryName,
    this.level = 1,
  });

  @override
  State<SubPage> createState() => _SubPageState();
}

class _SubPageState extends State<SubPage> {
  Stream<QuerySnapshot>? categoryItemStream;

  // LOAD LESSON DATA

  void getOnTheLoad() {
    if (widget.level == 1) {
      // Level 1: Library -> Subject -> Lessons
      categoryItemStream = FirebaseFirestore.instance
          .collection('library')
          .doc(widget.subjectId)
          .collection('Lessons')
          .snapshots();
    } else if (widget.level == 2) {
      // Level 2: Filter by SubCategory1
      categoryItemStream = FirebaseFirestore.instance
          .collection('library')
          .doc(widget.subjectId)
          .collection('Lessons')
          .where('SubCategory1', isEqualTo: widget.categoryName)
          .snapshots();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    getOnTheLoad();
  }
  // SHOW LESSONS / SUB CATEGORIES

  Widget allItemsVertically() {
    if (categoryItemStream == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

    return StreamBuilder<QuerySnapshot>(
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

        final docs = snapshot.data!.docs;

        // ======================================================
        // REMOVE DUPLICATES
        // ======================================================

        final List<Map<String, dynamic>> displayedList = [];
        final Set<String> uniqueTracker = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (widget.level == 1) {
            final String sub1 = data['SubCategory1']?.toString() ?? '';

            if (sub1.isNotEmpty && !uniqueTracker.contains(sub1)) {
              uniqueTracker.add(sub1);

              displayedList.add({
                'name': sub1,
                'nextAction': 'TO_SUBCAT2',
                'data': data,
              });
            }
          } else if (widget.level == 2) {
            final String sub2 = data['SubCategory2']?.toString() ?? '';

            if (sub2.isNotEmpty && !uniqueTracker.contains(sub2)) {
              uniqueTracker.add(sub2);

              displayedList.add({
                'name': sub2,
                'nextAction': 'TO_DETAIL',
                'data': data,
              });
            }
          }
        }

        if (displayedList.isEmpty) {
          return _buildMessage(
            icon: Icons.menu_book_outlined,
            message: 'មិនមានមេរៀនទេ!',
            color: Colors.grey,
          );
        }

        // ======================================================
        // HEADER + LIST
        // ======================================================

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Added',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  'Total: ${displayedList.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: displayedList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),

              itemBuilder: (context, index) {
                final item = displayedList[index];

                return _buildLessonCard(
                  name: item['name'].toString(),
                  nextAction: item['nextAction'].toString(),
                  data: item['data'] as Map<String, dynamic>,
                  index: index,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLessonCard({
    required String name,
    required String nextAction,
    required Map<String, dynamic> data,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(15),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(15),

        onTap: () {
          if (nextAction == 'TO_SUBCAT2') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubPage(
                  subjectId: widget.subjectId,
                  categoryName: name,
                  level: 2,
                ),
              ),
            );
          } else if (nextAction == 'TO_DETAIL') {
            final String lessonName =
                data['SubCategory2']?.toString() ?? 'Untitled';

            final String typeName =
                data['SubCategory1']?.toString() ?? 'General';

            final String lessonType =
                data['LessonType']?.toString().trim() ?? 'TEXT';

            final String detail = data['Detail']?.toString().trim() ?? '';

            debugPrint('======================================');
            debugPrint('📚 Lesson Name: $lessonName');
            debugPrint('📂 Type Name: $typeName');
            debugPrint('📄 Lesson Type: $lessonType');
            debugPrint('🔗 Detail: $detail');
            debugPrint('======================================');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Details(
                  typeName: typeName,
                  lessonName: lessonName,
                  detailType: lessonType,
                  lessonText: lessonType.toUpperCase() == 'TEXT' ? detail : '',
                  fileUrl:
                      (lessonType.toUpperCase() == 'IMAGE' ||
                          lessonType.toUpperCase() == 'PDF')
                      ? detail
                      : '',
                ),
              ),
            );
          }
        },

        child: Padding(
          padding: const EdgeInsets.all(15),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 50,
                    width: 50,

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Icon(
                      Icons.menu_book_outlined,
                      size: 30,
                      color: Colors.black54,
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 17,
                    color: Colors.black45,
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Tap to view lesson',
                    style: TextStyle(color: Colors.black38, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color),

          const SizedBox(height: 10),

          Text(message, style: TextStyle(color: color, fontSize: 16)),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          widget.categoryName,
          style: AppWidget.HeadLineTextFeildStyle(),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: allItemsVertically(),
      ),
    );
  }
}
