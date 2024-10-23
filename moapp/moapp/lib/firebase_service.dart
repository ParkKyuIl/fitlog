import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'gym_map_page.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    QuerySnapshot snapshot = await _db
        .collection('users')
        .orderBy('squatCount', descending: true)
        .get();
    List<Map<String, dynamic>> leaderboard = snapshot.docs.map((doc) {
      return {
        'nickname': doc['nickname'],
        'squatCount': doc['squatCount'],
        'gym': doc['gym'],
        'imageUrl': doc['imageUrl'],
      };
    }).toList();
    return leaderboard;
  }

  Future<List<Gym>> getGyms() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('gyms').get();
      List<Gym> gyms =
          snapshot.docs.map((doc) => Gym.fromDocument(doc)).toList();
      return gyms;
    } catch (e) {
      throw Exception('Error loading gyms: $e');
    }
  }

  Future<String> getRandomVideoUrl() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('videos').get();
      List<QueryDocumentSnapshot> documents = snapshot.docs;
      Random random = Random();
      int randomIndex = random.nextInt(documents.length);
      DocumentSnapshot randomDoc = documents[randomIndex];
      return randomDoc['url'];
    } catch (e) {
      throw Exception('Error loading video URL: $e');
    }
  }
}
