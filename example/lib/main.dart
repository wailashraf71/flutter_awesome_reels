import 'package:flutter/material.dart';

import 'data/sample_data.dart';
import 'screens/analytics_screen.dart';
import 'screens/demo_reels_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Awesome Reels Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Awesome Reels'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.video_library,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to Flutter Awesome Reels',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'A comprehensive package for creating TikTok-style reels with advanced features',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                _buildFeatureCard(
                  context,
                  'Basic Demo',
                  'Experience the default reels with sample videos',
                  Icons.play_circle_filled,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DemoReelsScreen(
                        reels: SampleData.basicReels,
                        title: 'Basic Demo',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFeatureCard(
                  context,
                  'Analytics Dashboard',
                  'View detailed analytics and metrics',
                  Icons.analytics,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFeatureCard(
                  context,
                  'Premium Features',
                  'See all features in action',
                  Icons.star,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DemoReelsScreen(
                        reels: SampleData.premiumReels,
                        title: 'Premium Features',
                        config: SampleData.premiumConfig,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white.withAlpha(128),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
