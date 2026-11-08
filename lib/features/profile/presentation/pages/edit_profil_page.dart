import 'dart:io';

import 'package:edunest_app/features/auth/presentation/components/my_textfield.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/presentation/components/cambodia_address_picker.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileUser user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final nameTextController = TextEditingController();
  final bioTextController = TextEditingController();
  final phoneTextController = TextEditingController();
  final addressTextController = TextEditingController();
  final universityTextController = TextEditingController();
  final majorTextController = TextEditingController();
  final nicknameTextController = TextEditingController();

  File? selectedImage;

  // =========================================================
  // SELECTED VALUES
  // =========================================================

  late String selectedDateOfBirth;
  late String selectedGender;
  late String selectedYears;
  late String selectedSemester;
  late String selectedRelationshipStatus;

  late List<String> selectedHobbies;

  String selectedUniversity = '';
  String selectedMajor = '';

  // =========================================================
  // BBU CAMPUSES
  // =========================================================

  final List<String> bbuCampuses = [
    'BBU Phnom Penh Campus',
    'BBU Siem Reap Campus',
    'BBU Battambang Campus',
    'BBU Preah Sihanouk Campus',
    'BBU Banteay Meanchey Campus',
    'BBU Ratanakiri Campus',
    'BBU Takeo Campus',
    'BBU Stung Treng Campus',
    'BBU Tboung Khmum Campus',
  ];

  // Initial major catalog. Verify the current official
  // program list with BBU before treating it as exhaustive.

  final List<String> bbuMajors = [
    'General Management',
    'Accounting and Finance',
    'Finance and Banking',
    'Marketing',
    'International Business',
    'Real Estate and Land Management',
    'Business Administration',
    'Accounting',
    'Finance',
    'Information Technology',
    'Teaching English as a Foreign Language',
  ];

  // =========================================================
  // INITIALIZATION
  // =========================================================

  @override
  void initState() {
    super.initState();

    nameTextController.text = widget.user.name;
    bioTextController.text = widget.user.bio;
    phoneTextController.text = widget.user.phoneNumber;
    addressTextController.text = widget.user.address;
    universityTextController.text = widget.user.university;
    majorTextController.text = widget.user.major;
    nicknameTextController.text = widget.user.nickname;

    selectedUniversity = widget.user.university;
    selectedMajor = widget.user.major;

    selectedDateOfBirth = widget.user.dateofbirth;
    selectedGender = widget.user.gender;
    selectedYears = widget.user.years;
    selectedSemester = widget.user.semester;
    selectedRelationshipStatus = widget.user.relationshipStatus;

    selectedHobbies = widget.user.hobbies
        .split(',')
        .map((hobby) => hobby.trim())
        .where((hobby) => hobby.isNotEmpty)
        .toList();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

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

  // =========================================================
  // PICK PROFILE IMAGE
  // =========================================================

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (!mounted || pickedImage == null) return;

    setState(() {
      selectedImage = File(pickedImage.path);
    });
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  void updateProfile() {
    final name = nameTextController.text.trim();
    final university = selectedUniversity.trim();
    final major = selectedMajor.trim();

    if (name.isEmpty) {
      _showError('Full name is required.');
      return;
    }

    if (university.isEmpty) {
      _showError('Please select your BBU campus.');
      return;
    }

    if (major.isEmpty) {
      _showError('Please select your major.');
      return;
    }

    context.read<ProfileCubit>().updateProfile(
      uid: widget.user.uid,
      newName: name,
      newBio: bioTextController.text.trim(),
      image: selectedImage,
      newDateofbirth: selectedDateOfBirth,
      newGender: selectedGender,
      newPhoneNumber: phoneTextController.text.trim(),
      newAddress: addressTextController.text.trim(),
      newUniversity: university,
      newMajor: major,
      newYears: selectedYears,
      newSemester: selectedSemester,
      newHobbies: selectedHobbies.join(', '),
      newNickname: nicknameTextController.text.trim(),
      newRelationshipStatus: selectedRelationshipStatus,
    );
  }

  // =========================================================
  // REUSABLE SELECTION BOTTOM SHEET
  // =========================================================

  Future<String?> _showSelection({
    required String title,
    required List<String> options,
    required String currentValue,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option == currentValue;

                      return ListTile(
                        title: Text(option),
                        trailing: isSelected
                            ? const Icon(
                                Iconsax.tick_circle,
                                color: Colors.blue,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext, option);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // UNIVERSITY SELECTION
  // =========================================================

  Future<void> _selectUniversity() async {
    final result = await _showSelection(
      title: 'Select BBU Campus',
      options: bbuCampuses,
      currentValue: selectedUniversity,
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedUniversity = result;
      universityTextController.text = result;
    });
  }

  // =========================================================
  // MAJOR SELECTION
  // =========================================================

  Future<void> _selectMajor() async {
    final result = await _showSelection(
      title: 'Select Your Major',
      options: bbuMajors,
      currentValue: selectedMajor,
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedMajor = result;
      majorTextController.text = result;
    });
  }

  // =========================================================
  // DATE OF BIRTH
  // =========================================================

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (!mounted || picked == null) return;

    setState(() {
      selectedDateOfBirth =
          '${picked.day}/${picked.month}/${picked.year}';
    });
  }

  // =========================================================
  // GENDER
  // =========================================================

  Future<void> _selectGender() async {
    final result = await _showSelection(
      title: 'Select Gender',
      options: [
        'Male',
        'Female',
        'Other',
        'Prefer not to say',
      ],
      currentValue: selectedGender,
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedGender = result;
    });
  }

  // =========================================================
  // RELATIONSHIP STATUS
  // =========================================================

  Future<void> _selectRelationship() async {
    final result = await _showSelection(
      title: 'Relationship Status',
      options: [
        'Single',
        'In a relationship',
        'Married',
        'Prefer not to say',
      ],
      currentValue: selectedRelationshipStatus,
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedRelationshipStatus = result;
    });
  }

  // =========================================================
  // YEAR
  // =========================================================

  Future<void> _selectYear() async {
    final result = await _showSelection(
      title: 'Select Year',
      options: [
        'Year 1',
        'Year 2',
        'Year 3',
        'Year 4',
      ],
      currentValue: selectedYears,
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedYears = result;
    });
  }

  // =========================================================
  // SEMESTER
  // =========================================================

  Future<void> _selectSemester() async {
    final result = await _showSelection(
      title: 'Select Semester',
      options: [
        'Semester 1',
        'Semester 2',
        'Semester 3',
      ],
      currentValue: selectedSemester,
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedSemester = result;
    });
  }

  // =========================================================
  // HOBBIES
  // =========================================================

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    children: [
                      const Text(
                        'Select Hobbies',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Expanded(
                        child: ListView(
                          children: hobbies.map((hobby) {
                            final selected =
                                tempSelected.contains(hobby);

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
                          }).toList(),
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedHobbies =
                                  List<String>.from(tempSelected);
                            });

                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editAddress() async {
    final result = await CambodiaAddressPicker.show(
      context,
      initialAddress: addressTextController.text,
    );

    if (!mounted || result == null) return;

    setState(() {
      addressTextController.text = result;
    });
  }

  Future<void> _editPhone() async {
    final result = await _editText(
      title: 'Phone Number',
      initialValue: phoneTextController.text,
    );

    if (!mounted || result == null) return;

    setState(() {
      phoneTextController.text = result;
    });
  }

  Future<String?> _editText({
    required String title,
    required String initialValue,
  }) async {
    final controller = TextEditingController(
      text: initialValue,
    );

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter $title',
              ),
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
                  Navigator.pop(
                    dialogContext,
                    controller.text.trim(),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

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
                  SizedBox(height: 12),
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

  // =========================================================
  // MAIN EDIT PROFILE PAGE
  // =========================================================

  Widget buildEditPage() {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setting'),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Text(
              'Profile Setting',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? textColor
                    : const Color.fromARGB(255, 88, 84, 71),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Edit your personal information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            // PROFILE IMAGE

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
                        : CircleProfile(
                            imageurl: widget.user.profileImageUrl,
                          ),

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

            const SizedBox(height: 28),

            // =================================================
            // BASIC INFORMATION
            // =================================================

            _sectionTitle(
              'Basic Information',
              Iconsax.user,
            ),

            const SizedBox(height: 12),

            _fieldTitle('Full Name *'),

            MyTextfield(
              controller: nameTextController,
              hintText: 'Enter your full name',
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

            _sectionTitle(
              'Personal Information',
              Iconsax.profile_2user,
            ),

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
              value: selectedGender.isEmpty
                  ? 'Select gender'
                  : selectedGender,
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
                  ? 'Select your Cambodia address'
                  : addressTextController.text,
              onTap: _editAddress,
            ),

            const SizedBox(height: 25),
            _sectionTitle(
              'Education',
              Iconsax.teacher,
            ),

            const SizedBox(height: 10),

            _settingTile(
              icon: Iconsax.building,
              title: 'University / Campus *',
              value: selectedUniversity.isEmpty
                  ? 'Select BBU campus'
                  : selectedUniversity,
              onTap: _selectUniversity,
            ),

            _settingTile(
              icon: Iconsax.book,
              title: 'Major *',
              value: selectedMajor.isEmpty
                  ? 'Select your major'
                  : selectedMajor,
              onTap: _selectMajor,
            ),

            _settingTile(
              icon: Iconsax.layer,
              title: 'Year',
              value: selectedYears.isEmpty
                  ? 'Select year'
                  : selectedYears,
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

            // =================================================
            // OTHER
            // =================================================

            _sectionTitle(
              'Other',
              Iconsax.more,
            ),

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

            // =================================================
            // SAVE BUTTON
            // =================================================

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: updateProfile,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _fieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 5,
        left: 5,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 5,
        ),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
