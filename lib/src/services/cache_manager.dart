import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/reel_config.dart';

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

  /// Initialize the cache manager
  Future<void> initialize(CacheConfig config) async {
    if (_isInitialized) return;
    
    _config = config;
    _dio = Dio();
    
    // Setup cache directory
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = config.cacheDirectoryName ?? 'awesome_reels_cache';
    _cacheDirectory = Directory('${appDir.path}/$cacheDir');
    
    if (!await _cacheDirectory.exists()) {
      await _cacheDirectory.create(recursive: true);
    }
    
    // Load existing cache index
    await _loadCacheIndex();
    
    // Cleanup expired cache
    await _cleanupExpiredCache();
    
    // Ensure cache size is within limits
    await _enforceCacheSize();
    
    _isInitialized = true;
  }

  /// Get cached file path for a URL
  Future<String?> getCachedFilePath(String url) async {
    if (!_isInitialized) return null;
    
    final cacheKey = _generateCacheKey(url);
    final cacheItem = _cacheIndex[cacheKey];
    
    if (cacheItem != null && await _isCacheValid(cacheItem)) {
      // Update access time
      cacheItem.lastAccessTime = DateTime.now();
      await _saveCacheIndex();
      return cacheItem.filePath;
    }
    
    return null;
  }

  /// Download and cache a file
  Future<String?> downloadAndCache(String url, {
    Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!_isInitialized) await initialize(_config);
    
    // Check if already cached
    final cachedPath = await getCachedFilePath(url);
    if (cachedPath != null) return cachedPath;
    
    // Check if download is already in progress
    if (_downloadFutures.containsKey(url)) {
      return await _downloadFutures[url];
    }
    
    // Start download
    final downloadFuture = _performDownload(url, onProgress: onProgress, cancelToken: cancelToken);
    _downloadFutures[url] = downloadFuture;
    
    try {
      final result = await downloadFuture;
      return result;
    } finally {
      _downloadFutures.remove(url);
    }
  }

  /// Perform the actual download
  Future<String?> _performDownload(String url, {
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
      
      // Add to cache index
      final cacheItem = CacheItem(
        url: url,
        filePath: filePath,
        cacheKey: cacheKey,
        fileSize: fileSize,
        downloadTime: DateTime.now(),
        lastAccessTime: DateTime.now(),
        expiryTime: DateTime.now().add(_config.cacheDuration),
      );
      
      _cacheIndex[cacheKey] = cacheItem;
      await _saveCacheIndex();
      
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
    final cachedPath = await getCachedFilePath(url);
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
    if (!_isInitialized) return;
    
    try {
      // Delete all cached files
      for (final item in _cacheIndex.values) {
        final file = File(item.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Clear index
      _cacheIndex.clear();
      await _saveCacheIndex();
      
      debugPrint('Cache cleared successfully');
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
    return url.hashCode.abs().toString();
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
      final indexFile = File('${_cacheDirectory.path}/cache_index.json');
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        final Map<String, dynamic> indexData = 
            Map<String, dynamic>.from(
              (await compute(_parseJson, content)) ?? {}
            );
        
        for (final entry in indexData.entries) {
          try {
            _cacheIndex[entry.key] = CacheItem.fromJson(entry.value);
          } catch (e) {
            debugPrint('Error parsing cache item: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cache index: $e');
    }
  }

  /// Save cache index to storage
  Future<void> _saveCacheIndex() async {
    try {
      final indexFile = File('${_cacheDirectory.path}/cache_index.json');
      final indexData = <String, dynamic>{};
      
      for (final entry in _cacheIndex.entries) {
        indexData[entry.key] = entry.value.toJson();
      }
      
      final jsonString = await compute(_jsonEncode, indexData);
      await indexFile.writeAsString(jsonString);
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
      debugPrint('Cleaned up ${expiredKeys.length} expired cache items');
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
      debugPrint('Removed ${itemsToRemove.length} cache items to enforce size limit');
    }
  }

  /// Cancel all ongoing downloads
  void cancelAllDownloads() {
    for (final future in _downloadFutures.values) {
      // Note: This is a simplified cancellation
      // In a real implementation, you'd want to store CancelTokens
    }
    _downloadFutures.clear();
  }
}

/// Cache item data model
class CacheItem {
  final String url;
  final String filePath;
  final String cacheKey;
  final int fileSize;
  final DateTime downloadTime;
  DateTime lastAccessTime;
  final DateTime expiryTime;

  CacheItem({
    required this.url,
    required this.filePath,
    required this.cacheKey,
    required this.fileSize,
    required this.downloadTime,
    required this.lastAccessTime,
    required this.expiryTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'filePath': filePath,
      'cacheKey': cacheKey,
      'fileSize': fileSize,
      'downloadTime': downloadTime.toIso8601String(),
      'lastAccessTime': lastAccessTime.toIso8601String(),
      'expiryTime': expiryTime.toIso8601String(),
    };
  }

  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem(
      url: json['url'],
      filePath: json['filePath'],
      cacheKey: json['cacheKey'],
      fileSize: json['fileSize'],
      downloadTime: DateTime.parse(json['downloadTime']),
      lastAccessTime: DateTime.parse(json['lastAccessTime']),
      expiryTime: DateTime.parse(json['expiryTime']),
    );
  }
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
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    if (totalSize < 1024 * 1024 * 1024) return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  String toString() {
    return 'CacheStats(files: $totalFiles, size: $humanReadableSize, expired: $expiredFiles)';
  }
}

// Helper functions for compute
Map<String, dynamic>? _parseJson(String jsonString) {
  try {
    final dynamic parsed = const JsonDecoder().convert(jsonString);
    return parsed is Map<String, dynamic> ? parsed : null;
  } catch (e) {
    return null;
  }
}

String _jsonEncode(Map<String, dynamic> data) {
  return const JsonEncoder().convert(data);
}
