import 'dart:io';

import 'package:edunest_app/features/auth/presentation/components/my_textfield.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileUser user;
  const EditProfilePage({super.key, required this.user});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // CONTROLLERS

  final nameTextController = TextEditingController();
  final bioTextController = TextEditingController();
  final phoneTextController = TextEditingController();
  final addressTextController = TextEditingController();
  final universityTextController = TextEditingController();
  final majorTextController = TextEditingController();
  final nicknameTextController = TextEditingController();

  File? selectedImage;
  // DROPDOWN / SELECT VALUES

  late String selectedDateOfBirth;
  late String selectedGender;
  late String selectedYears;
  late String selectedSemester;
  late String selectedRelationshipStatus;

  late List<String> selectedHobbies;

  @override
  void initState() {
    super.initState();

    // Existing values
    nameTextController.text = widget.user.name;
    bioTextController.text = widget.user.bio;
    phoneTextController.text = widget.user.phoneNumber;
    addressTextController.text = widget.user.address;
    universityTextController.text = widget.user.university;
    majorTextController.text = widget.user.major;
    nicknameTextController.text = widget.user.nickname;

    // Selection values
    selectedDateOfBirth = widget.user.dateofbirth;
    selectedGender = widget.user.gender;
    selectedYears = widget.user.years;
    selectedSemester = widget.user.semester;
    selectedRelationshipStatus = widget.user.relationshipStatus;
    selectedHobbies = List<String>.from(
      widget.user.hobbies.split(',').map((hobby) => hobby.trim()),
    );
  }

  @override
  void dispose() {
    nameTextController.dispose();
    bioTextController.dispose();
    phoneTextController.dispose();
    addressTextController.dispose();
    universityTextController.dispose();
    majorTextController.dispose();
    nicknameTextController.dispose();

    super.dispose();
  }
  // PICK PROFILE IMAGE

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        selectedImage = File(pickedImage.path);
      });
    }
  }
  // UPDATE PROFILE

  void updateProfile() {
    final profileCubit = context.read<ProfileCubit>();
    

    profileCubit.updateProfile(
      uid: widget.user.uid,

      newName: nameTextController.text.trim(),

      newBio: bioTextController.text.trim(),

      image: selectedImage,

      // NEW FIELDS
      newDateofbirth: selectedDateOfBirth,

      newGender: selectedGender,

      newPhoneNumber: phoneTextController.text.trim(),

      newAddress: addressTextController.text.trim(),

      newUniversity: universityTextController.text.trim(),

      newMajor: majorTextController.text.trim(),

      newYears: selectedYears,

      newSemester: selectedSemester,

      newHobbies: selectedHobbies.join(', '),

      newNickname: nicknameTextController.text.trim(),

      newRelationshipStatus: selectedRelationshipStatus,
    );
  }

  //function
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDateOfBirth = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectGender() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Select Gender',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              ListTile(
                title: const Text('Male'),
                onTap: () => Navigator.pop(context, 'Male'),
              ),

              ListTile(
                title: const Text('Female'),
                onTap: () => Navigator.pop(context, 'Female'),
              ),

              ListTile(
                title: const Text('Other'),
                onTap: () => Navigator.pop(context, 'Other'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedGender = result;
      });
    }
  }

  Future<void> _selectRelationship() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final statuses = [
          'Single',
          'In a relationship',
          'Married',
          'Prefer not to say',
        ];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Relationship Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              ...statuses.map(
                (status) => ListTile(
                  title: Text(status),
                  onTap: () => Navigator.pop(context, status),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedRelationshipStatus = result;
      });
    }
  }

  Future<void> _selectYear() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final years = ['Year 1', 'Year 2', 'Year 3', 'Year 4'];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Select Year',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              ...years.map(
                (year) => ListTile(
                  title: Text(year),
                  onTap: () => Navigator.pop(context, year),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedYears = result;
      });
    }
  }

  Future<void> _selectSemester() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final semesters = ['Semester 1', 'Semester 2', 'Semester 3'];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Select Semester',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              ...semesters.map(
                (semester) => ListTile(
                  title: Text(semester),
                  onTap: () => Navigator.pop(context, semester),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedSemester = result;
      });
    }
  }

  Future<void> _selectHobbies() async {
    final hobbies = [
      'Reading',
      'Gaming',
      'Music',
      'Sports',
      'Drawing',
      'Coding',
      'Traveling',
      'Photography',
      'Movies',
      'Cooking',
    ];

    final tempSelected = List<String>.from(selectedHobbies);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    const Text(
                      'Select Hobbies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    ...hobbies.map((hobby) {
                      final selected = tempSelected.contains(hobby);

                      return CheckboxListTile(
                        title: Text(hobby),

                        value: selected,

                        onChanged: (value) {
                          setModalState(() {
                            if (value == true) {
                              tempSelected.add(hobby);
                            } else {
                              tempSelected.remove(hobby);
                            }
                          });
                        },
                      );
                    }),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedHobbies = List<String>.from(tempSelected);
                          });

                          Navigator.pop(context);
                        },

                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editUniversity() async {
    final result = await _editText(
      title: 'University',
      initialValue: universityTextController.text,
    );

    if (result != null) {
      setState(() {
        universityTextController.text = result;
      });
    }
  }

  Future<void> _editPhone() async {
    final result = await _editText(
      title: 'Phone Number',
      initialValue: phoneTextController.text,
    );

    if (result != null) {
      setState(() {
        phoneTextController.text = result;
      });
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileStates>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          Navigator.pop(context);
        }
      },

      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Saving profile...'),
                ],
              ),
            ),
          );
        }

        return buildEditPage();
      },
    );
  }

  Future<void> _editAddress() async {
    final result = await _editText(
      title: 'Address',
      initialValue: addressTextController.text,
    );

    if (result != null) {
      setState(() {
        addressTextController.text = result;
      });
    }
  }

  Future<void> _editMajor() async {
    final result = await _editText(
      title: 'Major',
      initialValue: majorTextController.text,
    );

    if (result != null) {
      setState(() {
        majorTextController.text = result;
      });
    }
  }

  Future<String?> _editText({
    required String title,
    required String initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter $title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }
  // MAIN PAGE

  Widget buildEditPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setting'), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // TITLE

            const SizedBox(height: 10),

            const Text(
              'Profile Setting,',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 88, 84, 71),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),
            Center(
              child: GestureDetector(
                onTap: pickImage,

                child: Stack(
                  children: [
                    selectedImage != null
                        ? CircleAvatar(
                            radius: 58,
                            backgroundImage: FileImage(selectedImage!),
                          )
                        : CircleProfile(imageurl: widget.user.profileImageUrl),

                    Positioned(
                      right: 0,
                      bottom: 5,

                      child: Container(
                        padding: const EdgeInsets.all(8),

                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Iconsax.camera,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // BASIC INFORMATION
            // =================================================
            _sectionTitle('Basic Information', Iconsax.user),

            const SizedBox(height: 12),

            _fieldTitle('Full Name'),

            MyTextfield(
              controller: nameTextController,
              hintText: 'Enter your name',
              obscureText: false,
              text: widget.user.name,
            ),

            const SizedBox(height: 12),

            _fieldTitle('Nickname'),

            MyTextfield(
              controller: nicknameTextController,
              hintText: 'Enter your nickname',
              obscureText: false,
              text: widget.user.nickname,
            ),

            const SizedBox(height: 12),

            _fieldTitle('Bio'),

            MyTextfield(
              controller: bioTextController,
              hintText: 'Tell people about yourself',
              obscureText: false,
              text: widget.user.bio,
            ),

            const SizedBox(height: 25),

            // =================================================
            // PERSONAL INFORMATION
            // =================================================
            _sectionTitle('Personal Information', Iconsax.profile_2user),

            const SizedBox(height: 10),

            _settingTile(
              icon: Iconsax.calendar,
              title: 'Date of Birth',
              value: selectedDateOfBirth.isEmpty
                  ? 'Add your birth date'
                  : selectedDateOfBirth,
              onTap: _selectDate,
            ),

            _settingTile(
              icon: Iconsax.user,
              title: 'Gender',
              value: selectedGender.isEmpty ? 'Select gender' : selectedGender,
              onTap: _selectGender,
            ),

            _settingTile(
              icon: Iconsax.call,
              title: 'Phone Number',
              value: phoneTextController.text.isEmpty
                  ? 'Add phone number'
                  : phoneTextController.text,
              onTap: _editPhone,
            ),

            _settingTile(
              icon: Iconsax.heart,
              title: 'Relationship',
              value: selectedRelationshipStatus.isEmpty
                  ? 'Select status'
                  : selectedRelationshipStatus,
              onTap: _selectRelationship,
            ),

            _settingTile(
              icon: Iconsax.location,
              title: 'Address',
              value: addressTextController.text.isEmpty
                  ? 'Add address'
                  : addressTextController.text,
              onTap: _editAddress,
            ),

            const SizedBox(height: 25),

            // =================================================
            // EDUCATION
            // =================================================
            _sectionTitle('Education', Iconsax.teacher),

            const SizedBox(height: 10),

            _settingTile(
              icon: Iconsax.building,
              title: 'University',
              value: universityTextController.text.isEmpty
                  ? 'Add university'
                  : universityTextController.text,
              onTap: _editUniversity,
            ),

            _settingTile(
              icon: Iconsax.book,
              title: 'Major',
              value: majorTextController.text.isEmpty
                  ? 'Add major'
                  : majorTextController.text,
              onTap: _editMajor,
            ),

            _settingTile(
              icon: Iconsax.layer,
              title: 'Year',
              value: selectedYears.isEmpty ? 'Select year' : selectedYears,
              onTap: _selectYear,
            ),

            _settingTile(
              icon: Iconsax.book_1,
              title: 'Semester',
              value: selectedSemester.isEmpty
                  ? 'Select semester'
                  : selectedSemester,
              onTap: _selectSemester,
            ),

            const SizedBox(height: 25),

            // OTHER
            _sectionTitle('Other', Iconsax.more),

            const SizedBox(height: 10),

            _settingTile(
              icon: Iconsax.game,
              title: 'Hobbies',
              value: selectedHobbies.isEmpty
                  ? 'Add hobbies'
                  : selectedHobbies.join(', '),
              onTap: _selectHobbies,
            ),

            const SizedBox(height: 30),
            // SAVE BUTTON
            // =================================================
            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed: updateProfile,

                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color.fromARGB(255, 224, 247, 250),

                  foregroundColor: const Color.fromARGB(255, 88, 84, 71),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),

                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // =========================================================
  // FIELD TITLE
  // =========================================================

  Widget _fieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 5),

      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  // =========================================================
  // SETTING TILE
  // =========================================================

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),

        child: Row(
          children: [
            Icon(icon, size: 21),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
