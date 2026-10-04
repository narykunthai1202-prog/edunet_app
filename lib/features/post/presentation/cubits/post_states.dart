import 'package:edunest_app/features/post/domain/entities/post.dart';

abstract class PostState {}

//initial state
class PostInitialState extends PostState {}

//loading state
class PostLoadingState extends PostState {}

//uploading state
class PostUploadingState extends PostState {}

//error state
class PostErrorState extends PostState {
  final String message;
  PostErrorState({required this.message});
}

//loaded state
class PostLoadedState extends PostState {
  final List<Post> posts;
  PostLoadedState({required this.posts});
}
