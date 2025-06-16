import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reel_config.dart';
import 'package:video_player/video_player.dart';
import 'package:crypto/crypto.dart';

/// Advanced cache manager for video files and thumbnails
class CacheManager {
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._internal();

  CacheManager._internal();

  late Dio _dio;
  late Directory _cacheDirectory;
  late CacheConfig _config;
  bool _isInitialized = false;

  final Map<String, CacheItem> _cacheIndex = {};
  final Map<String, Future<String?>> _downloadFutures = {};

  // LRU cache for video controllers
  final Map<String, DateTime> _controllerAccessTimes = {};
  final Map<String, dynamic> _videoControllers = {};
  final int _maxControllers = 5; // Tune as needed
  // Max cache size for video files (200MB)
  final int _maxCacheFileSize = 200 * 1024 * 1024;

  // In-memory cache for recently used files (fast access)
  final Map<String, String> _memoryFileCache = {};
  final int _maxMemoryFiles = 10;

  /// Initialize the cache manager
  Future<void> initialize() async {
    _cacheDirectory = await getTemporaryDirectory();
    await _loadCacheIndex();
    await _cleanupExpiredCache();
    await _enforceCacheSize();
  }

  /// Get cached file path for a URL (check memory cache first)
  String? getCachedFilePath(String url) {
    final cacheKey = _generateCacheKey(url);
    final item = _cacheIndex[cacheKey];
    if (item != null && !item.isExpired) {
      item.lastAccessTime = DateTime.now();
      return item.filePath;
    }
    return null;
  }

  /// Download and cache a file
  Future<String?> downloadAndCache(
    String url, {
    Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!_isInitialized) await initialize();

    // Check if already cached
    final cachedPath = getCachedFilePath(url);
    if (cachedPath != null) return cachedPath;

    // Check if download is already in progress
    if (_downloadFutures.containsKey(url)) {
      return await _downloadFutures[url];
    }

    // Start download
    final downloadFuture =
        _performDownload(url, onProgress: onProgress, cancelToken: cancelToken);
    _downloadFutures[url] = downloadFuture;

    try {
      final result = await downloadFuture;
      return result;
    } finally {
      _downloadFutures.remove(url);
    }
  }

