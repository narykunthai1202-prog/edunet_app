import 'package:edunest_app/features/faq/domain/entities/faq_item.dart';
import 'package:edunest_app/features/faq/domain/repos/faq_repos.dart';
import 'package:edunest_app/features/faq/presentation/Cubits/faq_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FaqCubit extends Cubit<FaqState> {
  final FaqRepo faqRepo;

  FaqCubit({required this.faqRepo}) : super(FaqInitial());

  Future<void> fetchFaqs() async {
    emit(FaqLoading());
    try {
      final faqs = await faqRepo.getFaqs();
      emit(FaqLoaded(faqs));
    } catch (e) {
      emit(FaqError(e.toString()));
    }
  }

  Future<void> fetchFaqsByCategory(String category) async {
    emit(FaqLoading());
    try {
      final faqsByCategory = await faqRepo.getFaqsByCategory(category);
      emit(FaqLoaded(faqsByCategory));
    } catch (e) {
      emit(FaqError(e.toString()));
    }
  }

  Future<void> searchFaqs(String query) async {
    emit(FaqLoading());
    try {
      final searchResults = await faqRepo.searchFaqs(query);
      emit(FaqLoaded(searchResults));
    } catch (e) {
      emit(FaqError(e.toString()));
    }
  }

  Future<FaqItem> voteFaq(FaqItem faq, bool isHelpful) {
    return faqRepo.voteFaq(faq, isHelpful);
  }
}