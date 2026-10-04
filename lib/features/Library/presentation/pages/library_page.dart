import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/Library/presentation/pages/sub_page.dart';
import 'package:edunest_app/widget/widget_support.dart';
import 'package:flutter/material.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final Stream<QuerySnapshot> _subjectsStream = FirebaseFirestore.instance
      .collection('library')
      .snapshots();

  bool _isValidImageUrl(String value) {
    final url = value.trim();

    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        automaticallyImplyLeading: false,

        title: Text('All Books', style: AppWidget.HeadLineTextFeildStyle()),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: _subjectsStream,

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyan),
              );
            }

            if (snapshot.hasError) {
              debugPrint('Library Firestore Error: ${snapshot.error}');

              return _buildMessage(
                icon: Icons.error_outline,
                message: 'Failed to load subjects.',
                color: Colors.redAccent,
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildMessage(
                icon: Icons.menu_book_outlined,
                message: 'No subjects available.',
                color: Colors.grey,
              );
            }

            final docs = snapshot.data!.docs;

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
                      'Total: ${docs.length}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: GridView.builder(
                    itemCount: docs.length,

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.1,
                        ),

                    itemBuilder: (context, index) {
                      final doc = docs[index];

                      final data = doc.data() as Map<String, dynamic>;

                      final String title =
                          data['Category']?.toString() ?? 'Unknown';

                      final String imageUrl =
                          data['Image']?.toString().trim() ?? '';

                      return _buildSubjectCard(
                        subjectId: doc.id,
                        title: title,
                        imageUrl: imageUrl,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubjectCard({
    required String subjectId,
    required String title,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(15),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(15),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SubPage(subjectId: subjectId, categoryName: title, level: 1),
            ),
          );
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
                  _buildSubjectImage(imageUrl),

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
                    title,
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
                    'Tap to view lessons',
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

  Widget _buildSubjectImage(String imageUrl) {
    if (!_isValidImageUrl(imageUrl)) {
      return Container(
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
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),

      child: Image.network(
        imageUrl,
        height: 50,
        width: 50,
        fit: BoxFit.contain,

        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            height: 50,
            width: 50,
            color: Colors.white,

            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.cyan,
                ),
              ),
            ),
          );
        },

        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 50,
            width: 50,
            color: Colors.white,

            child: const Icon(
              Icons.broken_image_outlined,
              size: 28,
              color: Colors.grey,
            ),
          );
        },
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
}
