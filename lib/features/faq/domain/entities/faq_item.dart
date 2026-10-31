class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String category;
  final List<String> tags;
  int helpfulCount;
  int unhelpfulCount;
  bool? userVote; // true for helpful, false for unhelpful, null for none

  FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.tags = const [],
    this.helpfulCount = 0,
    this.unhelpfulCount = 0,
    this.userVote,
  });

  FaqItem copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    List<String>? tags,
    int? helpfulCount,
    int? unhelpfulCount,
    bool? userVote,
  }) {
    return FaqItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      unhelpfulCount: unhelpfulCount ?? this.unhelpfulCount,
      userVote: userVote ?? this.userVote,
    );
  }
}
