import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Videos',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: VideoListScreen(),
    );
  }
}

class VideoListScreen extends StatefulWidget {
  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<String> _videoUrls = [];

  @override
  void initState() {
    super.initState();
    _getVideoUrls();
  }

  void _getVideoUrls() async {
  // Get the list of all videos in the 'videos' collection in Firebase Storage
  final ListResult result =
      await FirebaseStorage.instance.ref('videos/').listAll();

  // Get the download URL for each video and add it to the _videoUrls list
  List<String> videoUrls = [];

  // Play the first video as soon as it's fetched
  final firstUrl = await result.items.first.getDownloadURL();
  videoUrls.add(firstUrl);
  setState(() {
    _videoUrls = videoUrls;
  });

  // Start fetching other video URLs in the background
  for (int i = 1; i < result.items.length; i++) {
    final ref = result.items[i];
    final url = await ref.getDownloadURL();
    setState(() {
      _videoUrls.add(url);
    });
  }

  // Shuffle the list of video URLs
  _videoUrls.shuffle();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TikTok Videos'),
      ),
      body: PageView.builder(
        itemCount: _videoUrls.length,
        itemBuilder: (BuildContext context, int index) {
          return VideoPlayerScreen(videoUrl: _videoUrls[index]);
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  VideoPlayerScreen({required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true); // set loop to true
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? Stack(
              children: [
                AspectRatio(
                  aspectRatio: 9 / 16,
                  child: VideoPlayer(_controller),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      backgroundColor: Colors.white,
                      playedColor: Colors.pinkAccent,
                      bufferedColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
