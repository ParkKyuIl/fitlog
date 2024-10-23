import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:math';
import 'app_state.dart';
import 'firebase_service.dart';
import 'gym_map_page.dart';
import 'pose_detector_view.dart';
import 'profile.dart';
import 'video_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    GymMapPage(),
    PoseDetectorView(),
    Profile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.greenAccent,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '체육관 찾기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '자세 체크',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> leaderboard = [];
  List<Gym> gyms = [];
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadLeaderboard();
    await _loadGyms();
    await _loadVideoUrl();
  }

  Future<void> _loadLeaderboard() async {
    try {
      FirestoreService firestoreService = FirestoreService();
      List<Map<String, dynamic>> data = await firestoreService.getLeaderboard();
      if (mounted) {
        setState(() {
          leaderboard = data;
        });
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
    }
  }

  Future<void> _loadGyms() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('gyms').get();
      List<Gym> gymList =
          snapshot.docs.map((doc) => Gym.fromDocument(doc)).toList();
      if (mounted) {
        setState(() {
          gyms = gymList;
        });
      }
    } catch (e) {
      print('Error loading gyms: $e');
    }
  }

  Future<void> _loadVideoUrl() async {
    try {
      await Future.delayed(Duration(milliseconds: 100)); // 잠시 대기
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('videos').get();
      List<QueryDocumentSnapshot> documents = snapshot.docs;
      Random random = Random();
      int randomIndex = random.nextInt(documents.length);
      DocumentSnapshot randomDoc = documents[randomIndex];
      String url = randomDoc['url'];
      if (mounted) {
        setState(() {
          _videoUrl = url;
        });
      }
    } catch (e) {
      print('Error loading video URL: $e');
    }
  }

  String getYoutubeThumbnailUrl(String videoUrl) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    return 'https://img.youtube.com/vi/$videoId/0.jpg'; // YouTube 썸네일 URL 형식
  }

  Future<void> _refreshPage() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshPage,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26.0, 62.0, 46.0, 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<ApplicationState>(
              builder: (context, appState, _) {
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: appState.userprofile != null
                          ? NetworkImage(appState.userprofile!)
                          : AssetImage('assets/google_logo.png')
                              as ImageProvider,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요 ${appState.nickname ?? '사용자'}님',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '오늘 운동 하셨나요?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              '오늘의 추천 운동',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildVideoCard(context),
            const SizedBox(height: 24),
            Text(
              '중량 리더보드',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildLeaderboard(),
            const SizedBox(height: 24),
            Text(
              '박스 리뷰',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildSubscriptionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_videoUrl != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPage(videoUrl: _videoUrl!),
            ),
          );
        }
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: _videoUrl != null
              ? DecorationImage(
                  image: NetworkImage(getYoutubeThumbnailUrl(_videoUrl!)),
                  fit: BoxFit.cover,
                )
              : DecorationImage(
                  image: AssetImage('assets/green.jpeg'),
                  fit: BoxFit.cover,
                ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 64,
              ),
            ),
            if (_videoUrl == null)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      children: leaderboard.map((entry) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: entry['imageUrl'] != null
                ? NetworkImage(entry['imageUrl'])
                : AssetImage('assets/google_logo.png') as ImageProvider,
          ),
          title: Text(
            '${entry['nickname'] ?? 'Unknown'} (${entry['gym'] ?? 'Unknown'})',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          trailing: Text(
            '${entry['squatCount'] ?? 0} kg',
            style: TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionSection() {
    return Container(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: gyms.map((gym) {
          return FutureBuilder<double>(
            future: _getGymRating(gym.name),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              double rating = snapshot.data ?? 0.0;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GymDetailPage(gym: gym),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: gym.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(gym.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : DecorationImage(
                            image: AssetImage('assets/google_logo.png'),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            gym.name,
                            style: TextStyle(
                              backgroundColor: Colors.black.withOpacity(0.5),
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Future<double> _getGymRating(String gymName) async {
    QuerySnapshot commentsSnapshot = await FirebaseFirestore.instance
        .collection('gyms')
        .doc(gymName)
        .collection('comments')
        .get();

    if (commentsSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in commentsSnapshot.docs) {
        totalRating += doc['rating'];
      }
      return totalRating / commentsSnapshot.docs.length;
    }
    return 0.0;
  }
}
