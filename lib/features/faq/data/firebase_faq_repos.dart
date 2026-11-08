import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/faq/data/faq_data.dart';
import 'package:edunest_app/features/faq/domain/entities/faq_item.dart';
import 'package:edunest_app/features/faq/domain/repos/faq_repos.dart';

class FirebaseFaqRepository implements FaqRepo {
  FirebaseFaqRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<List<FaqItem>> getFaqs() async {
    try {
      await _seedFaqsIfCollectionIsEmpty();
      final querySnapshot = await _firestore.collection('faqs').get();
      return await Future.wait(querySnapshot.docs.map(_faqFromDocument));
    } catch (error) {
      throw Exception('Failed to fetch FAQs: $error');
    }
  }

  @override
  Future<List<FaqItem>> getFaqsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('faqs')
          .where('category', isEqualTo: category)
          .get();
      return await Future.wait(querySnapshot.docs.map(_faqFromDocument));
    } catch (error) {
      throw Exception('Failed to fetch FAQs by category: $error');
    }
  }

  @override
  Future<List<FaqItem>> searchFaqs(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('faqs')
          .where('question', isGreaterThanOrEqualTo: query)
          .where('question', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return await Future.wait(querySnapshot.docs.map(_faqFromDocument));
    } catch (error) {
      throw Exception('Failed to search FAQs: $error');
    }
  }

  @override
  Future<FaqItem> voteFaq(FaqItem faq, bool isHelpful) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('Sign in to submit FAQ feedback.');
    }

    final faqReference = _firestore.collection('faqs').doc(faq.id);
    final voteReference = faqReference.collection('votes').doc(userId);

    try {
      return await _firestore.runTransaction((transaction) async {
        final faqSnapshot = await transaction.get(faqReference);
        final voteSnapshot = await transaction.get(voteReference);
        if (!faqSnapshot.exists) {
          throw StateError('This FAQ no longer exists.');
        }

        final data = faqSnapshot.data()!;
        var helpfulCount = (data['helpfulCount'] as num?)?.toInt() ?? 0;
        var unhelpfulCount = (data['unhelpfulCount'] as num?)?.toInt() ?? 0;
        final previousVote = voteSnapshot.data()?['isHelpful'] as bool?;

        if (previousVote != isHelpful) {
          if (previousVote == true) helpfulCount--;
          if (previousVote == false) unhelpfulCount--;
          if (isHelpful) {
            helpfulCount++;
          } else {
            unhelpfulCount++;
          }

          transaction.update(faqReference, {
            'helpfulCount': helpfulCount,
            'unhelpfulCount': unhelpfulCount,
          });
          transaction.set(voteReference, {
            'isHelpful': isHelpful,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        return faq.copyWith(
          helpfulCount: helpfulCount,
          unhelpfulCount: unhelpfulCount,
          userVote: isHelpful,
        );
      });
    } catch (error) {
      throw Exception('Failed to save FAQ feedback: $error');
    }
  }

  Future<void> _seedFaqsIfCollectionIsEmpty() async {
    final collection = _firestore.collection('faqs');
    final existingFaqs = await collection.limit(1).get();
    if (existingFaqs.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final faq in initialFaqData) {
      batch.set(collection.doc(faq.id), {
        'question': faq.question,
        'answer': faq.answer,
        'category': faq.category,
        'tags': faq.tags,
        'helpfulCount': faq.helpfulCount,
        'unhelpfulCount': faq.unhelpfulCount,
      });
    }
    await batch.commit();
  }

  Future<FaqItem> _faqFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();
    final userId = _auth.currentUser?.uid;
    bool? userVote;
    if (userId != null) {
      final voteSnapshot = await document.reference
          .collection('votes')
          .doc(userId)
          .get();
      userVote = voteSnapshot.data()?['isHelpful'] as bool?;
    }

    return FaqItem(
      id: document.id,
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      category: data['category'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>? ?? []).whereType<String>().toList(),
      helpfulCount: (data['helpfulCount'] as num?)?.toInt() ?? 0,
      unhelpfulCount: (data['unhelpfulCount'] as num?)?.toInt() ?? 0,
      userVote: userVote,
    );
  }
}