  /// Perform the actual download
  Future<String?> _performDownload(
    String url, {
    Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final cacheKey = _generateCacheKey(url);
      final fileName = _generateFileName(url);
      final filePath = '${_cacheDirectory.path}/$fileName';

      // Download the file
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'User-Agent': 'AwesomeReels/1.0.0',
          },
        ),
      );

      // Verify file was downloaded successfully
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Downloaded file does not exist');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        await file.delete();
        throw Exception('Downloaded file is empty');
      }

      // Add to cache index and evict if needed
      final cacheItem = CacheItem(
        url: url,
        filePath: filePath,
        cacheKey: cacheKey,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        lastAccessTime: DateTime.now(),
        expiryTime: DateTime.now().add(_config.cacheDuration),
      );

      await _addToCacheIndex(cacheItem);

      // Enforce cache size limits
      await _enforceCacheSize();

      return filePath;
    } catch (e) {
      debugPrint('Cache download error for $url: $e');
      return null;
    }
  }

  /// Preload multiple URLs
  Future<void> preloadUrls(List<String> urls) async {
    final futures = urls.map((url) => downloadAndCache(url)).toList();
    await Future.wait(futures, eagerError: false);
  }

  /// Check if a URL is cached
  Future<bool> isCached(String url) async {
    final cachedPath = getCachedFilePath(url);
    return cachedPath != null;
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    if (!_isInitialized) return CacheStats.empty();

    int totalFiles = _cacheIndex.length;
    int totalSize = 0;
    int expiredFiles = 0;

    for (final item in _cacheIndex.values) {
      totalSize += item.fileSize;
      if (DateTime.now().isAfter(item.expiryTime)) {
        expiredFiles++;
      }
    }

    return CacheStats(
      totalFiles: totalFiles,
      totalSize: totalSize,
      expiredFiles: expiredFiles,
      cacheDirectory: _cacheDirectory.path,
    );
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      for (final item in _cacheIndex.values) {
        final file = File(item.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _cacheIndex.clear();
      await _saveCacheIndex();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Remove specific URL from cache
  Future<void> removeCachedUrl(String url) async {
    if (!_isInitialized) return;

    final cacheKey = _generateCacheKey(url);
    final cacheItem = _cacheIndex[cacheKey];

    if (cacheItem != null) {
      // Delete file
      final file = File(cacheItem.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from index
      _cacheIndex.remove(cacheKey);
      await _saveCacheIndex();
    }
  }

  /// Generate cache key from URL
  String _generateCacheKey(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  /// Generate filename from URL
  String _generateFileName(String url) {
    final uri = Uri.parse(url);
    final extension = uri.path.split('.').last;
    final cacheKey = _generateCacheKey(url);
    return '$cacheKey.$extension';
  }

  /// Check if cache item is valid
  Future<bool> _isCacheValid(CacheItem item) async {
    // Check if file exists
    final file = File(item.filePath);
    if (!await file.exists()) {
      _cacheIndex.remove(item.cacheKey);
      await _saveCacheIndex();
      return false;
    }

    // Check if expired
    if (DateTime.now().isAfter(item.expiryTime)) {
      await file.delete();
      _cacheIndex.remove(item.cacheKey);
      await _saveCacheIndex();
      return false;
    }

    return true;
  }

  /// Load cache index from storage
  Future<void> _loadCacheIndex() async {
    try {
      final file = File('${_cacheDirectory.path}/cache_index.json');
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _cacheIndex.clear();
        _cacheIndex.addAll(json.map((key, value) =>
            MapEntry(key, CacheItem.fromJson(value as Map<String, dynamic>))));
      }
    } catch (e) {
      debugPrint('Error loading cache index: $e');
      _cacheIndex.clear();
    }
  }

  /// Save cache index to storage
  Future<void> _saveCacheIndex() async {
    try {
      final file = File('${_cacheDirectory.path}/cache_index.json');
      final json =
          _cacheIndex.map((key, value) => MapEntry(key, value.toJson()));
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving cache index: $e');
    }
  }

  /// Cleanup expired cache items
  Future<void> _cleanupExpiredCache() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheIndex.entries) {
      if (now.isAfter(entry.value.expiryTime)) {
        expiredKeys.add(entry.key);

        // Delete file
        final file = File(entry.value.filePath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            debugPrint('Error deleting expired cache file: $e');
          }
        }
      }
    }

    // Remove from index
    for (final key in expiredKeys) {
      _cacheIndex.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      await _saveCacheIndex();
      debugPrint('Cleaned up \\${expiredKeys.length} expired cache items');
    }
  }

  /// Enforce cache size limits
  Future<void> _enforceCacheSize() async {
    final stats = await getCacheStats();

    if (stats.totalSize <= _config.maxCacheSize) return;

    // Sort by last access time (LRU)
    final sortedItems = _cacheIndex.values.toList()
      ..sort((a, b) => a.lastAccessTime.compareTo(b.lastAccessTime));

    int currentSize = stats.totalSize;
    final itemsToRemove = <CacheItem>[];

    for (final item in sortedItems) {
      if (currentSize <= _config.maxCacheSize) break;

      itemsToRemove.add(item);
      currentSize -= item.fileSize;
    }

    // Remove items
    for (final item in itemsToRemove) {
      final file = File(item.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Error deleting cache file: $e');
        }
      }
      _cacheIndex.remove(item.cacheKey);
    }

    if (itemsToRemove.isNotEmpty) {
      await _saveCacheIndex();
      debugPrint(
          'Removed ${itemsToRemove.length} cache items to enforce size limit');
    }
  }

  /// Cancel all ongoing downloads
  void cancelAllDownloads() {
    _downloadFutures.clear();
  }

  /// Get or create a video controller for a given reel ID
  dynamic getOrCreateVideoController(String reelId, String url) {
    if (_videoControllers.containsKey(reelId)) {
      _controllerAccessTimes[reelId] = DateTime.now();
      return _videoControllers[reelId];
    }

    // Before creating, evict if over limit
    if (_videoControllers.length >= _maxControllers) {
      _evictOldestController();
    }

    // Use cache file if available
    final filePath = getCachedFilePath(url);
    final controller = filePath != null
        ? _createControllerFromFile(filePath)
        : _createControllerFromUrl(url);

    // Initialize the controller immediately
    controller.initialize().then((_) {
      debugPrint('Video controller initialized for reel: $reelId');
    }).catchError((error) {
      debugPrint(
          'Error initializing video controller for reel $reelId: $error');
      _videoControllers.remove(reelId);
      _controllerAccessTimes.remove(reelId);
    });

    _videoControllers[reelId] = controller;
    _controllerAccessTimes[reelId] = DateTime.now();
    return controller;
  }

  /// Evict the oldest controller
  void _evictOldestController() {
    if (_videoControllers.isEmpty) return;

    final oldest = _controllerAccessTimes.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;

    _videoControllers[oldest]?.dispose();
    _videoControllers.remove(oldest);
    _controllerAccessTimes.remove(oldest);
  }

  /// Download and cache a video file
  Future<String?> _downloadAndCacheFile(String url) async {
    final cacheKey = _generateCacheKey(url);

    // Check if already downloading
    if (_downloadFutures.containsKey(cacheKey)) {
      return _downloadFutures[cacheKey];
    }

    // Check if already cached
    if (_cacheIndex.containsKey(cacheKey)) {
      final item = _cacheIndex[cacheKey]!;
      if (!item.isExpired) {
        return item.filePath;
      }
    }

    // Start download
    final downloadFuture = _downloadFile(url);
    _downloadFutures[cacheKey] = downloadFuture;

    try {
      final filePath = await downloadFuture;
      if (filePath != null) {
        final file = File(filePath);
        final fileSize = await file.length();
        final now = DateTime.now();
        await _addToCacheIndex(CacheItem(
          cacheKey: cacheKey,
          filePath: filePath,
          url: url,
          createdAt: now,
          fileSize: fileSize,
          lastAccessTime: now,
          expiryTime: now.add(const Duration(days: 7)),
        ));
      }
      return filePath;
    } finally {
      _downloadFutures.remove(cacheKey);
    }
  }

  /// Download a file to cache
  Future<String?> _downloadFile(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final fileName = _generateFileName(url);
        final file = File('${_cacheDirectory.path}/$fileName');
        await file.writeAsBytes(response.data);
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }

  /// Add to cache index and evict if over size
  Future<void> _addToCacheIndex(CacheItem cacheItem) async {
    _cacheIndex[cacheItem.cacheKey] = cacheItem;
    await _saveCacheIndex();
    await _evictIfOverCacheSize();
  }

  /// Evict least recently used files if over max cache size (parallel file checks)
  Future<void> _evictIfOverCacheSize() async {
    int totalSize =
        _cacheIndex.values.fold(0, (sum, item) => sum + item.fileSize);
    if (totalSize <= _maxCacheFileSize) return;
    // Sort by last access time (oldest first)
    final sorted = _cacheIndex.values.toList()
      ..sort((a, b) => a.lastAccessTime.compareTo(b.lastAccessTime));
    // Check file existence in parallel
    final futures = <Future>[];
    for (final item in sorted) {
      if (totalSize <= _maxCacheFileSize) break;
      futures.add(() async {
        final file = File(item.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        totalSize -= item.fileSize;
        _cacheIndex.remove(item.cacheKey);
        _memoryFileCache.remove(item.cacheKey);
      }());
    }
    await Future.wait(futures);
    await _saveCacheIndex();
  }

  void _addToMemoryCache(String cacheKey, String filePath) {
    _memoryFileCache[cacheKey] = filePath;
    if (_memoryFileCache.length > _maxMemoryFiles) {
      // Remove oldest
      final oldest = _memoryFileCache.keys.first;
      _memoryFileCache.remove(oldest);
    }
  }

  // Helper to create controller from file
  dynamic _createControllerFromFile(String filePath) {
    return VideoPlayerController.file(File(filePath));
  }

  // Helper to create controller from url
  dynamic _createControllerFromUrl(String url) {
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }

  /// Dispose the cache manager
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _controllerAccessTimes.clear();
    _downloadFutures.clear();
  }
}

