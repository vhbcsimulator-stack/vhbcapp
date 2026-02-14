import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Custom cache manager for VHBC app images
/// 
/// Storage locations:
/// - Android: /data/data/com.vhbc.intelliapp/cache/vhbc_image_cache/
/// - iOS: Library/Caches/vhbc_image_cache/
/// - Web: Browser IndexedDB
/// - Desktop: System temp directory
class VHBCImageCacheManager {
  static const key = 'vhbc_image_cache';
  
  static CacheManager? _instance;
  
  /// Get singleton instance of cache manager
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        // Cache for 30 days
        stalePeriod: const Duration(days: 30),
        // Maximum 200 cached objects
        maxNrOfCacheObjects: 200,
        // Repository for custom storage location
        repo: JsonCacheInfoRepository(databaseName: key),
        // File service for downloading
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }
  
  /// Clear all cached images
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }
  
  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cachePath = path.join(cacheDir.path, key);
      final dir = Directory(cachePath);
      
      if (!await dir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  /// Format cache size for display
  static String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Remove specific image from cache
  static Future<void> removeFile(String url) async {
    await instance.removeFile(url);
  }
  
  /// Check if file is cached
  static Future<bool> isCached(String url) async {
    final fileInfo = await instance.getFileFromCache(url);
    return fileInfo != null;
  }
}

/// Cache manager for thumbnails (smaller cache size, longer retention)
class VHBCThumbnailCacheManager {
  static const key = 'vhbc_thumbnail_cache';
  
  static CacheManager? _instance;
  
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        // Cache thumbnails for 60 days (they're small)
        stalePeriod: const Duration(days: 60),
        // More thumbnails can be cached
        maxNrOfCacheObjects: 500,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }
}
