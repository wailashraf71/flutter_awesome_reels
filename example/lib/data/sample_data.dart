import 'package:flutter/material.dart';
import 'package:flutter_awesome_reels/flutter_awesome_reels.dart';

class SampleData {
  static final List<ReelModel> basicReels = [
    ReelModel(
      id: '1',
      videoUrl:
          'https://videos.pexels.com/video-files/7657449/7657449-hd_1920_1080_25fps.mp4',
      user: const ReelUser(
        id: 'u1',
        username: 'alice',
        displayName: 'Alice',
      ),
      likesCount: 120,
      commentsCount: 15,
      sharesCount: 5,
      tags: ['fun', 'bunny'],
      audio: const ReelAudio(title: 'Sample Music'),
      duration: 10000,
      isLiked: false,
      views: 1000,
      location: 'Wonderland',
    ),
    ReelModel(
      id: '2',
      videoUrl:
          'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      user: const ReelUser(
        id: 'u2',
        username: 'bob',
        displayName: 'Bob',
        isFollowing: true,
      ),
      likesCount: 200,
      commentsCount: 30,
      sharesCount: 10,
      tags: ['adventure', 'travel'],
      audio: const ReelAudio(title: 'Adventure Tune'),
      duration: 12000,
      isLiked: true,
      views: 2500,
      location: 'Mountains',
    ),
  ];

  static final List<ReelModel> premiumReels = [
    ...basicReels,
    ReelModel(
      id: '3',
      videoUrl:
          'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      user: const ReelUser(
        id: 'u3',
        username: 'charlie',
        displayName: 'Charlie',
      ),
      likesCount: 350,
      commentsCount: 50,
      sharesCount: 20,
      tags: ['premium', 'exclusive'],
      audio: const ReelAudio(title: 'Premium Beat'),
      duration: 15000,
      isLiked: false,
      views: 5000,
      location: 'City Lights',
    ),
  ];

  static final ReelConfig premiumConfig = ReelConfig(
    accentColor: const Color(0xFFFF006E),
  );
}
