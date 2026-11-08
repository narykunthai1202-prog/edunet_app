import 'package:edunest_app/features/faq/domain/entities/faq_item.dart';

abstract class FaqRepo {
  Future<List<FaqItem>> getFaqs();
  Future<List<FaqItem>> getFaqsByCategory(String category);
  Future<List<FaqItem>> searchFaqs(String query);
  Future<FaqItem> voteFaq(FaqItem faq, bool isHelpful);
}