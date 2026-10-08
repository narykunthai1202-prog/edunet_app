import 'package:edunest_app/features/post/domain/entities/comment.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';

abstract class PostRepo {
  Future<List<Post>> fetchAllPosts();
  Future<void> createPost(Post post);
  Future<void> deletePost(String postId);
  Future<List<Post>> fetchPostsByUserId(String userId);

  // Post like
  Future<void> toggleLikePost(String postId, String userId);

  // Comments
  Future<void> addComment(String postId, Comment comment);
  Future<void> deleteComment(String postId, String commentId);

  // Comment reaction
  Future<void> toggleCommentReaction(
    String postId,
    String commentId,
    String userId,
  );

  // Comment reply
  Future<void> addReply(
    String postId,
    String commentId,
    Comment reply,
  );

  Future<void> deleteReply(
    String postId,
    String commentId,
    String replyId,
  );

  // Following / Public posts
  Future<List<Post>> fetchpostbyfollowing(String userId);
  Future<List<Post>> fetchpostbypublic();

  // Saved posts
  Future<void> toggleSavedPost(String postId, String userId);
  Future<List<Post>> fetchSavedPosts(String userId);
  Future<bool> isPostSaved(String postId, String userId);

  // Profile privacy
  Future<List<Post>> fetchVisiblePostsByUserId(
    String profileUserId,
    String? viewerUserId,
  );

  // Edit post
  Future<void> editPost(Post post);
}