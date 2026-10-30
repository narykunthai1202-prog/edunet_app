import 'package:edunest_app/features/post/domain/entities/post.dart';

abstract class ArchiveState {}

class ArchiveInitialState extends ArchiveState {}

class ArchiveLoadingState extends ArchiveState {}

class ArchiveLoadedState extends ArchiveState {
  final List<Post> deletedPosts;
  final List<Post> likedPosts;

  ArchiveLoadedState({
    required this.deletedPosts,
    required this.likedPosts,
  });

  ArchiveLoadedState copyWith({
    List<Post>? deletedPosts,
    List<Post>? likedPosts,
  }) {
    return ArchiveLoadedState(
      deletedPosts: deletedPosts ?? this.deletedPosts,
      likedPosts: likedPosts ?? this.likedPosts,
    );
  }
}

class ArchiveActionSuccessState extends ArchiveState {
  final String message;
  final List<Post> deletedPosts;
  final List<Post> likedPosts;

  ArchiveActionSuccessState({
    required this.message,
    required this.deletedPosts,
    required this.likedPosts,
  });
}

class ArchiveErrorState extends ArchiveState {
  final String message;
  ArchiveErrorState({required this.message});
}
