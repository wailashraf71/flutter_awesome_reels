## 0.0.2

### 🚀 New Features
* **Long-press Controls**: Added long-press to pause/play functionality with proper state tracking
* **Intelligent Retry System**: Enhanced video loading with exponential backoff and automatic cache clearing on failures
* **Configuration Enhancements**: Added new ReelConfig options:
  - `bookmarkInMoreMenu` - Move bookmark button to more menu (default: true)
  - `downloadInMoreMenu` - Move download button to more menu (default: true) 
  - `followButtonColor` - Configurable follow button color (default: white)
  - `followingButtonColor` - Color when user is following (default: white70)
* **Improved UI Organization**: Better button placement with configurable more menu options
* **Enhanced Comment System**: Redesigned comment bottom sheet with improved UI and keyboard handling
* **Live Preview Playground**: Added mini reels player in playground screen for real-time configuration testing

### 🔧 Improvements
* **Follow Button Styling**: Updated to use configurable colors instead of fixed accent color
* **Error Handling**: Better retry logic with cache management for failed video loads
* **Comment Interface**: Removed external dialog dependency, improved native comment experience
* **Code Organization**: Cleaned up duplicate imports and optimized widget structure

### 🗑️ Removed
* **Premium Features**: Removed premium-only features to maintain open-source nature
* **External Dependencies**: Reduced reliance on external dialog packages

### 🐛 Bug Fixes
* Fixed loading overlay persistence issues
* Improved video state management during long-press interactions
* Better handling of video controller lifecycle

## 0.0.1

* Initial release: TikTok/Instagram-style vertical video reels widget with caching, analytics, and rich interactions.
