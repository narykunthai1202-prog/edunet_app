import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/core/services/cloudinary_services.dart';
import 'package:edunest_app/features/notifications/data/repositories/firebase_notification_repo.dart';
import 'package:edunest_app/features/notifications/domain/entities/notification.dart';
import 'package:edunest_app/features/post/domain/entities/comment.dart';
import 'package:edunest_app/features/profile/domain/repos/profile_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';
import 'package:edunest_app/features/post/domain/repos/post_repos.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_states.dart';

class PostCubit extends Cubit<PostState> {
  final PostRepo postRepo;
  final FirebaseNotificationRepo notificationRepo;
  final ProfileRepo profileRepo;

  PostCubit({
    required this.postRepo,
    required this.notificationRepo,
    required this.profileRepo,
  }) : super(PostInitialState());

  // Create a new post
  Future<void> createPost(Post post, {List<File>? image}) async {
    try {
      emit(PostUploadingState());

      List<String> imageUrls = [];
      // Upload all selected images
      if (image != null && image.isNotEmpty) {
        for (final image in image) {
          final result = await CloudinaryService.instance.uploadImage(image);

          if (!result.success ||
              result.imageUrl == null ||
              result.imageUrl!.isEmpty) {
            emit(
              PostErrorState(message: result.error ?? "Failed to upload image"),
            );
            return;
          }

          imageUrls.add(result.imageUrl!);
        }
      }

      // Create post with all image URLs
      final newPost = post.copyWith(imageUrls: imageUrls);

      await postRepo.createPost(newPost);
      await _notifyTaggedUsers(newPost);

      // Refresh posts after upload
      await fetchAllPostsbypublic();
    } catch (e) {
      emit(PostErrorState(message: e.toString()));
    }
  }

  Future<void> _notifyTaggedUsers(Post post) async {
    final taggedUserIds = post.taggedUserIds ?? const <String>[];
    final receivers = taggedUserIds
        .where((userId) => userId.isNotEmpty && userId != post.userId)
        .toSet();
    if (receivers.isEmpty) return;

    String? senderImageUrl;
    try {
      final sender = await profileRepo.fetchUserProfile(post.userId);
      senderImageUrl = sender?.profileImageUrl;
    } catch (error) {
      debugPrint(
        'Could not load post author profile for tag notifications: $error',
      );
    }

    for (final receiverId in receivers) {
      final notification = Notification(
        id: 'mention_${Uri.encodeComponent(post.id)}_${Uri.encodeComponent(receiverId)}',
        receiverId: receiverId,
        senderId: post.userId,
        type: 'mention',
        title: 'You were tagged',
        message: '${post.userName} mentioned you in a post',
        postId: post.id,
        isRead: false,
        senderProfileImageurl: senderImageUrl,
        createdAt: Timestamp.now(),
      );
      try {
        await notificationRepo.createNotification(notification);
      } catch (error) {
        debugPrint('Could not send tag notification to $receiverId: $error');
      }
    }
  }

  // Load all posts
  Future<void> fetchAllPosts() async {
    try {
      emit(PostLoadingState());

      final posts = await postRepo.fetchAllPosts();

      emit(PostLoadedState(posts: posts));
    } catch (e) {
      emit(PostErrorState(message: e.toString()));
    }
  }

  //delete post (soft delete)
  Future<void> deletePost(String postId, {String? userId}) async {
    try {
      await postRepo.deletePost(postId, userId: userId);
      await fetchAllPostsbypublic();
    } catch (e) {
      emit(PostErrorState(message: e.toString()));
    }
  }

  //restore post
  Future<void> restorePost(String postId, String userId) async {
    try {
      await postRepo.restorePost(postId, userId);
      await fetchAllPostsbypublic();
    } catch (e) {
      emit(PostErrorState(message: e.toString()));
    }
  }

  //permanently delete post
  Future<void> permanentlyDeletePost(String postId, String userId) async {
    try {
      await postRepo.permanentlyDeletePost(postId, userId);
      await fetchAllPostsbypublic();
    } catch (e) {
      emit(PostErrorState(message: e.toString()));
    }
  }

