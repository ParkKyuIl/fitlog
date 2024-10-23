import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shrine/app_state.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gymController = TextEditingController();
  final TextEditingController _maxSquatController = TextEditingController();
  String? _selectedGender;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<ApplicationState>(context, listen: false);
    _nicknameController.text = appState.nickname ?? '';
    _emailController.text = appState.email;
    _gymController.text = appState.gym ?? '';
    _maxSquatController.text = appState.maxSquat.toString();
    _selectedGender = appState.gender;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _gymController.dispose();
    _maxSquatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      final uploadTask = firebaseStorageRef.putFile(imageFile);
      final taskSnapshot = await uploadTask.whenComplete(() => {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 업로드가 완료되었습니다!'),
        ),
      );

      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 업로드 중 오류가 발생했습니다: $e'),
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.edit, color: Colors.greenAccent),
          onPressed: () => _showEditDialog(context),
        ),
        actions: [
          Consumer<ApplicationState>(
            builder: (context, appState, _) => IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                await _googleSignIn.signOut();
                context.go("/login");
                appState.userprofile = null;
                appState.uid = "";
                appState.email = "Anonymous";
                appState.nickname = null;
                appState.gender = null;
                appState.gym = null;
                appState.maxSquat = "0";
              },
              icon: const Icon(Icons.exit_to_app, color: Colors.greenAccent),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  color: Colors.black,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Consumer<ApplicationState>(
                            builder: (context, appState, _) => (appState
                                        .userprofile ==
                                    null)
                                ? Image.asset('assets/logo.png', height: 300)
                                : Image.network(appState.userprofile!,
                                    height: 400),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.greenAccent),
                      Consumer<ApplicationState>(
                        builder: (context, appState, _) => Text(
                          'Nickname: ${appState.nickname ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const Divider(color: Colors.greenAccent),
                      Consumer<ApplicationState>(
                        builder: (context, appState, _) => Text(
                          'Email: ${appState.email}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const Divider(color: Colors.greenAccent),
                      Consumer<ApplicationState>(
                        builder: (context, appState, _) => Text(
                          'Gender: ${appState.gender ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const Divider(color: Colors.greenAccent),
                      Consumer<ApplicationState>(
                        builder: (context, appState, _) => Text(
                          'Gym: ${appState.gym ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const Divider(color: Colors.greenAccent),
                      Consumer<ApplicationState>(
                        builder: (context, appState, _) => Text(
                          '3대 중량: ${appState.maxSquat ?? 'N/A'} kg',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context, listen: false);
    _nicknameController.text = appState.nickname ?? '';
    _gymController.text = appState.gym ?? '';
    _maxSquatController.text = appState.maxSquat.toString();
    _selectedGender = appState.gender;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: _selectedImage == null
                        ? appState.userprofile == null
                            ? Image.asset('assets/logo.png', height: 100)
                            : Image.network(appState.userprofile!, height: 100)
                        : Image.file(_selectedImage!, height: 100),
                  ),
                ),
                _buildEditableField(
                  'Nickname',
                  _nicknameController,
                ),
                _buildGenderField(),
                _buildEditableField(
                  'Gym',
                  _gymController,
                ),
                _buildEditableField(
                  'Max Squat',
                  _maxSquatController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveProfile();
                Navigator.of(context).pop();
                setState(() {});
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.black),
          ),
          TextField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender:',
            style: const TextStyle(color: Colors.black),
          ),
          DropdownButton<String>(
            value: _selectedGender,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black),
            items: <String>['Male', 'Female', 'Other']
                .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                })
                .toList()
                .cast<DropdownMenuItem<String>>(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final appState = Provider.of<ApplicationState>(context, listen: false);

    final updatedNickname = _nicknameController.text;
    final updatedGender = _selectedGender;
    final updatedGym = _gymController.text;
    final updatedMaxSquat = int.tryParse(_maxSquatController.text) ?? 0;
    String? imageUrl;

    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(appState.uid)
        .update({
      'nickname': updatedNickname,
      'gender': updatedGender,
      'gym': updatedGym,
      'squatCount': updatedMaxSquat,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    setState(() {
      appState.nickname = updatedNickname;
      appState.gender = updatedGender;
      appState.gym = updatedGym;
      appState.maxSquat = updatedMaxSquat.toString();
      if (imageUrl != null) appState.userprofile = imageUrl;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully'),
      ),
    );
  }
}
