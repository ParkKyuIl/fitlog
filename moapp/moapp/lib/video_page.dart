import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPage extends StatefulWidget {
  final String videoUrl;

  VideoPage({required this.videoUrl});

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();
    _initializeYoutubeController(widget.videoUrl);
  }

  void _initializeYoutubeController(String videoUrl) {
    _youtubeController = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(videoUrl)!,
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('오늘의 추천 운동'),
      ),
      body: Container(
        color: Colors.black, // 배경을 검은색으로 설정
        child: Align(
          alignment: FractionalOffset(0.5, 0.4), // 조금 더 위로 올리기
          child: YoutubePlayer(
            controller: _youtubeController,
            showVideoProgressIndicator: true,
          ),
        ),
      ),
    );
  }
}
