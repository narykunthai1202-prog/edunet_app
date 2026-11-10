
import 'package:edunest_app/features/faq/domain/entities/faq_item.dart';

abstract class FaqState {}

class FaqInitial extends FaqState {}

class FaqLoading extends FaqState {}

class FaqLoaded extends FaqState {
  final List<FaqItem> faqs;

  FaqLoaded(this.faqs);
}

class FaqError extends FaqState {
  final String message;

  FaqError(this.message);
}
