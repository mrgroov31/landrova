import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/api_tenant.dart';
import '../models/complaint.dart';
import '../models/payment.dart';
import '../models/building.dart';
import '../models/service_provider.dart';
import 'cache_service.dart';
import 'api_service.dart';
import 'auth_service.dart';

class OptimizedApiService {
  static const Duration _shortCache = Duration(minutes: 2);
  static const Duration _mediumCache = Duration(minutes: 5);
  static const Duration _longCache = Duration(minutes: 15);
  
  // Connection pool for HTTP requests
  static final http.Client _httpClient = http.Client();
  
  // Request deduplication
  static final Map<String, Future<dynamic>> _ongoingRequests = {};

  // Batch load dashboard data with parallel requests and caching
  static Future<Map<String, dynamic>> loadDashboardDataOptimized(String ownerId) async {
    debugPrint('🚀 [OPTIMIZED] Loading dashboard data for owner: $ownerId');
    final stopwatch = Stopwatch()..start();

    try {
      // Try to get cached dashboard data first
      final cachedDashboard = await CacheService.get<Map<String, dynamic>>(
        CacheService.dashboardKey, 
        maxAge: _shortCache,
      );
      
      if (cachedDashboard != null) {
        debugPrint('⚡ [OPTIMIZED] Dashboard cache hit! Loaded in ${stopwatch.elapsedMilliseconds}ms');
        return cachedDashboard;
      }

      // Load all data in parallel with individual caching
      final futures = await Future.wait([
        _loadRoomsOptimized(ownerId),
        _loadTenantsOptimized(ownerId),
        _loadComplaintsOptimized(ownerId),
        _loadPaymentsOptimized(),
        _loadBuildingsOptimized(ownerId),
      ]);

      final dashboardData = {
        'rooms': futures[0],
        'tenants': futures[1], 
        'complaints': futures[2],
        'payments': futures[3],
        'buildings': futures[4],
        'loadedAt': DateTime.now().toIso8601String(),
      };

      // Cache the combined dashboard data
      await CacheService.set(CacheService.dashboardKey, dashboardData, maxAge: _shortCache);
      
      debugPrint('✅ [OPTIMIZED] Dashboard loaded in ${stopwatch.elapsedMilliseconds}ms');
      return dashboardData;
      
    } catch (e) {
      debugPrint('❌ [OPTIMIZED] Dashboard load failed in ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  // Optimized rooms loading with caching and deduplication
  static Future<List<Room>> _loadRoomsOptimized(String ownerId) async {
    final cacheKey = '${CacheService.roomsKey}_$ownerId';
    
    // Check cache first
    final cached = await CacheService.get<List<dynamic>>(cacheKey, maxAge: _mediumCache);
    if (cached != null) {
      debugPrint('📦 [OPTIMIZED] Rooms cache hit');
      return cached.map((json) => Room.fromJson(json)).toList();
    }

    // Deduplicate requests
    final requestKey = 'rooms_$ownerId';
    if (_ongoingRequests.containsKey(requestKey)) {
      debugPrint('🔄 [OPTIMIZED] Deduplicating rooms request');
      final result = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      return ApiService.parseRooms(result);
    }

    // Make API request
    _ongoingRequests[requestKey] = ApiService.fetchRoomsByOwnerId(ownerId);
    
    try {
      final response = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      final rooms = ApiService.parseRooms(response);
      
      // Cache the raw JSON for faster parsing
      final roomsJson = rooms.map((room) => room.toJson()).toList();
      await CacheService.set(cacheKey, roomsJson, maxAge: _mediumCache);
      
      return rooms;
    } finally {
      _ongoingRequests.remove(requestKey);
    }
  }

  // Optimized tenants loading
  static Future<List<Tenant>> _loadTenantsOptimized(String ownerId) async {
    final cacheKey = '${CacheService.tenantsKey}_$ownerId';
    
    final cached = await CacheService.get<List<dynamic>>(cacheKey, maxAge: _mediumCache);
    if (cached != null) {
      debugPrint('📦 [OPTIMIZED] Tenants cache hit');
      return cached.map((json) => Tenant.fromJson(json)).toList();
    }

    final requestKey = 'tenants_$ownerId';
    if (_ongoingRequests.containsKey(requestKey)) {
      final result = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      return ApiService.parseTenants(result);
    }

    _ongoingRequests[requestKey] = ApiService.fetchTenants();
    
    try {
      final response = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      final tenants = ApiService.parseTenants(response);
      
      final tenantsJson = tenants.map((tenant) => tenant.toJson()).toList();
      await CacheService.set(cacheKey, tenantsJson, maxAge: _mediumCache);
      
      return tenants;
    } finally {
      _ongoingRequests.remove(requestKey);
    }
  }

  // Optimized complaints loading
  static Future<List<Complaint>> _loadComplaintsOptimized(String ownerId) async {
    final cacheKey = '${CacheService.complaintsKey}_$ownerId';
    
    final cached = await CacheService.get<List<dynamic>>(cacheKey, maxAge: _shortCache);
    if (cached != null) {
      debugPrint('📦 [OPTIMIZED] Complaints cache hit');
      return cached.map((json) => Complaint.fromJson(json)).toList();
    }

    final requestKey = 'complaints_$ownerId';
    if (_ongoingRequests.containsKey(requestKey)) {
      final result = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      return ApiService.parseApiComplaints(result);
    }

    _ongoingRequests[requestKey] = ApiService.fetchComplaintsByOwnerId(ownerId);
    
    try {
      final response = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      final complaints = ApiService.parseApiComplaints(response);
      
      final complaintsJson = complaints.map((complaint) => complaint.toJson()).toList();
      await CacheService.set(cacheKey, complaintsJson, maxAge: _shortCache);
      
      return complaints;
    } finally {
      _ongoingRequests.remove(requestKey);
    }
  }

  // Optimized payments loading
  static Future<List<Payment>> _loadPaymentsOptimized() async {
    final cacheKey = CacheService.paymentsKey;
    
    final cached = await CacheService.get<List<dynamic>>(cacheKey, maxAge: _mediumCache);
    if (cached != null) {
      debugPrint('📦 [OPTIMIZED] Payments cache hit');
      return cached.map((json) => Payment.fromJson(json)).toList();
    }

    const requestKey = 'payments';
    if (_ongoingRequests.containsKey(requestKey)) {
      final result = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      return ApiService.parsePayments(result);
    }

    _ongoingRequests[requestKey] = ApiService.fetchPayments();
    
    try {
      final response = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      final payments = ApiService.parsePayments(response);
      
      final paymentsJson = payments.map((payment) => payment.toJson()).toList();
      await CacheService.set(cacheKey, paymentsJson, maxAge: _mediumCache);
      
      return payments;
    } finally {
      _ongoingRequests.remove(requestKey);
    }
  }

  // Optimized buildings loading
  static Future<List<Building>> _loadBuildingsOptimized(String ownerId) async {
    final cacheKey = '${CacheService.buildingsKey}_$ownerId';
    
    final cached = await CacheService.get<List<dynamic>>(cacheKey, maxAge: _longCache);
    if (cached != null) {
      debugPrint('📦 [OPTIMIZED] Buildings cache hit');
      return cached.map((json) => Building.fromJson(json)).toList();
    }

    final requestKey = 'buildings_$ownerId';
    if (_ongoingRequests.containsKey(requestKey)) {
      final result = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      return ApiService.parseBuildings(result);
    }

    _ongoingRequests[requestKey] = ApiService.fetchBuildingsByOwnerId(ownerId);
    
    try {
      final response = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      final buildings = ApiService.parseBuildings(response);
      
      final buildingsJson = buildings.map((building) => building.toJson()).toList();
      await CacheService.set(cacheKey, buildingsJson, maxAge: _longCache);
      
      return buildings;
    } finally {
      _ongoingRequests.remove(requestKey);
    }
  }

  // Optimized service providers loading with smart caching
  static Future<List<ServiceProvider>> loadServiceProvidersOptimized({
    String? serviceType,
    bool forceRefresh = false,
  }) async {
    final cacheKey = serviceType != null 
        ? '${CacheService.serviceProvidersKey}_$serviceType'
        : CacheService.serviceProvidersKey;
    
    if (!forceRefresh) {
      final cached = await CacheService.get<List<dynamic>>(cacheKey, maxAge: _mediumCache);
      if (cached != null) {
        debugPrint('📦 [OPTIMIZED] Service providers cache hit');
        return cached.map((json) => ServiceProvider.fromJson(json)).toList();
      }
    }

    final requestKey = 'service_providers_${serviceType ?? 'all'}';
    if (_ongoingRequests.containsKey(requestKey)) {
      final result = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      return ApiService.parseServiceProviders(result);
    }

    _ongoingRequests[requestKey] = ApiService.fetchServiceProviders(
      serviceType: serviceType,
      verified: true,
      sortBy: 'rating',
      sortOrder: 'desc',
      limit: 50,
    );
    
    try {
      final response = await _ongoingRequests[requestKey] as Map<String, dynamic>;
      final providers = ApiService.parseServiceProviders(response);
      
      final providersJson = providers.map((provider) => provider.toJson()).toList();
      await CacheService.set(cacheKey, providersJson, maxAge: _mediumCache);
      
      return providers;
    } catch (e) {
      debugPrint('❌ [OPTIMIZED] Service providers API failed, returning empty list: $e');
      return [];
    } finally {
      _ongoingRequests.remove(requestKey);
    }
  }

  // Preload data in background
  static Future<void> preloadDashboardData() async {
    try {
      final ownerId = AuthService.getOwnerId();
      debugPrint('🔄 [OPTIMIZED] Preloading dashboard data...');
      
      // Preload in background without waiting
      unawaited(loadDashboardDataOptimized(ownerId));
      unawaited(loadServiceProvidersOptimized());
      
    } catch (e) {
      debugPrint('❌ [OPTIMIZED] Preload failed: $e');
    }
  }

  // Invalidate cache when data changes
  static Future<void> invalidateCache(String dataType, [String? ownerId]) async {
    switch (dataType) {
      case 'rooms':
        await CacheService.clear('${CacheService.roomsKey}_${ownerId ?? AuthService.getOwnerId()}');
        await CacheService.clear(CacheService.dashboardKey);
        break;
      case 'tenants':
        await CacheService.clear('${CacheService.tenantsKey}_${ownerId ?? AuthService.getOwnerId()}');
        await CacheService.clear(CacheService.dashboardKey);
        break;
      case 'complaints':
        await CacheService.clear('${CacheService.complaintsKey}_${ownerId ?? AuthService.getOwnerId()}');
        await CacheService.clear(CacheService.dashboardKey);
        break;
      case 'payments':
        await CacheService.clear(CacheService.paymentsKey);
        await CacheService.clear(CacheService.dashboardKey);
        break;
      case 'buildings':
        await CacheService.clear('${CacheService.buildingsKey}_${ownerId ?? AuthService.getOwnerId()}');
        await CacheService.clear(CacheService.dashboardKey);
        break;
      case 'service_providers':
        final keys = (await CacheService.getCacheInfo())['memoryCache'] as List<String>;
        for (final key in keys) {
          if (key.startsWith(CacheService.serviceProvidersKey)) {
            await CacheService.clear(key);
          }
        }
        break;
      case 'dashboard':
        await CacheService.clear(CacheService.dashboardKey);
        break;
    }
  }

  // Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'ongoingRequests': _ongoingRequests.keys.toList(),
      'cacheInfo': CacheService.getCacheInfo(),
    };
  }

  // Cleanup resources
  static void dispose() {
    _httpClient.close();
    _ongoingRequests.clear();
  }
}

// Helper to fire and forget futures
void unawaited(Future<void> future) {
  future.catchError((error) {
    debugPrint('❌ [OPTIMIZED] Unawaited future failed: $error');
  });
}