  //toggle like
  Future<void> toggleLikePost(Post post, String userId) async {
    try {
      // First like/unlike the post
      await postRepo.toggleLikePost(post.id, userId);
      if (post.userId == userId) {
        return;
      }
      final senderprofile = await profileRepo.fetchUserProfile(userId);
      if (senderprofile == null) {
        return;
      }
      final existingNotification = await notificationRepo.getLikeNotification(
        post.id,
        userId,
        post.userId,
      );
      final isLiked = post.likes.contains(userId);
      if (isLiked) {
        final notification = Notification(
          id: FirebaseFirestore.instance.collection('notifications').doc().id,
          receiverId: post.userId,
          senderId: userId,
          type: 'like',
          title: 'New Like ❤️',
          message: '${senderprofile.name} liked your post',
          isRead: false,
          postId: post.id,
          senderProfileImageurl: senderprofile.profileImageUrl,
          createdAt: Timestamp.now(),
        );
        await notificationRepo.createNotification(notification);
      } else {
        if (existingNotification != null) {
          await notificationRepo.deleteNotification(existingNotification.id);
        }
      }
    } catch (e) {
      emit(PostErrorState(message: 'fail to toggle like: $e'));
    }
  }

  //add a comment
  Future<Comment?> addComment(
    Post post,
    Comment comment,
    File? image,
    String userId,
  ) async {
    try {
      Comment updatedComment = comment;

      // Upload comment image if there is one
      if (image != null) {
        final result = await CloudinaryService.instance.uploadImage(image);

        if (!result.success ||
            result.imageUrl == null ||
            result.imageUrl!.isEmpty) {
          emit(
            PostErrorState(message: result.error ?? 'Failed to upload image'),
          );
          return null;
        }

        updatedComment = comment.CopyWith(imageUrl: result.imageUrl);
      }

      // Save comment first
      await postRepo.addComment(post.id, updatedComment);

      // Don't send notification if user commented on their own post
      if (post.userId == userId) {
        return updatedComment;
      }
      // Create comment notification
      final notification = Notification(
        id: FirebaseFirestore.instance.collection('notifications').doc().id,
        receiverId: post.userId,
        senderId: userId,
        type: 'comment',
        title: 'New Comment 💬',
        message: '${comment.userName} commented on your post',
        postId: post.id,
        isRead: false,
        senderProfileImageurl: comment.userimgurl ?? '',
        createdAt: Timestamp.now(),
      );

      await notificationRepo.createNotification(notification);

      return updatedComment;
    } catch (e) {
      emit(PostErrorState(message: 'Fail to add comment: $e'));

      return null;
    }
  }

