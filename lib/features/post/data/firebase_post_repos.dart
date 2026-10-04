import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/post/domain/entities/comment.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';

import '../domain/repos/post_repos.dart';

class FirebasePostRepo implements PostRepo {
  //store the post in a collection called 'posts' in firestore
  final CollectionReference postscollection = FirebaseFirestore.instance
      .collection('posts');
  final usercollection = FirebaseFirestore.instance.collection('users');
  @override
  Future<void> createPost(Post post) async {
    try {
      await postscollection.doc(post.id).set(post.toJson());
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await postscollection.doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  @override
  Future<List<Post>> fetchAllPosts() async {
    try {
      final postsSnapshot = await postscollection
          .orderBy('timestamp', descending: true)
          .get();

      final List<Post> allPosts = postsSnapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return allPosts;
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  @override
  Future<List<Post>> fetchPostsByUserId(String userId) async {
    try {
      final postSnapshot = await postscollection
          .where('userId', isEqualTo: userId)
          .get();
      //convert the snapshot to a list of posts to json
     final userPosts = postSnapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>,);
      data ['id' ] ??= doc.id;
      return Post.fromJson(data);
     }).toList();
     userPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return userPosts;
    } catch (e) {
      throw Exception('Failed to fetch posts by userId: $e');
    }
  }

  @override
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      final postDoc = await postscollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        //check if user likes
        final hasLiked = post.likes.contains(userId);
        //update the like list
        if (hasLiked) {
          post.likes.remove(userId);
        } else {
          post.likes.add(userId);
        }
        //update the post document with new like list
        await postscollection.doc(postId).update({'likes': post.likes});
      } else {
        throw Exception("post not found");
      }
    } catch (e) {
      throw Exception("Error toggle like: $e");
    }
  }

  @override
  Future<void> addComment(String postId, Comment comment) async {
    try {
      //get post doc
      final postDoc = await postscollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        //add the new comment
        post.comments.add(comment);
        //update the post document
        await postscollection.doc(postId).update({
          'comments': post.comments.map((comment) => comment.toJson()).toList(),
        });
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      throw Exception('Error adding comment');
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      //get post doc
      final postDoc = await postscollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        //add the new comment
        post.comments.removeWhere((comment) => comment.id == commentId);
        //update the post document
        await postscollection.doc(postId).update({
          'comments': post.comments.map((comment) => comment.toJson()).toList(),
        });
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      throw Exception('Error deleting comment');
    }
  }
