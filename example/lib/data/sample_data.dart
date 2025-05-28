import 'package:flutter_awesome_reels/flutter_awesome_reels.dart';

class SampleData {
  static final List<ReelModel> basicReels = [
    ReelModel(
      id: '1',
      videoUrl:
          'https://www.sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
      user: const ReelUser(
        id: 'u1',
        username: 'alice',
        displayName: 'Alice in Wonderland',
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
          'https://videos.pexels.com/video-files/4865389/4865389-uhd_1440_2732_25fps.mp4',
      user: const ReelUser(
        id: 'u2',
        username: 'bob',
        displayName: 'Bob Builder',
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
    ),  ];
}
