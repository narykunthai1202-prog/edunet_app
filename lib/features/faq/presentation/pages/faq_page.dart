import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../data/faq_data.dart';
import '../../domain/entities/faq_item.dart';
import '../components/contact_support_card.dart';
import '../components/faq_tile.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final TextEditingController _searchController = TextEditingController();
  List<FaqItem> _faqList = [];
  String _selectedCategory = FaqCategories.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _faqList = List.from(initialFaqData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqItem> get _filteredFaqs {
    return _faqList.where((item) {
      final matchesCategory = _selectedCategory == FaqCategories.all ||
          item.category == _selectedCategory;

      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) {
        return matchesCategory;
      }

      final matchesQuestion = item.question.toLowerCase().contains(query);
      final matchesAnswer = item.answer.toLowerCase().contains(query);
      final matchesTags = item.tags.any((tag) => tag.toLowerCase().contains(query));

      return matchesCategory && (matchesQuestion || matchesAnswer || matchesTags);
    }).toList();
  }

  void _handleVote(FaqItem item, bool isHelpful) {
    setState(() {
      item.userVote = isHelpful;
      if (isHelpful) {
        item.helpfulCount += 1;
      } else {
        item.unhelpfulCount += 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHelpful
              ? 'Thank you! Marked as helpful.'
              : 'Thank you for your feedback.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredFaqs;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.inversePrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FAQ & Help Center',
          style: TextStyle(
            color: colorScheme.inversePrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Header description
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Find quick answers to common questions about your EduNest account, classes, posts, and security.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242227) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : colorScheme.outline.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.inversePrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search questions, keywords, or topics...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: colorScheme.secondary,
                        ),
                        prefixIcon: Icon(
                          Iconsax.search_normal_1,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories Horizontal Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: FaqCategories.list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = FaqCategories.list[index];
                  final isSelected = _selectedCategory == cat;

                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : colorScheme.inversePrimary,
                    ),
                    selectedColor: colorScheme.primary,
                    backgroundColor: isDark
                        ? const Color(0xFF2B282D)
                        : colorScheme.surface,
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : colorScheme.outline.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),
          ),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} questions found',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.secondary,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty ||
                      _selectedCategory != FaqCategories.all) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedCategory = FaqCategories.all;
                        });
                      },
                      child: Text(
                        'Reset filters',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // FAQ List or Empty State
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242227) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.search_status,
                      size: 48,
                      color: colorScheme.secondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No matching questions found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try searching with different terms or select "All" categories.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedCategory = FaqCategories.all;
                        });
                      },
                      child: const Text('Show All Questions'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return FaqTile(
                      key: ValueKey(item.id),
                      item: item,
                      onVote: (isHelpful) => _handleVote(item, isHelpful),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),

          // Contact Support Card
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: ContactSupportCard(),
            ),
          ),
        ],
      ),
    );
  }
}
