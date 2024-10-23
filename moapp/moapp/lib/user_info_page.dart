import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class UserInfoPage extends StatefulWidget {
  final User user;

  const UserInfoPage({Key? key, required this.user}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  int _currentStep = 0;
  String? _nickname;
  String? _gender;
  String? _gym;
  String? maxSqaut;
  File? _imageFile;
  String? _imageUrl;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child(widget.user.uid);
      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() => {});
      _imageUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Uploaded image URL: $_imageUrl');
    }
  }

  List<Step> getSteps() {
    return [
      Step(
        title:
            const Text('닉네임을 입력해주세요!', style: TextStyle(color: Colors.black)),
        content: TextFormField(
          style: TextStyle(color: Colors.black),
          decoration: const InputDecoration(labelText: '닉네임 입력'),
          onSaved: (value) {
            _nickname = value;
          },
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('성별', style: TextStyle(color: Colors.black)),
        content: DropdownButtonFormField<String>(
          items: const [
            DropdownMenuItem(
                child: Text('남성', style: TextStyle(color: Colors.black)),
                value: 'Male'),
            DropdownMenuItem(
                child: Text('여성', style: TextStyle(color: Colors.black)),
                value: 'Female'),
          ],
          onChanged: (value) {
            setState(() {
              _gender = value;
            });
          },
        ),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text('소속 체육관', style: TextStyle(color: Colors.black)),
        content: TextFormField(
          style: TextStyle(color: Colors.black),
          decoration: const InputDecoration(labelText: '소속 체육관 입력'),
          onSaved: (value) {
            _gym = value;
          },
        ),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text('3대 중량', style: TextStyle(color: Colors.black)),
        content: TextFormField(
          style: TextStyle(color: Colors.black),
          decoration: const InputDecoration(labelText: '3대 중량을 적어주세요!'),
          onSaved: (value) {
            maxSqaut = value;
          },
        ),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text('프로필 사진', style: TextStyle(color: Colors.black)),
        content: Column(
          children: [
            _imageFile == null
                ? const Text('이미지가 선택되지 않았습니다.',
                    style: TextStyle(color: Colors.black))
                : Image.file(_imageFile!),
            TextButton.icon(
              icon: const Icon(Icons.image, color: Colors.black),
              label: const Text('앨범에서 이미지를 선택해주세요!',
                  style: TextStyle(color: Colors.black)),
              onPressed: _pickImage,
            ),
          ],
        ),
        isActive: _currentStep >= 3,
      ),
    ];
  }

  void _submitDetails() async {
    _formKey.currentState?.save();
    await _uploadImage();

    if (!mounted) return; // 위젯이 여전히 마운트된 상태인지 확인

    // Firestore에 사용자 정보 저장
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .set({
      'nickname': _nickname,
      'gender': _gender,
      'gym': _gym,
      'imageUrl': _imageUrl,
      'squatCount': maxSqaut,
    });

    // ApplicationState에 사용자 정보 설정
    Provider.of<ApplicationState>(context, listen: false).setUserProfile(
      _nickname!,
      _gender!,
      _gym!,
      _imageUrl,
      maxSqaut!,
    );

    if (!mounted) return; // 위젯이 여전히 마운트된 상태인지 확인

    // GoRouter를 사용하여 홈 페이지로 네비게이션
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              const Text('User Info', style: TextStyle(color: Colors.black))),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < getSteps().length - 1) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              _submitDetails();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          steps: getSteps(),
        ),
      ),
    );
  }
}
