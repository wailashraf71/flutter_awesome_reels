import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_awesome_reels/flutter_awesome_reels.dart';
import 'demo_reels_screen.dart';

/// Playground screen for testing and configuring reel features
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  final RxBool _showProgressBar = true.obs;
  final RxBool _enableGestures = true.obs;
  final RxBool _enableCaching = true.obs;
  final RxBool _enableAutoPlay = true.obs;
  final RxBool _enableMute = false.obs;
  final RxDouble _volume = 1.0.obs;
  final RxInt _preloadRange = 2.obs;
  final RxBool _enableLongPressControls = true.obs;
  final RxBool _enableDoubleTapLike = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reels Playground'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Video Controls'),
            _buildVideoControlsSection(),
            const SizedBox(height: 20),
            
            _buildSectionHeader('Interaction Features'),
            _buildInteractionSection(),
            const SizedBox(height: 20),
            
            _buildSectionHeader('Performance Settings'),
            _buildPerformanceSection(),            const SizedBox(height: 20),
              _buildSectionHeader('UI Customization'),
            _buildUISection(),
            const SizedBox(height: 30),
            
            _buildSectionHeader('Live Preview'),
            _buildLivePreviewSection(),
            const SizedBox(height: 30),
            
            _buildApplyButton(),
            const SizedBox(height: 20),
            
            _buildDemoButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVideoControlsSection() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Obx(() => SwitchListTile(
              title: const Text('Auto Play', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Automatically play videos when visible', 
                  style: TextStyle(color: Colors.white70)),
              value: _enableAutoPlay.value,
              onChanged: (value) => _enableAutoPlay.value = value,
              activeColor: Colors.white,
            )),
            
            Obx(() => SwitchListTile(
              title: const Text('Mute by Default', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Start videos muted', 
                  style: TextStyle(color: Colors.white70)),
              value: _enableMute.value,
              onChanged: (value) => _enableMute.value = value,
              activeColor: Colors.white,
            )),
            
            const Divider(color: Colors.white30),
            
            Obx(() => ListTile(
              title: const Text('Volume', style: TextStyle(color: Colors.white)),
              subtitle: Slider(
                value: _volume.value,
                onChanged: (value) => _volume.value = value,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_volume.value * 100).round()}%',
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionSection() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Obx(() => SwitchListTile(
              title: const Text('Long Press Controls', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Long press to pause, release to play', 
                  style: TextStyle(color: Colors.white70)),
              value: _enableLongPressControls.value,
              onChanged: (value) => _enableLongPressControls.value = value,
              activeColor: Colors.white,
            )),
            
            Obx(() => SwitchListTile(
              title: const Text('Double Tap Like', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Double tap to like with animation', 
                  style: TextStyle(color: Colors.white70)),
              value: _enableDoubleTapLike.value,
              onChanged: (value) => _enableDoubleTapLike.value = value,
              activeColor: Colors.white,
            )),
            
            Obx(() => SwitchListTile(
              title: const Text('Gesture Controls', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Enable swipe and tap gestures', 
                  style: TextStyle(color: Colors.white70)),
              value: _enableGestures.value,
              onChanged: (value) => _enableGestures.value = value,
              activeColor: Colors.white,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Obx(() => SwitchListTile(
              title: const Text('Enable Caching', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Cache videos for better performance', 
                  style: TextStyle(color: Colors.white70)),
              value: _enableCaching.value,
              onChanged: (value) => _enableCaching.value = value,
              activeColor: Colors.white,
            )),
            
            const Divider(color: Colors.white30),
            
            Obx(() => ListTile(
              title: const Text('Preload Range', style: TextStyle(color: Colors.white)),
              subtitle: Text('Preload ${_preloadRange.value} videos ahead/behind', 
                  style: const TextStyle(color: Colors.white70)),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _preloadRange.value.toDouble(),
                  onChanged: (value) => _preloadRange.value = value.round(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildUISection() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Obx(() => SwitchListTile(
              title: const Text('Show Progress Bar', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Display video progress at bottom', 
                  style: TextStyle(color: Colors.white70)),
              value: _showProgressBar.value,
              onChanged: (value) => _showProgressBar.value = value,
              activeColor: Colors.white,
            )),
            
            const ListTile(
              title: Text('Play/Pause Icon', style: TextStyle(color: Colors.white)),
              subtitle: Text('Always centered when shown', 
                  style: TextStyle(color: Colors.white70)),
              trailing: Icon(Icons.play_circle_filled, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );  }

  Widget _buildLivePreviewSection() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'See your settings in action with this mini preview:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              width: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildMiniReelsPlayer(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap "Apply Settings" to see changes reflected here',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMiniReelsPlayer() {
    // Create a mini reel configuration based on current settings
    final config = ReelConfig(
      showProgressIndicator: _showProgressBar.value,
      enableCaching: _enableCaching.value,
      accentColor: Colors.blue,
      textColor: Colors.white,
      showFollowButton: true,
      showBookmarkButton: true,
      showDownloadButton: false, // Disabled for mini preview
      showMoreButton: true,
      bookmarkInMoreMenu: true,
      downloadInMoreMenu: true,
      followButtonColor: Colors.white,
      followingButtonColor: Colors.white70,
      preloadConfig: PreloadConfig(
        preloadAhead: _preloadRange.value,
        preloadBehind: 1,
      ),
      videoPlayerConfig: VideoPlayerConfig(
        startMuted: _enableMute.value,
        defaultVolume: _volume.value,
      ),
    );

    // Use only the first reel for mini preview
    final miniReels = SampleData.basicReels.take(1).toList();

    return AwesomeReels(
      reels: miniReels,
      config: config,
      onReelChanged: (index) {},
      onReelLiked: (reel) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liked in preview!'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }

  Widget _buildApplyButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _applySettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Apply Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDemoButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _launchDemo,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Go to Demo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _showProgressBar.value = true;
      _enableGestures.value = true;
      _enableCaching.value = true;
            _enableAutoPlay.value = true;
      _enableMute.value = false;
      _volume.value = 1.0;
      _preloadRange.value = 2;
      _enableLongPressControls.value = true;
      _enableDoubleTapLike.value = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to default settings'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _applySettings() {
    // In a real implementation, these settings would be applied to the reel controller
    final settings = {
      'showProgressBar': _showProgressBar.value,
      'enableGestures': _enableGestures.value,
      'enableCaching': _enableCaching.value,
      'enableAutoPlay': _enableAutoPlay.value,
      'enableMute': _enableMute.value,
      'volume': _volume.value,
      'preloadRange': _preloadRange.value,
      'enableLongPressControls': _enableLongPressControls.value,
      'enableDoubleTapLike': _enableDoubleTapLike.value,
    };
    
    debugPrint('Applied settings: $settings');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings applied successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate back to demo
    Navigator.of(context).pop();
  }
  void _launchDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DemoReelsScreen(
          reels: SampleData.basicReels,
          title: 'Instagram-like Reels Demo',
        ),
      ),
    );
  }
}
