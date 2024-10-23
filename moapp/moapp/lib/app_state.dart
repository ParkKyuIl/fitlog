import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider, GoogleAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';
import 'gym_map_page.dart';
import 'firebase_service.dart';

final FirestoreService _firebaseService = FirestoreService();

class ApplicationState extends ChangeNotifier {
  List<Map<String, dynamic>> _leaderboard = [];
  List<Gym> _gyms = [];
  String? _videoUrl;

  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  List<Gym> get gyms => _gyms;
  String? get videoUrl => _videoUrl;

  ApplicationState() {
    debugPrint('initializing...');
    init();
  }

  StreamSubscription<QuerySnapshot>? _productSubScription;
  bool _loggedIn = false;
  String? userprofile;
  String uid = "";
  String email = "Anonymous";
  String? nickname;
  String? gender;
  String? gym;
  String? maxSquat;

  bool get loggedIn => _loggedIn;
  XFile? image;

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([EmailAuthProvider()]);

    await loadData();

    FirebaseAuth.instance.userChanges().listen((user) async {
      if (user != null) {
        if (!user.isAnonymous) {
          if (user.photoURL != null) {
            userprofile = user.photoURL!;
          }
          if (user.email != null) {
            email = user.email!;
          }
          uid = user.uid;

          // 추가된 사용자 정보 로드
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            nickname = data['nickname'];
            gender = data['gender'];
            gym = data['gym'];
            userprofile = data['imageUrl'];
            maxSquat = data['squatCount'].toString();
          }

          _loggedIn = true;
          debugPrint("current uid : " + uid);
        } else {
          uid = user.uid;
          email = "Anonymous";
        }
        notifyListeners();
      } else {
        email = "Anonymous";
        userprofile = null;
        _loggedIn = false;
        image = null;

        notifyListeners();
      }
    });
  }

  Future<void> loadData() async {
    try {
      _leaderboard = await _firebaseService.getLeaderboard();
      _gyms = await _firebaseService.getGyms();
      _videoUrl = await _firebaseService.getRandomVideoUrl();
      notifyListeners();
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> setUserProfile(String nickname, String gender, String gym,
      String? imageUrl, String maxSquat) async {
    this.nickname = nickname;
    this.gender = gender;
    this.gym = gym;
    this.userprofile = imageUrl;
    this.maxSquat = maxSquat;
    notifyListeners();
  }

  Future<void> refreshLoggedInUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    await currentUser.reload();
  }
}