@override
Future<List<Post>> fetchpostbyfollowing(String userId) async {
  try {
    // Get current user's document
    final currentUserDoc = await usercollection.doc(userId).get();

    if (!currentUserDoc.exists) {
      return [];
    }

    final currentUserData =
        currentUserDoc.data() as Map<String, dynamic>;

    // People that current user follows
    final followingIds = List<String>.from(
      currentUserData['following'] ?? [],
    );

    if (followingIds.isEmpty) {
      return [];
    }
    // and check whether they follow current user back.
    final List<String> mutualFriendIds = [];

    for (int i = 0; i < followingIds.length; i += 30) {
      final batch = followingIds.skip(i).take(30).toList();

      final usersSnapshot = await usercollection
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in usersSnapshot.docs) {
        final userData =
            doc.data();

        final followers = List<String>.from(
          userData['followers'] ?? [],
        );

        // Both users follow each other
        if (followers.contains(userId)) {
          mutualFriendIds.add(doc.id);
        }
      }
    }

    if (mutualFriendIds.isEmpty) {
      return [];
    }

    // Now fetch posts only from mutual friends
    final List<Post> followingPosts = [];

    for (int i = 0; i < mutualFriendIds.length; i += 30) {
      final batch = mutualFriendIds.skip(i).take(30).toList();

      final postSnapshot = await postscollection
          .where('userId', whereIn: batch)
          .where('privacy', isEqualTo: 'Friend')
          .get();

      final posts = postSnapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(
              doc.data() as Map<String, dynamic>,
            );

            data['id'] ??= doc.id;

            return Post.fromJson(data);
          })
          .toList();

      followingPosts.addAll(posts);
    }

    // Newest posts first
    followingPosts.sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    );

    return followingPosts;
  } catch (e) {
    throw Exception(
      'Failed to fetch posts by following: $e',
    );
  }
}

  @override
  Future<List<Post>> fetchpostbypublic() async {
    try {
      final postSnapshot = await postscollection
          .where('privacy', isEqualTo: 'Public')
          
          .get();

      final posts = postSnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>,
        );

        // Make sure ID exists
        data['id'] ??= doc.id;

        return Post.fromJson(data);
      }).toList();

      return posts;
    } catch (e) {
      print('🔥 FETCH PUBLIC POSTS ERROR: $e');
      throw Exception('Failed to fetch posts by public: $e');
    }
  }

  @override
  Future<bool> isPostSaved(String postId, String userId) async {
    try {
      final userDoc = await usercollection.doc(userId).get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      final List<String> savedPosts = List<String>.from(
        userData['savedPosts'] ?? [],
      );

      return savedPosts.contains(postId);
    } catch (e) {
      throw Exception('Failed to check saved post: $e');
    }
  }

  @override
  Future<void> toggleSavedPost(String postId, String userId) async {
    try {
      final userRef = usercollection.doc(userId);
      final postRef = postscollection.doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final postSnapshot = await transaction.get(postRef);

        if (!userSnapshot.exists) {
          throw Exception('User not found');
        }

        if (!postSnapshot.exists) {
          throw Exception('Post not found');
        }

        final userData = userSnapshot.data() as Map<String, dynamic>;
        final postData = postSnapshot.data() as Map<String, dynamic>;

        final savedPosts = List<String>.from(userData['savedPosts'] ?? []);

        final savedBy = List<String>.from(postData['savedBy'] ?? []);

        final isSaved = savedPosts.contains(postId);

        if (isSaved) {
          savedPosts.remove(postId);
          savedBy.remove(userId);
        } else {
          savedPosts.add(postId);
          savedBy.add(userId);
        }

        transaction.update(userRef, {'savedPosts': savedPosts});

        transaction.update(postRef, {'savedBy': savedBy});
      });
    } catch (e) {
      throw Exception('Error toggling saved post: $e');
    }
  }

  @override
  Future<List<Post>> fetchSavedPosts(String userId) async {
    try {
      final userDoc = await usercollection.doc(userId).get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      final List<String> savedPostIds = List<String>.from(
        userData['savedPosts'] ?? [],
      );

      if (savedPostIds.isEmpty) {
        return [];
      }

      final List<Post> savedPosts = [];

      // Firestore whereIn limit
      for (int i = 0; i < savedPostIds.length; i += 30) {
        final batch = savedPostIds.skip(i).take(30).toList();

        final snapshot = await postscollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final posts = snapshot.docs
            .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        savedPosts.addAll(posts);
      }

      // Newest saved posts first
      savedPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return savedPosts;
    } catch (e) {
      throw Exception('Failed to fetch saved posts: $e');
    }
  }
@override
Future<List<Post>> fetchVisiblePostsByUserId(
  String profileUserId,
  String? viewerUserId,
) async {
  try {
    final postSnapshot = await postscollection
        .where('userId', isEqualTo: profileUserId)
        .get();

    final posts = postSnapshot.docs
        .map((doc) {
          final data = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );

          data['id'] ??= doc.id;

          return Post.fromJson(data);
        })
        .toList();

    // Get the profile owner's user document
    final profileUserDoc =
        await usercollection.doc(profileUserId).get();

    if (!profileUserDoc.exists) {
      return [];
    }

    final profileUserData =
        profileUserDoc.data() as Map<String, dynamic>;

    final List<String> profileFollowing =
        List<String>.from(profileUserData['following'] ?? []);

    // Check whether viewer follows profile owner
    final viewerFollowsOwner =
        viewerUserId != null &&
        profileUserData['followers']?.contains(viewerUserId) == true;

    // Check whether profile owner follows viewer
    bool ownerFollowsViewer = false;

    if (viewerUserId != null) {
      final viewerDoc =
          await usercollection.doc(viewerUserId).get();

      if (viewerDoc.exists) {
        final viewerData =
            viewerDoc.data() as Map<String, dynamic>;

        final List<String> viewerFollowing =
            List<String>.from(viewerData['following'] ?? []);

        ownerFollowsViewer =
            viewerFollowing.contains(profileUserId);
      }
    }

    final List<Post> visiblePosts = posts.where((post) {
      // Owner can see everything on their own profile
      if (viewerUserId == profileUserId) {
        return true;
      }

      // PUBLIC
      if (post.privacy == 'Public') {
        return true;
      }

      // ONLY ME
      if (post.privacy == 'private') {
        return false;
      }

      // FRIENDS / FOLLOWING
      if (post.privacy == 'Friend') {
        return viewerFollowsOwner && ownerFollowsViewer;
      }

      return false;
    }).toList();

    visiblePosts.sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    );

    return visiblePosts;
  } catch (e) {
    throw Exception(
      'Failed to fetch visible posts by userId: $e',
    );
  }
}

  @override
  Future<void> editPost(Post post, ) async {
    try{
       await postscollection.doc(post.id).update(post.toJson());
    }
    catch (e){
      throw Exception('Failed to edit post: $e');
    }
  }
}
