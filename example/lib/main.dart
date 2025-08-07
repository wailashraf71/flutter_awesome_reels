import 'package:flutter/material.dart';

import 'screens/playground_screen.dart';
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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF38BDF8),
          thumbColor: Color(0xFF38BDF8),
          inactiveTrackColor: Colors.white30,
        ),
      ),
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1120), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -40,
                child: _GradientOrb(
                  size: 180,
                  colors: const [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
                ),
              ),
              Positioned(
                bottom: -80,
                left: -40,
                child: _GradientOrb(
                  size: 240,
                  colors: const [Color(0xFF2563EB), Color(0xFF22D3EE)],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.play_circle_fill,
                            size: 40, color: Color(0xFF93C5FD)),
                        SizedBox(width: 12),
                        Text(
                          'Awesome Reels',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: _GradientText(
                        'Welcome to Flutter Awesome',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF60A5FA), Color(0xFF22D3EE)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Build playful, modern, and professional reels experiences with blue gradient flair.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _FeatureCard(
                      title: 'Basic Demo',
                      description:
                          'Experience the default reels with sample videos',
                      icon: Icons.play_circle_filled,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DemoReelsScreen(
                            reels: SampleData.basicReels,
                            title: 'Basic Demo',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FeatureCard(
                      title: 'Settings Playground',
                      description: 'Test and configure reel features',
                      icon: Icons.settings,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF22D3EE)],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlaygroundScreen(),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Old card kept for reference has been replaced with modern gradient cards.
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
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
              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const _GradientText(this.text, {required this.style, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _GradientOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GradientOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
