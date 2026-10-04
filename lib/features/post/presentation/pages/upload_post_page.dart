import 'dart:io';

import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';
import 'package:edunest_app/features/post/presentation/components/my_bubble.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_states.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  State<UploadPostPage> createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  List<File> selectedImages = [];
  final textController = TextEditingController();

  // Current user
  AppUser? currentUser;
  late final ProfileCubit profileCubit;
  String selectedPrivacy = 'Public';

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    profileCubit = context.read<ProfileCubit>();
  }

  void getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentUser;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final pickedImages = await picker.pickMultiImage(imageQuality: 80);

    if (pickedImages.isEmpty) return;

    // How many more pictures can be selected
    final remainingSlots = 50 - selectedImages.length;

    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can upload a maximum of 50 pictures.'),
        ),
      );
      return;
    }

    // Only take the number that fits within the 50 limit
    final imagesToAdd = pickedImages
        .take(remainingSlots)
        .map((image) => File(image.path))
        .toList();

    setState(() {
      selectedImages.addAll(imagesToAdd);
    });

    if (pickedImages.length > remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only 50 pictures are allowed per post.')),
      );
    }
  }

  Widget _privacyOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedPrivacy == value;

    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        ),
      ),

      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),

      subtitle: Text(subtitle),

      trailing: Radio<String>(
        value: value,
        groupValue: selectedPrivacy,
        onChanged: (newValue) {
          if (newValue == null) return;

          setState(() {
            selectedPrivacy = newValue;
          });

          Navigator.pop(context);
        },
      ),

      onTap: () {
        setState(() {
          selectedPrivacy = value;
        });

        Navigator.pop(context);
      },
    );
  }

  void showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Who can see your post?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                _privacyOption(
                  value: 'Public',
                  title: 'Public',
                  subtitle: 'Everyone can see this post',
                  icon: Iconsax.global,
                ),
                _privacyOption(
                  value: 'Friend',
                  title: 'Friend',
                  subtitle: 'Only your Friend can see this post',
                  icon: Iconsax.people,
                ),
                _privacyOption(
                  value: 'private',
                  title: 'Only me',
                  subtitle: 'Only you can see this post',
                  icon: Iconsax.lock,
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void uploadPost() {
    if (selectedImages.isEmpty && textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something or select an image.'),
        ),
      );
      return;
    }

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser?.uid ?? '',
      userName: currentUser?.name ?? '',
      text: textController.text.trim(),
      imageUrls: [],
      timestamp: DateTime.now(),
      likes: [],
      comments: [],
      privacy: selectedPrivacy,
      savedBy: [],
    );

    final postCubit = context.read<PostCubit>();

    postCubit.createPost(newPost, image: selectedImages);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostCubit, PostState>(
      builder: (context, state) {
        print(state);
        if (state is PostUploadingState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return buildUploadPostPage();
      },
      listener: (context, state) {
        if (state is PostLoadedState) {
          Navigator.pop(context);
        }
        if (state is PostErrorState) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
    );
  }

  Widget buildUploadPostPage() {
    final user = profileCubit.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Post'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.document_upload),
            onPressed: uploadPost, // Hooked up the upload functionality
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleProfile(
                    imageurl: user?.profileImageUrl ?? '',
                    size: 40.0,
                  ),
                  const SizedBox(width: 15.0),
                  Text(
                    user?.name ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // Caption Textbox
              TextField(
                controller: textController,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16.0),
                ),
              ),
              const SizedBox(height: 15.0),

              // Action Buttons Row (Gallery & Privacy)
              Row(
                children: [
                  MyBubble(
                    iconData: Iconsax.gallery,
                    onTap: pickImage,
                    text: 'Gallery',
                  ),
                  const SizedBox(width: 10.0),
                  MyBubble(
                    iconData: Iconsax.key,
                    onTap: showPrivacyOptions,
                    text: 'Privacy',
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              if (!kIsWeb && selectedImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            selectedImages[index],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        // Remove image button
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
