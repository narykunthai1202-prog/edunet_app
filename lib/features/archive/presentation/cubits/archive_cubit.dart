import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';
import 'package:edunest_app/features/post/domain/repos/post_repos.dart';
import 'archive_states.dart';

class ArchiveCubit extends Cubit<ArchiveState> {
  final PostRepo postRepo;

  ArchiveCubit({required this.postRepo}) : super(ArchiveInitialState());

  List<Post> _deletedPosts = [];
  List<Post> _likedPosts = [];

  Future<void> fetchArchive(String userId) async {
    try {
      emit(ArchiveLoadingState());

      final results = await Future.wait([
        postRepo.fetchRecentlyDeletedPosts(userId),
        postRepo.fetchLikedPosts(userId),
      ]);

      _deletedPosts = results[0];
      _likedPosts = results[1];

      emit(ArchiveLoadedState(
        deletedPosts: _deletedPosts,
        likedPosts: _likedPosts,
      ));
    } catch (e) {
      emit(ArchiveErrorState(message: e.toString()));
    }
  }

  Future<void> restorePost(String postId, String userId) async {
    try {
      await postRepo.restorePost(postId, userId);
      _deletedPosts.removeWhere((p) => p.id == postId);

      emit(ArchiveActionSuccessState(
        message: 'Post restored successfully to your profile and feed.',
        deletedPosts: List.from(_deletedPosts),
        likedPosts: List.from(_likedPosts),
      ));

      emit(ArchiveLoadedState(
        deletedPosts: List.from(_deletedPosts),
        likedPosts: List.from(_likedPosts),
      ));
    } catch (e) {
      emit(ArchiveErrorState(message: 'Failed to restore post: $e'));
    }
  }

  Future<void> permanentlyDeletePost(String postId, String userId) async {
    try {
      await postRepo.permanentlyDeletePost(postId, userId);
      _deletedPosts.removeWhere((p) => p.id == postId);

      emit(ArchiveActionSuccessState(
        message: 'Post permanently deleted.',
        deletedPosts: List.from(_deletedPosts),
        likedPosts: List.from(_likedPosts),
      ));

      emit(ArchiveLoadedState(
        deletedPosts: List.from(_deletedPosts),
        likedPosts: List.from(_likedPosts),
      ));
    } catch (e) {
      emit(ArchiveErrorState(message: 'Failed to permanently delete post: $e'));
    }
  }

  Future<void> unlikePost(Post post, String userId) async {
    try {
      await postRepo.toggleLikePost(post.id, userId);
      _likedPosts.removeWhere((p) => p.id == post.id);

      emit(ArchiveLoadedState(
        deletedPosts: List.from(_deletedPosts),
        likedPosts: List.from(_likedPosts),
      ));
    } catch (e) {
      emit(ArchiveErrorState(message: 'Failed to update like status: $e'));
    }
  }
}
