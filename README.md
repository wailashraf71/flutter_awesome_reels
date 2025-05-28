# Flutter Awesome Reels 🎥

A powerful, customizable Flutter widget for building TikTok/Instagram-style vertical video reels with advanced features like caching, analytics, and rich interactions.

![Flutter Awesome Reels Preview](preview.png)

---

## ✨ Features

### 🎬 **Core Video Features**
- **Vertical Swipeable Feed**: Smooth PageView-based vertical scrolling
- **Auto-play & Pause**: Intelligent video playback based on visibility
- **Long-press Controls**: Pause/play videos with long-press gestures
- **Looping Videos**: Seamless video loops for endless entertainment
- **Intelligent Retry**: Automatic retry with exponential backoff for failed loads

### 🎨 **Rich Interactions**
- **Double-tap to Like**: Instagram-style like animation
- **Comment System**: Beautiful native comment bottom sheet with keyboard handling
- **Follow/Unfollow**: Configurable follow button with custom colors
- **Share & Bookmark**: Built-in sharing and bookmarking functionality
- **More Menu**: Customizable overflow menu for additional actions

### ⚡ **Performance & Caching**
- **Smart Caching**: Advanced video caching with automatic cleanup
- **Preloading**: Configurable video preloading (ahead/behind)
- **Memory Management**: Efficient memory usage with lifecycle management
- **Analytics Ready**: Built-in analytics service for engagement tracking

### 🎛️ **Customization**
- **Button Organization**: Move bookmark/download to more menu
- **Color Themes**: Customizable accent colors and follow button colors
- **Loading States**: Custom loading and error widgets
- **Progress Indicators**: Configurable progress bars and time labels

---

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_awesome_reels: ^0.0.2
```

Then run:
```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1. Import the package

```dart
import 'package:flutter_awesome_reels/flutter_awesome_reels.dart';
```

### 2. Create your reel data

```dart
final List<ReelModel> reels = [
  ReelModel(
    id: '1',
    videoUrl: 'https://example.com/video1.mp4',
    user: ReelUser(
      id: 'u1',
      username: 'john_doe',
      displayName: 'John Doe',
    ),
    caption: 'Amazing sunset! #nature #beautiful',
    likesCount: 1250,
    commentsCount: 89,
    tags: ['nature', 'sunset'],
  ),
  // Add more reels...
];
```

### 3. Display the reels

```dart
class ReelsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AwesomeReels(
        reels: reels,
        config: ReelConfig(
          // Customize appearance and behavior
          showProgressIndicator: true,
          enableCaching: true,
          accentColor: Colors.red,
          followButtonColor: Colors.white,
          bookmarkInMoreMenu: true,
        ),
        onReelLiked: (reel) {
          print('Liked: ${reel.id}');
        },
        onReelShared: (reel) {
          print('Shared: ${reel.id}');
        },
        onUserFollowed: (user) {
          print('Followed: ${user.username}');
        },
      ),
    );
  }
}
```

---

## 🎛️ Configuration Options

### ReelConfig

```dart
ReelConfig(
  // UI Appearance
  backgroundColor: Colors.black,
  accentColor: Colors.red,
  textColor: Colors.white,
  
  // Button Configuration
  showFollowButton: true,
  followButtonColor: Colors.white,
  followingButtonColor: Colors.white70,
  bookmarkInMoreMenu: true,     // Move bookmark to more menu
  downloadInMoreMenu: true,     // Move download to more menu
  
  // Video Controls
  showProgressIndicator: true,
  enableCaching: true,
  
  // Performance
  preloadConfig: PreloadConfig(
    preloadAhead: 2,
    preloadBehind: 1,
  ),
  
  // Analytics
  enableAnalytics: true,
)
```

### Button Organization

Control where action buttons appear:

```dart
ReelConfig(
  // Main action bar buttons
  showBookmarkButton: true,
  showDownloadButton: true,
  
  // Move to more menu (recommended for cleaner UI)
  bookmarkInMoreMenu: true,    // Moves bookmark to ⋯ menu
  downloadInMoreMenu: true,    // Moves download to ⋯ menu
)
```

---

## 📱 Playground Example

Try our interactive playground to see all features in action:

```bash
cd example
flutter run
```

The playground includes:
- **Live Preview**: Mini reels player with real-time configuration
- **Settings Panel**: Adjust all configuration options
- **Feature Testing**: Test long-press, double-tap, and other interactions

---

## 🔧 Advanced Usage

### Custom Actions

Add custom actions to the more menu:

```dart
ReelConfig(
  customActions: [
    CustomAction(
      icon: Icons.report,
      title: 'Report',
      onTap: (reel) {
        // Handle report action
      },
    ),
    CustomAction(
      icon: Icons.download,
      title: 'Save to Gallery',
      onTap: (reel) {
        // Handle save action
      },
    ),
  ],
)
```

### Analytics Integration

```dart
// Initialize analytics
AnalyticsService.instance.initialize(
  enabled: true,
  onAnalyticsReported: (analytics) {
    // Send to your analytics service
    print('Video ${analytics.reelId} watched for ${analytics.watchDuration}');
  },
);
```

### Custom Loading & Error Widgets

```dart
ReelConfig(
  loadingWidgetBuilder: (context) {
    return Center(
      child: CircularProgressIndicator(color: Colors.red),
    );
  },
  errorWidgetBuilder: (context, error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 48),
          Text('Failed to load video', style: TextStyle(color: Colors.white)),
          ElevatedButton(
            onPressed: () => /* retry logic */,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  },
)
```

---

## 🎯 Key Features Showcase

### Long-press Controls
- **Pause on press**: Hold down to pause video
- **Resume on release**: Release to continue playing
- **Visual feedback**: Smooth state transitions

### Smart Caching
- **Automatic management**: Videos cached automatically
- **Size limits**: Configurable cache size (default: 100MB)
- **Intelligent cleanup**: Old cache files automatically removed

### Comment System
- **Native bottom sheet**: Beautiful, iOS/Android native feel
- **Keyboard handling**: Proper keyboard animations
- **Rich interactions**: Like comments, reply functionality

---

## 🔒 Permissions

Add these permissions to your app:

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 📋 Requirements

- **Flutter**: >=3.0.0
- **Dart**: >=3.0.0
- **iOS**: >=12.0
- **Android**: API level 21+

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🌟 Star History

If you find this package helpful, please give it a ⭐ on [GitHub](https://github.com/wailashraf71/flutter_awesome_reels)!

---

## 📚 More Examples

Check out the `/example` directory for more comprehensive examples including:
- Basic implementation
- Custom theming
- Analytics integration
- Performance optimization
- Advanced configuration

Happy coding! 🚀
