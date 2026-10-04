import 'package:edunest_app/features/search/domain/search_repos.dart';
import 'package:edunest_app/features/search/presentation/cubits/search_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchCubit extends Cubit<SearchStates> {
  final SearchRepos searchrepo;
  SearchCubit({required this.searchrepo}) : super(SearchInitial());
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }
    try {
      emit(SearchLoading());
      final users = await searchrepo.searchUsers(query);
      emit(SearchLoaded(users));
    } catch (e) {
      emit(SearchError('Error fetching search result'));
    }
  }
}
