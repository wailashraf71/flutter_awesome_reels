import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility functions for the awesome reels package
class ReelUtils {
  ReelUtils._();
  /// Format duration to string (e.g., "1:23", "12:34")
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    }
    
    return "$minutes:$seconds";
  }

  /// Format duration from milliseconds to string
  static String formatDurationFromMilliseconds(int? milliseconds) {
    if (milliseconds == null) return "00:00";
    return formatDuration(Duration(milliseconds: milliseconds));
  }

  /// Format large numbers (e.g., 1000 -> "1K", 1500000 -> "1.5M")
  static String formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      double value = count / 1000;
      return value % 1 == 0 ? '${value.toInt()}K' : '${value.toStringAsFixed(1)}K';
    }
    if (count < 1000000000) {
      double value = count / 1000000;
      return value % 1 == 0 ? '${value.toInt()}M' : '${value.toStringAsFixed(1)}M';
    }
    double value = count / 1000000000;
    return value % 1 == 0 ? '${value.toInt()}B' : '${value.toStringAsFixed(1)}B';
  }

  /// Format file size (e.g., 1024 -> "1 KB", 1048576 -> "1 MB")
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Generate a unique ID
  static String generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${timestamp}_$random';
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https'));
    } catch (e) {
      return false;
    }
  }

  /// Check if URL is a video file based on extension
  static bool isVideoUrl(String url) {
    final videoExtensions = [
      '.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.m4v', '.3gp'
    ];
    
    final lowercaseUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowercaseUrl.contains(ext));
  }

  /// Extract video ID from various video platforms
  static String? extractVideoId(String url) {
    // YouTube
    RegExp youtubeRegex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    
    final youtubeMatch = youtubeRegex.firstMatch(url);
    if (youtubeMatch != null) {
      return youtubeMatch.group(1);
    }
    
    // Vimeo
    RegExp vimeoRegex = RegExp(r'vimeo\.com\/(\d+)', caseSensitive: false);
    final vimeoMatch = vimeoRegex.firstMatch(url);
    if (vimeoMatch != null) {
      return vimeoMatch.group(1);
    }
    
    return null;
  }

  /// Get thumbnail URL from video URL (platform specific)
  static String? getThumbnailUrl(String videoUrl) {
    final videoId = extractVideoId(videoUrl);
    if (videoId == null) return null;
    
    // YouTube thumbnail
    if (videoUrl.contains('youtube') || videoUrl.contains('youtu.be')) {
      return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    }
    
    // Vimeo thumbnail (requires API call in real implementation)
    if (videoUrl.contains('vimeo')) {
      return 'https://vumbnail.com/$videoId.jpg';
    }
    
    return null;
  }

  /// Calculate aspect ratio from width and height
  static double calculateAspectRatio(double width, double height) {
    if (height == 0) return 16 / 9; // Default aspect ratio
    return width / height;
  }

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375; // Base width (iPhone 6/7/8)
    return baseFontSize * scaleFactor.clamp(0.8, 1.2);
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context, EdgeInsets basePadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375; // Base width
    
    return EdgeInsets.only(
      left: basePadding.left * scaleFactor,
      top: basePadding.top * scaleFactor,
      right: basePadding.right * scaleFactor,
      bottom: basePadding.bottom * scaleFactor,
    );
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final diagonal = _calculateDiagonal(context);
    return diagonal > 7.0; // Inches
  }

  /// Calculate device diagonal in inches
  static double _calculateDiagonal(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    final widthInches = size.width * devicePixelRatio / 160;
    final heightInches = size.height * devicePixelRatio / 160;
    
    return sqrt(widthInches * widthInches + heightInches * heightInches);
  }

  /// Debounce function calls
  static void debounce(Function() function, Duration delay, [Timer? timer]) {
    timer?.cancel();
    timer = Timer(delay, function);
  }

  /// Throttle function calls
  static bool throttle(String key, Duration duration) {
    final now = DateTime.now();
    final lastCall = _throttleMap[key];
    
    if (lastCall == null || now.difference(lastCall) >= duration) {
      _throttleMap[key] = now;
      return true;
    }
    
    return false;
  }
  
  static final Map<String, DateTime> _throttleMap = {};

  /// Convert hex color string to Color
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convert Color to hex string
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  /// Calculate luminance of a color
  static double getLuminance(Color color) {
    return color.computeLuminance();
  }

  /// Get contrasting text color (black or white) for a background color
  static Color getContrastingColor(Color backgroundColor) {
    return getLuminance(backgroundColor) > 0.5 ? Colors.black : Colors.white;
  }

  /// Generate gradient colors
  static List<Color> generateGradient(Color startColor, Color endColor, int steps) {
    final colors = <Color>[];
    
    for (int i = 0; i < steps; i++) {
      final ratio = i / (steps - 1);
      final red = (startColor.red + (endColor.red - startColor.red) * ratio).round();
      final green = (startColor.green + (endColor.green - startColor.green) * ratio).round();
      final blue = (startColor.blue + (endColor.blue - startColor.blue) * ratio).round();
      final alpha = (startColor.alpha + (endColor.alpha - startColor.alpha) * ratio).round();
      
      colors.add(Color.fromARGB(alpha, red, green, blue));
    }
    
    return colors;
  }

  /// Animate value with easing
  static double easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  /// Linear interpolation
  static double lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  /// Clamp value between min and max
  static T clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Map value from one range to another
  static double mapRange(double value, double inMin, double inMax, double outMin, double outMax) {
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  }

  /// Check if two rectangles intersect
  static bool rectsIntersect(Rect rect1, Rect rect2) {
    return rect1.left < rect2.right &&
           rect1.right > rect2.left &&
           rect1.top < rect2.bottom &&
           rect1.bottom > rect2.top;
  }

  /// Get distance between two points
  static double getDistance(Offset point1, Offset point2) {
    final dx = point1.dx - point2.dx;
    final dy = point1.dy - point2.dy;
    return sqrt(dx * dx + dy * dy);
  }

  /// Get angle between two points in radians
  static double getAngle(Offset point1, Offset point2) {
    final dx = point2.dx - point1.dx;
    final dy = point2.dy - point1.dy;
    return atan2(dy, dx);
  }

  /// Convert radians to degrees
  static double radiansToDegrees(double radians) {
    return radians * 180 / pi;
  }

  /// Convert degrees to radians
  static double degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Generate random color
  static Color randomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if string contains only numbers
  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get platform-specific file path separator
  static String get pathSeparator => Platform.pathSeparator;

  /// Check if app is running in debug mode
  static bool get isDebugMode => kDebugMode;

  /// Check if app is running in release mode
  static bool get isReleaseMode => kReleaseMode;
  /// Get current timestamp in milliseconds
  static int get timestamp => DateTime.now().millisecondsSinceEpoch;

  /// Convert timestamp to DateTime
  static DateTime timestampToDateTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Get time ago string (e.g., "2 hours ago", "3 days ago")
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