  //delete comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await postRepo.deleteComment(postId, commentId);
      await fetchAllPosts();
    } catch (e) {
      emit(PostErrorState(message: 'Failed to delete comment'));
    }
  }

  // ignore: unused_element
  Future<String?> _getSenderProfileImage(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    final data = doc.data();
    return data?['profileImageUrl'] as String?;
  }

  Future<Post?> getPostById(String postId) async {
    try {
      final posts = await postRepo.fetchAllPosts();

      for (final post in posts) {
        if (post.id == postId) {
          return post;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Load all posts
  Future<void> fetchAllPostsbyfollowing(String userId) async {
    try {
      emit(PostLoadingState());
      final posts = await postRepo.fetchpostbyfollowing(userId);
      emit(PostLoadedState(posts: posts));
    } catch (e) {
      emit(PostErrorState(message: e.toString()));
    }
  }

  // Load all posts
  Future<void> fetchAllPostsbypublic() async {
    try {
      emit(PostLoadingState());

      final posts = await postRepo.fetchpostbypublic();

      emit(PostLoadedState(posts: posts));
    } catch (e) {
      emit(PostErrorState(message: e.toString()));
    }
  }

  //saved
  Future<void> toggleSavedPosts(Post post, String postId, String userId) async {
    try {
      // First like/unlike the post
      await postRepo.toggleSavedPost(postId, userId);
      if (post.userId == userId) {
        return;
      }
      final senderprofile = await profileRepo.fetchUserProfile(userId);
      if (senderprofile == null) {
        return;
      }
      final existingNotification = await notificationRepo.getSavedNotification(
        post.id,
        userId,
        post.userId,
      );
      final issaved = post.savedBy.contains(userId);
      if (issaved) {
        final notification = Notification(
          id: FirebaseFirestore.instance.collection('notifications').doc().id,
          receiverId: post.userId,
          senderId: userId,
          type: 'save',
          title: 'Saved Favorite 🔖',
          message: '${senderprofile.name} saved your post to favourite',
          isRead: false,
          postId: post.id,
          senderProfileImageurl: senderprofile.profileImageUrl,
          createdAt: Timestamp.now(),
        );
        await notificationRepo.createNotification(notification);
      } else {
        if (existingNotification != null) {
          await notificationRepo.deleteNotification(existingNotification.id);
        }
      }
    } catch (e) {
      emit(PostErrorState(message: 'fail to saved favourite: $e'));
    }
  }

  Future<List<Post>> fetchSavedPosts(String userId) async {
    try {
      return await postRepo.fetchSavedPosts(userId);
    } catch (e) {
      throw Exception('faile to saved post: $e');
    }
  }

  Future<bool> isPostSaved(String postId, String userId) async {
    try {
      return await postRepo.isPostSaved(postId, userId);
    } catch (e) {
      throw Exception('faile to saved post: $e');
    }
  }

  // Load posts for one user
  Future<void> fetchPostsByUserId(String userId) async {
    try {
      emit(PostLoadingState());

      final posts = await postRepo.fetchPostsByUserId(userId);

      emit(PostLoadedState(posts: posts));
    } catch (e) {
      emit(PostErrorState(message: e.toString()));
    }
  }

  Future<List<Post>> getVisiblePostsByUserId(
    String profileUserId,
    String? viewerUserId,
  ) async {
    return await postRepo.fetchVisiblePostsByUserId(
      profileUserId,
      viewerUserId,
    );
  }

  Future<void> editPost({
    required Post post,
    required String text,
    required String privacy,
    required List<String> imageUrls,
  }) async {
    try {
      emit(PostUploadingState());
      final updatePost = post.copyWith(
        text: text,
        privacy: privacy,
        imageUrls: imageUrls,
      );
      await postRepo.editPost(updatePost);
      await fetchAllPostsbypublic();
    } catch (e) {
      emit(PostErrorState(message: 'Failed to edit post: $e'));
    }
  }

  Future<void> addReply(
    String postId,
    String commentId,
    Comment reply, {
    required Comment parent,
    File? image,
  }) async {
    try {
      var updatedReply = reply;
      if (image != null) {
        final result = await CloudinaryService.instance.uploadImage(image);
        if (!result.success ||
            result.imageUrl == null ||
            result.imageUrl!.isEmpty) {
          throw Exception(result.error ?? 'Failed to upload reply image');
        }
        updatedReply = reply.CopyWith(imageUrl: result.imageUrl);
      }
      await postRepo.addReply(postId, commentId, updatedReply);
      if (parent.userId != reply.userId) {
        try {
          await notificationRepo.createNotification(
            Notification(
              id: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc()
                  .id,
              receiverId: parent.userId,
              senderId: reply.userId,
              type: 'reply',
              title: 'New Reply',
              message: '${reply.userName} replied to your comment',
              postId: postId,
              commentId: commentId,
              isRead: false,
              senderProfileImageurl: reply.userimgurl,
              createdAt: Timestamp.now(),
            ),
          );
        } catch (error) {
          debugPrint('Could not send reply notification: $error');
        }
      }
    } catch (e) {
      emit(PostErrorState(message: 'Failed to add reply: $e'));
      rethrow;
    }
  }

  Future<void> deleteReply(
    String postId,
    String commentId,
    String replyId,
  ) async {
    try {
      await postRepo.deleteReply(postId, commentId, replyId);
    } catch (e) {
      emit(PostErrorState(message: 'Failed to delete reply: $e'));
      rethrow;
    }
  }

  Future<void> toggleCommentReaction(
    String postId,
    Comment comment,
    String userId, {
    required bool isAdding,
  }) async {
    try {
      await postRepo.toggleCommentReaction(postId, comment.id, userId);
    } catch (e) {
      emit(PostErrorState(message: 'Failed to toggle comment reaction: $e'));
      rethrow;
    }

    if (comment.userId == userId) return;

    final notificationId =
        'comment_reaction_${Uri.encodeComponent(postId)}_'
        '${Uri.encodeComponent(comment.id)}_${Uri.encodeComponent(userId)}';
    try {
      if (!isAdding) {
        await notificationRepo.deleteNotification(notificationId);
      } else {
        final sender = await profileRepo.fetchUserProfile(userId);
        if (sender == null) {
          debugPrint(
            'Could not send reaction notification: actor profile not found',
          );
          return;
        }
        await notificationRepo.createNotification(
          Notification(
            id: notificationId,
            receiverId: comment.userId,
            senderId: userId,
            type: 'comment_reaction',
            title: 'New Reaction',
            message: '${sender.name} reacted to your comment',
            postId: postId,
            commentId: comment.id,
            isRead: false,
            senderProfileImageurl: sender.profileImageUrl,
            createdAt: Timestamp.now(),
          ),
        );
      }
    } catch (error) {
      debugPrint('Could not update comment reaction notification: $error');
    }
  }

  Future<List<Map<String, dynamic>>> searchUsersForMention(
    String query,
    String currentUserId,
  ) {
    return postRepo.searchUsersForMention(query, currentUserId);
  }
}
