import 'package:flutter/material.dart';
import 'package:flutter_awesome_reels/flutter_awesome_reels.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final List<String> videos = [
    'https://www.sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
    'https://www.sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: AwesomeReels(videoUrls: videos)),
    );
  }
}