/// Cache item data model
class CacheItem {
  final String cacheKey;
  final String filePath;
  final String url;
  final DateTime createdAt;
  final int fileSize;
  DateTime lastAccessTime; // Made non-final to allow updates
  final DateTime expiryTime;

  CacheItem({
    required this.cacheKey,
    required this.filePath,
    required this.url,
    required this.createdAt,
    required this.fileSize,
    required this.lastAccessTime,
    required this.expiryTime,
  });

  bool get isExpired => DateTime.now().isAfter(expiryTime);

  Map<String, dynamic> toJson() => {
        'cacheKey': cacheKey,
        'filePath': filePath,
        'url': url,
        'createdAt': createdAt.toIso8601String(),
        'fileSize': fileSize,
        'lastAccessTime': lastAccessTime.toIso8601String(),
        'expiryTime': expiryTime.toIso8601String(),
      };

  factory CacheItem.fromJson(Map<String, dynamic> json) => CacheItem(
        cacheKey: json['cacheKey'] as String,
        filePath: json['filePath'] as String,
        url: json['url'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        fileSize: json['fileSize'] as int,
        lastAccessTime: DateTime.parse(json['lastAccessTime'] as String),
        expiryTime: DateTime.parse(json['expiryTime'] as String),
      );
}

/// Cache statistics
class CacheStats {
  final int totalFiles;
  final int totalSize;
  final int expiredFiles;
  final String cacheDirectory;

  const CacheStats({
    required this.totalFiles,
    required this.totalSize,
    required this.expiredFiles,
    required this.cacheDirectory,
  });

  factory CacheStats.empty() {
    return const CacheStats(
      totalFiles: 0,
      totalSize: 0,
      expiredFiles: 0,
      cacheDirectory: '',
    );
  }

  /// Get human readable size
  String get humanReadableSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024)
      return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    if (totalSize < 1024 * 1024 * 1024)
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  String toString() {
    return 'CacheStats(files: $totalFiles, size: $humanReadableSize, expired: $expiredFiles)';
  }
}
