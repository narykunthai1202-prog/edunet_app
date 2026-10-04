import 'package:edunest_app/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class Details extends StatefulWidget {
  final String lessonName;
  final String typeName;
  final String lessonText;
  final String fileUrl;
  final String detailType;

  const Details({
    super.key,
    required this.lessonName,
    required this.typeName,
    required this.lessonText,
    required this.fileUrl,
    required this.detailType,
  });

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  // ============================================================
  // CHECK URL
  // ============================================================

  bool get hasValidUrl {
    final url = widget.fileUrl.trim();

    return url.startsWith("http://") || url.startsWith("https://");
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    final String type = widget.detailType.trim().toUpperCase();

    final String fileUrl = widget.fileUrl.trim();

    debugPrint("======================================");
    debugPrint("Lesson Name : ${widget.lessonName}");
    debugPrint("Detail Type : $type");
    debugPrint("File URL    : $fileUrl");
    debugPrint("======================================");

    // ==========================================================
    // TEXT
    // ==========================================================

    if (type == "TEXT") {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.lessonText.trim().isNotEmpty
              ? widget.lessonText
              : "គ្មានខ្លឹមសារអត្ថបទឡើយ។",
          style: const TextStyle(
            fontSize: 16,
            height: 1.7,
            color: Colors.black87,
          ),
          textAlign: TextAlign.justify,
        ),
      );
    }

    // ==========================================================
    // IMAGE
    // ==========================================================

    if (type == "IMAGE") {
      if (!hasValidUrl) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
                SizedBox(height: 10),
                Text(
                  "គ្មាន URL រូបភាព",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          fileUrl,
          width: double.infinity,
          fit: BoxFit.contain,

          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          },

          errorBuilder: (context, error, stackTrace) {
            debugPrint("❌ Image Error: $error");

            debugPrint("❌ Image URL: $fileUrl");

            return Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "មិនអាចបង្ហាញរូបភាពបាន!",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    fileUrl,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // ==========================================================
    // PDF
    // ==========================================================

    if (type == "PDF") {
      if (!hasValidUrl) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
                SizedBox(height: 10),
                Text(
                  "គ្មាន URL PDF",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }

      debugPrint("📄 Loading PDF: $fileUrl");

      return SizedBox(
        height: 600,

        child: SfPdfViewer.network(
          fileUrl,

          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            debugPrint("✅ PDF loaded successfully!");
          },

          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            debugPrint("❌ PDF Load Failed");

            debugPrint("Description: ${details.description}");

            debugPrint("Error: ${details.error}");
          },
        ),
      );
    }

    // ==========================================================
    // UNKNOWN TYPE
    // ==========================================================

    return Center(
      child: Column(
        children: [
          const Icon(Icons.help_outline, size: 60, color: Colors.orange),

          const SizedBox(height: 10),

          Text(
            "ប្រភេទមេរៀនមិនត្រឹមត្រូវ",
            style: const TextStyle(color: Colors.orange, fontSize: 16),
          ),

          const SizedBox(height: 5),

          Text(
            "LessonType: ${widget.detailType}",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String type = widget.detailType.trim().toUpperCase();

    String formatKhmer;

    if (type == "IMAGE") {
      formatKhmer = "រូបភាព";
    } else if (type == "PDF") {
      formatKhmer = "ឯកសារ PDF";
    } else {
      formatKhmer = "អត្ថបទ";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFB),

      appBar: AppBar(
        title: Text(widget.typeName, style: AppWidget.HeadLineTextFeildStyle()),

        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),

          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.all(22),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(15),

            border: Border.all(color: Colors.grey.shade200),
          ),

          child: SingleChildScrollView(
            child: Column(
              children: [
                // Lesson Name
                Text(
                  widget.lessonName,

                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),

                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                // Type
                Text(
                  "ទម្រង់មេរៀន៖ $formatKhmer",

                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),

                const Divider(
                  height: 30,
                  thickness: 1,
                  color: Color(0xFFF0F0F0),
                ),

                // Content
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
