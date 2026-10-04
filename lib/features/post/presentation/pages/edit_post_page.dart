import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';

class EditPostPage extends StatefulWidget {
  final Post post;

  const EditPostPage({
    super.key,
    required this.post,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController captionController;

  late String selectedPrivacy;

  // Local list.
  // We only update the real post after Save is pressed.
  late List<String> imageUrls;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    captionController = TextEditingController(
      text: widget.post.text,
    );

    selectedPrivacy = widget.post.privacy;

    imageUrls = List<String>.from(widget.post.imageUrls);
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    final caption = captionController.text.trim();

    setState(() {
      isSaving = true;
    });

    try {
      await context.read<PostCubit>().editPost(
            post: widget.post,
            text: caption,
            privacy: selectedPrivacy,
            imageUrls: imageUrls,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post updated successfully'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update post: $e'),
        ),
      );
    }
  }

  void removeImage(int index) {
    setState(() {
      imageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),

        title: const Text(
          'Edit Post',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          TextButton(
            onPressed: isSaving ? null : saveChanges,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // CAPTION
            // =========================
            const Text(
              'Caption',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: captionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write something...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =========================
            // PRIVACY
            // =========================
            const Text(
              'Privacy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPrivacy,
                  isExpanded: true,

                  items: const [
                    DropdownMenuItem(
                      value: 'Public',
                      child: Row(
                        children: [
                          Icon(Icons.public),
                          SizedBox(width: 10),
                          Text('Public'),
                        ],
                      ),
                    ),

                    DropdownMenuItem(
                      value: 'Friend',
                      child: Row(
                        children: [
                          Icon(Icons.people),
                          SizedBox(width: 10),
                          Text('Friends'),
                        ],
                      ),
                    ),

                    DropdownMenuItem(
                      value: 'private',
                      child: Row(
                        children: [
                          Icon(Icons.lock),
                          SizedBox(width: 10),
                          Text('Only Me'),
                        ],
                      ),
                    ),
                  ],

                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            selectedPrivacy = value;
                          });
                        },
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =========================
            // PHOTOS
            // =========================
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (imageUrls.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No photos',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: imageUrls.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrls[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,

                          errorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // DELETE PHOTO BUTTON
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: isSaving
                              ? null
                              : () => removeImage(index),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 30),

            // =========================
            // SAVE BUTTON
            // =========================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveChanges,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}