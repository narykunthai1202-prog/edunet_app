import 'package:edunest_app/features/post/domain/entities/comment.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';

abstract class PostRepo {
  Future<List<Post>> fetchAllPosts();
  Future<void> createPost(Post post);
  Future<void> deletePost(String postId);
  Future<List<Post>> fetchPostsByUserId(String userId);
  Future<void> toggleLikePost(String postId, String userId);
  Future<void> addComment(String postId, Comment comment);
  Future<void> deleteComment(String postId, String commentId);
  Future<List<Post>> fetchpostbyfollowing(String userId);
  Future<List<Post>> fetchpostbypublic();
  // saved posts
  Future<void> toggleSavedPost(String postId, String userId);
  Future<List<Post>> fetchSavedPosts(String userId);
  Future<bool> isPostSaved(String postId, String userId);
  Future<List<Post>> fetchVisiblePostsByUserId(
  String profileUserId,
  String? viewerUserId,);
  Future<void> editPost(Post post);
}
