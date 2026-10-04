import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';

abstract class SearchStates {}

class SearchInitial extends SearchStates {}

class SearchLoading extends SearchStates {}

class SearchLoaded extends SearchStates {
  final List<ProfileUser?> user;
  SearchLoaded(this.user);
}

class SearchError extends SearchStates {
  final String message;
  SearchError(this.message);
}
