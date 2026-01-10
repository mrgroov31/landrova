import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const Duration _longCacheDuration = Duration(hours: 1);
  
  // Cache keys
  static const String roomsKey = 'rooms';
  static const String tenantsKey = 'tenants';
  static const String complaintsKey = 'complaints';
  static const String paymentsKey = 'payments';
  static const String buildingsKey = 'buildings';
  static const String serviceProvidersKey = 'service_providers';
  static const String dashboardKey = 'dashboard';

  // Hive boxes
  static Box<dynamic>? _cacheBox;
  static Box<String>? _timestampBox;
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  static Future<void> init() async {
    try {
      // Open Hive boxes for caching
      _cacheBox = await Hive.openBox('api_cache');
      _timestampBox = await Hive.openBox<String>('cache_timestamps');
      
      debugPrint('✅ [HIVE CACHE] Initialized successfully');
      debugPrint('📦 [HIVE CACHE] Cache entries: ${_cacheBox?.length ?? 0}');
      debugPrint('⏰ [HIVE CACHE] Timestamp entries: ${_timestampBox?.length ?? 0}');
      
      // Load timestamps into memory for faster access
      _loadTimestampsToMemory();
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Initialization failed: $e');
    }
  }

  // Load timestamps into memory for faster validation
  static void _loadTimestampsToMemory() {
    try {
      final timestampBox = _timestampBox;
      if (timestampBox != null) {
        for (final key in timestampBox.keys) {
          final timestampStr = timestampBox.get(key);
          if (timestampStr != null) {
            _cacheTimestamps[key] = DateTime.parse(timestampStr);
          }
        }
        debugPrint('📥 [HIVE CACHE] Loaded ${_cacheTimestamps.length} timestamps to memory');
      }
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to load timestamps: $e');
    }
  }

  // Check if cache is valid
  static bool _isCacheValid(String key, Duration maxAge) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    final age = DateTime.now().difference(timestamp);
    final isValid = age < maxAge;
    
    if (!isValid) {
      debugPrint('⏰ [HIVE CACHE] Cache expired for $key (age: ${age.inMinutes}min, max: ${maxAge.inMinutes}min)');
    }
    
    return isValid;
  }

  // Get from memory cache first, then Hive cache
  static Future<T?> get<T>(String key, {Duration? maxAge}) async {
    await init();
    maxAge ??= _defaultCacheDuration;
    
    // Check memory cache first (fastest)
    if (_memoryCache.containsKey(key) && _isCacheValid(key, maxAge)) {
      debugPrint('⚡ [HIVE CACHE] Memory hit for $key');
      return _memoryCache[key] as T?;
    }

    // Check Hive cache
    try {
      final cacheBox = _cacheBox;
      if (cacheBox != null && cacheBox.containsKey(key)) {
        if (_isCacheValid(key, maxAge)) {
          final cachedData = cacheBox.get(key);
          if (cachedData != null) {
            // Update memory cache for faster subsequent access
            _memoryCache[key] = cachedData;
            debugPrint('📦 [HIVE CACHE] Hive hit for $key (age: ${DateTime.now().difference(_cacheTimestamps[key]!).inMinutes}min)');
            return cachedData as T?;
          }
        } else {
          // Remove expired cache
          await _removeExpiredCache(key);
        }
      }
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to get cached data for $key: $e');
    }

    debugPrint('❌ [HIVE CACHE] Miss for $key');
    return null;
  }

  // Set cache in both memory and Hive storage
  static Future<void> set<T>(String key, T data, {Duration? maxAge}) async {
    await init();
    
    try {
      final now = DateTime.now();
      
      // Update memory cache
      _memoryCache[key] = data;
      _cacheTimestamps[key] = now;
      
      // Update Hive cache
      final cacheBox = _cacheBox;
      final timestampBox = _timestampBox;
      
      if (cacheBox != null && timestampBox != null) {
        await cacheBox.put(key, data);
        await timestampBox.put(key, now.toIso8601String());
        
        debugPrint('✅ [HIVE CACHE] Stored $key (expires in ${(maxAge ?? _defaultCacheDuration).inMinutes}min)');
        debugPrint('📊 [HIVE CACHE] Total cache entries: ${cacheBox.length}');
      }
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to store $key: $e');
    }
  }

  // Remove expired cache entry
  static Future<void> _removeExpiredCache(String key) async {
    try {
      await _cacheBox?.delete(key);
      await _timestampBox?.delete(key);
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      debugPrint('🗑️ [HIVE CACHE] Removed expired cache for $key');
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to remove expired cache for $key: $e');
    }
  }

  // Clear specific cache
  static Future<void> clear(String key) async {
    await init();
    
    try {
      await _cacheBox?.delete(key);
      await _timestampBox?.delete(key);
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      
      debugPrint('🗑️ [HIVE CACHE] Cleared $key');
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to clear $key: $e');
    }
  }

  // Clear all cache
  static Future<void> clearAll() async {
    await init();
    
    try {
      await _cacheBox?.clear();
      await _timestampBox?.clear();
      _memoryCache.clear();
      _cacheTimestamps.clear();
      
      debugPrint('🗑️ [HIVE CACHE] Cleared all cache');
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to clear all cache: $e');
    }
  }

  // Preload cache with data
  static Future<void> preload(String key, Future<dynamic> Function() dataLoader, {Duration? maxAge}) async {
    final cached = await get(key, maxAge: maxAge);
    if (cached == null) {
      try {
        debugPrint('🔄 [HIVE CACHE] Preloading $key...');
        final data = await dataLoader();
        await set(key, data, maxAge: maxAge);
        debugPrint('✅ [HIVE CACHE] Preloaded $key');
      } catch (e) {
        debugPrint('❌ [HIVE CACHE] Failed to preload $key: $e');
      }
    } else {
      debugPrint('📦 [HIVE CACHE] $key already cached, skipping preload');
    }
  }

  // Get cache info for debugging
  static Map<String, dynamic> getCacheInfo() {
    return {
      'memoryCache': _memoryCache.keys.toList(),
      'memoryCacheSize': _memoryCache.length,
      'hiveCacheSize': _cacheBox?.length ?? 0,
      'timestampCacheSize': _timestampBox?.length ?? 0,
      'timestamps': _cacheTimestamps.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }

  // Clean up expired entries
  static Future<void> cleanupExpiredEntries() async {
    await init();
    
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      // Find expired entries
      for (final entry in _cacheTimestamps.entries) {
        if (now.difference(entry.value) > _longCacheDuration) {
          expiredKeys.add(entry.key);
        }
      }
      
      // Remove expired entries
      for (final key in expiredKeys) {
        await _removeExpiredCache(key);
      }
      
      if (expiredKeys.isNotEmpty) {
        debugPrint('🧹 [HIVE CACHE] Cleaned up ${expiredKeys.length} expired entries');
      }
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to cleanup expired entries: $e');
    }
  }

  // Invalidate cache when data changes
  static Future<void> invalidateRelated(String key) async {
    switch (key) {
      case roomsKey:
        await clear(dashboardKey);
        break;
      case tenantsKey:
        await clear(dashboardKey);
        break;
      case complaintsKey:
        await clear(dashboardKey);
        break;
      case paymentsKey:
        await clear(dashboardKey);
        break;
      case buildingsKey:
        await clear(dashboardKey);
        await clear(roomsKey);
        break;
    }
  }

  // Get cache size in bytes (approximate)
  static Future<int> getCacheSize() async {
    try {
      final cacheBox = _cacheBox;
      if (cacheBox == null) return 0;
      
      int totalSize = 0;
      for (final key in cacheBox.keys) {
        final value = cacheBox.get(key);
        if (value != null) {
          // Approximate size calculation
          totalSize += key.toString().length * 2; // Key size
          totalSize += json.encode(value).length * 2; // Value size (UTF-16)
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to calculate cache size: $e');
      return 0;
    }
  }

  // Compact Hive boxes for better performance
  static Future<void> compactCache() async {
    try {
      await _cacheBox?.compact();
      await _timestampBox?.compact();
      debugPrint('🗜️ [HIVE CACHE] Cache compacted successfully');
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to compact cache: $e');
    }
  }

  // Close Hive boxes (call on app dispose)
  static Future<void> dispose() async {
    try {
      await _cacheBox?.close();
      await _timestampBox?.close();
      _memoryCache.clear();
      _cacheTimestamps.clear();
      debugPrint('🔒 [HIVE CACHE] Disposed successfully');
    } catch (e) {
      debugPrint('❌ [HIVE CACHE] Failed to dispose: $e');
    }
  }
}