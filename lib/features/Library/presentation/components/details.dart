import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class Details extends StatefulWidget {
  final String lessonName; // ចំណងជើងមេរៀន (Title) — ត្រូវបង្ហាញនៅ AppBar
  final String typeName; // Book / Slide / Exercise...
  final String generation; // 16 / 17 / 18...
  final String lessonText;
  final String fileUrl;
  final String detailType; // TEXT / IMAGE / PDF

  const Details({
    super.key,
    required this.lessonName,
    required this.typeName,
    this.generation = '',
    required this.lessonText,
    required this.fileUrl,
    required this.detailType,
  });

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  // ============================================================
  // PDF STATE (សម្រាប់បង្ហាញក្នុង app)
  // ============================================================
  Uint8List? _pdfBytes;
  String? _pdfErrorMessage;
  bool _isPdfLoading = false;

  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();

    final String type = widget.detailType.trim().toUpperCase();
    if (type == "PDF" && hasValidUrl) {
      _isPdfLoading = true;
      _loadPdf();
    }
  }

  // ============================================================
  // CHECK URL VALIDITY
  // ============================================================
  bool get hasValidUrl {
    final url = widget.fileUrl.trim();
    return url.startsWith("http://") || url.startsWith("https://");
  }

  // ============================================================
  // DOWNLOAD PDF FROM CLOUDINARY (ដើម្បីបង្ហាញក្នុង app)
  // ============================================================
  Future<void> _loadPdf() async {
    final String url = widget.fileUrl.trim();

    try {
      final response = await http.get(Uri.parse(url));
      final Uint8List bytes = response.bodyBytes;

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _isPdfLoading = false;
          _pdfErrorMessage = "HTTP ${response.statusCode}";
        });
        return;
      }

      final bool looksLikePdf = bytes.length > 5 &&
          String.fromCharCodes(bytes.sublist(0, 5)) == "%PDF-";

      if (!looksLikePdf) {
        setState(() {
          _isPdfLoading = false;
          _pdfErrorMessage = "Server មិនបានផ្ញើ PDF មកទេ";
        });
        return;
      }

      setState(() {
        _pdfBytes = bytes;
        _isPdfLoading = false;
      });
    } catch (e) {
      debugPrint("❌ PDF download error: $e");
      if (!mounted) return;
      setState(() {
        _isPdfLoading = false;
        _pdfErrorMessage = "មិនអាចទាញយក PDF បាន: $e";
      });
    }
  }

  // ============================================================
  // OPEN / DOWNLOAD PDF (ប្រើ url_launcher — ដំណើរការដូចគ្នា
  // ទាំង Web និង Mobile, គ្មាន file_picker/dart:html ត្រូវការ)
  // ============================================================
  Future<void> _openPdfExternally() async {
    final Uri uri = Uri.parse(widget.fileUrl.trim());

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("មិនអាចបើក PDF បានទេ")),
        );
      }
    } catch (e) {
      debugPrint("❌ Open PDF error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("មិនអាចបើក PDF បាន: $e")),
      );
    }
  }

  // ============================================================
  // PDF VIEWER (full width, no card, with page counter overlay)
  // ============================================================
  Widget _buildPdfViewer() {
    final String fileUrl = widget.fileUrl.trim();

    if (!hasValidUrl) {
      return _buildErrorState(
        icon: Icons.picture_as_pdf_outlined,
        title: "គ្មាន URL PDF",
        message: "មិនអាចស្វែងរក Link របស់ PDF បានទេ",
      );
    }

    if (_isPdfLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyan),
      );
    }

    if (_pdfErrorMessage != null || _pdfBytes == null) {
      return _buildErrorState(
        icon: Icons.picture_as_pdf_outlined,
        title: "មិនអាចបើក PDF បាន!",
        message: "${_pdfErrorMessage ?? 'Unknown error'}\n\n$fileUrl",
      );
    }

    return Stack(
      children: [
        SfPdfViewer.memory(
          _pdfBytes!,
          controller: _pdfController,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() => _totalPages = details.document.pages.count);
          },
          onPageChanged: (PdfPageChangedDetails details) {
            setState(() => _currentPage = details.newPageNumber);
          },
        ),

        // Page counter (ដូច "1/20" ក្នុង mockup)
        if (_totalPages > 0)
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$_currentPage/$_totalPages",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CONTENT (Text / Image) — used only for non-PDF lesson types
  // ============================================================
  Widget _buildTextOrImageContent() {
    final String type = widget.detailType.trim().toUpperCase();
    final String fileUrl = widget.fileUrl.trim();

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

    if (type == "IMAGE") {
      if (!hasValidUrl) {
        return _buildErrorState(
          icon: Icons.image_not_supported_outlined,
          title: "គ្មាន URL រូបភាព",
          message: "សូមពិនិត្យមើល URL នៅក្នុង Firestore ឡើងវិញ",
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          fileUrl,
          width: double.infinity,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(color: Colors.cyan),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorState(
              icon: Icons.broken_image_outlined,
              title: "មិនអាចបង្ហាញរូបភាពបាន!",
              message: fileUrl,
            );
          },
        ),
      );
    }

    return _buildErrorState(
      icon: Icons.help_outline,
      title: "ប្រភេទមេរៀនមិនត្រឹមត្រូវ",
      message: "LessonType: ${widget.detailType}",
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 55, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            SelectableText(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitleText {
    final parts = <String>[
      widget.typeName,
      if (widget.generation.trim().isNotEmpty)
        'ជំនាន់ទី${widget.generation.trim()}',
    ];
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final String type = widget.detailType.trim().toUpperCase();
    final bool isPdf = type == "PDF";

    return Scaffold(
      backgroundColor: isPdf ? Colors.black12 : const Color(0xFFFFFDFB),

      // ================================================================
      // AppBar: ចំណងជើងមេរៀន (Title) នៅលើគេ, Type/Generation ជា subtitle
      // ================================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lessonName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              _subtitleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Download/Open button — មានតែពេលជា PDF
          if (isPdf && hasValidUrl)
            IconButton(
              tooltip: "ទាញយក PDF",
              onPressed: _openPdfExternally,
              icon: const Icon(Icons.download_outlined, color: Colors.black87),
            ),
          const SizedBox(width: 8),
        ],
      ),

      // ================================================================
      // BODY
      // ================================================================
      body: isPdf
          // PDF: ពេញអេក្រង់ គ្មាន card, គ្មាន title ស្ទួន (Title នៅ AppBar ហើយ)
          ? SafeArea(child: _buildPdfViewer())

          // TEXT / IMAGE: រក្សាទុករចនាប័ទ្មកាតដូចដើម
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildTextOrImageContent(),
                  ),
                ),
              ),
            ),
    );
  }
}