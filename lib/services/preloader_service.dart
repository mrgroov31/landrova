import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'optimized_api_service.dart';
import 'hive_api_service.dart';
import 'auth_service.dart';

class PreloaderService {
  static bool _isInitialized = false;
  static bool _isPreloading = false;

  // Initialize cache and preload critical data
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🚀 [PRELOADER] Initializing app performance optimizations...');
    final stopwatch = Stopwatch()..start();
    
    try {
      // Initialize Hive API service (includes cache service)
      await HiveApiService.init();
      debugPrint('✅ [PRELOADER] Hive API service initialized');
      
      // Initialize legacy cache service for backward compatibility
      await CacheService.init();
      debugPrint('✅ [PRELOADER] Legacy cache service initialized');
      
      // Start preloading critical data in background
      _preloadCriticalData();
      
      _isInitialized = true;
      debugPrint('✅ [PRELOADER] Initialization completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ [PRELOADER] Initialization failed: $e');
    }
  }

  // Preload critical data in background
  static void _preloadCriticalData() {
    if (_isPreloading) return;
    _isPreloading = true;
    
    debugPrint('🔄 [PRELOADER] Starting background data preload...');
    
    // Preload dashboard data
    _preloadDashboardData();
    
    // Preload service providers
    _preloadServiceProviders();
    
    _isPreloading = false;
  }

  // Preload dashboard data
  static Future<void> _preloadDashboardData() async {
    try {
      final ownerId = AuthService.getOwnerId();
      if (ownerId.isNotEmpty) {
        debugPrint('🔄 [PRELOADER] Preloading dashboard data with Hive...');
        
        // Use Hive API service for preloading
        HiveApiService.getDashboardData(ownerId).then((_) {
          debugPrint('✅ [PRELOADER] Dashboard data preloaded with Hive');
        }).catchError((e) {
          debugPrint('❌ [PRELOADER] Hive dashboard preload failed, trying optimized API: $e');
          // Fallback to optimized API
          return OptimizedApiService.loadDashboardDataOptimized(ownerId);
        }).then((_) {
          debugPrint('✅ [PRELOADER] Dashboard data preloaded with fallback');
        }).catchError((e) {
          debugPrint('❌ [PRELOADER] All dashboard preload methods failed: $e');
        });
      }
    } catch (e) {
      debugPrint('❌ [PRELOADER] Dashboard preload error: $e');
    }
  }

  // Preload service providers
  static Future<void> _preloadServiceProviders() async {
    try {
      debugPrint('🔄 [PRELOADER] Preloading service providers with Hive...');
      
      // Use Hive API service for preloading
      HiveApiService.getServiceProviders().then((_) {
        debugPrint('✅ [PRELOADER] Service providers preloaded with Hive');
      }).catchError((e) {
        debugPrint('❌ [PRELOADER] Hive service providers preload failed, trying optimized API: $e');
        // Fallback to optimized API
        return OptimizedApiService.loadServiceProvidersOptimized();
      }).then((_) {
        debugPrint('✅ [PRELOADER] Service providers preloaded with fallback');
      }).catchError((e) {
        debugPrint('❌ [PRELOADER] All service providers preload methods failed: $e');
      });
    } catch (e) {
      debugPrint('❌ [PRELOADER] Service providers preload error: $e');
    }
  }

  // Warm up cache with fresh data
  static Future<void> warmUpCache() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    debugPrint('🔥 [PRELOADER] Warming up Hive cache...');
    
    try {
      final ownerId = AuthService.getOwnerId();
      if (ownerId.isNotEmpty) {
        // Force refresh dashboard data in Hive
        await HiveApiService.getDashboardData(ownerId, forceRefresh: true);
        debugPrint('✅ [PRELOADER] Dashboard Hive cache warmed up');
      }
      
      // Force refresh service providers in Hive
      await HiveApiService.getServiceProviders(forceRefresh: true);
      debugPrint('✅ [PRELOADER] Service providers Hive cache warmed up');
      
    } catch (e) {
      debugPrint('❌ [PRELOADER] Hive cache warm up failed: $e');
    }
  }

  // Clear all cache and reinitialize
  static Future<void> resetCache() async {
    debugPrint('🗑️ [PRELOADER] Resetting all caches...');
    
    try {
      // Clear Hive cache
      await HiveApiService.clearAllCache();
      
      // Clear legacy cache
      await CacheService.clearAll();
      
      _isInitialized = false;
      await initialize();
      debugPrint('✅ [PRELOADER] All caches reset completed');
    } catch (e) {
      debugPrint('❌ [PRELOADER] Cache reset failed: $e');
    }
  }

  // Get performance metrics
  static Map<String, dynamic> getPerformanceMetrics() {
    return {
      'isInitialized': _isInitialized,
      'isPreloading': _isPreloading,
      'hiveStats': HiveApiService.getCacheStats(),
      'legacyCacheStats': CacheService.getCacheInfo(),
    };
  }

  // Cleanup resources
  static void dispose() {
    debugPrint('🧹 [PRELOADER] Cleaning up resources...');
    HiveApiService.dispose();
    CacheService.dispose();
    OptimizedApiService.dispose();
    _isInitialized = false;
    _isPreloading = false;
  }
}