import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/api_tenant.dart';
import '../models/complaint.dart';
import '../models/payment.dart';
import '../models/building.dart';
import '../models/service_provider.dart';
import 'api_service.dart';
import 'auth_service.dart';

class HiveApiService {
  // Cache durations optimized for different data types
  static const Duration _roomsCache = Duration(minutes: 15); // Rarely change
  static const Duration _buildingsCache = Duration(hours: 1); // Very stable
  static const Duration _tenantsCache = Duration(minutes: 10); // Moderate changes
  static const Duration _complaintsCache = Duration(minutes: 2); // Frequently updated
  static const Duration _paymentsCache = Duration(minutes: 5); // Regular updates
  static const Duration _serviceProvidersCache = Duration(minutes: 10); // Moderate changes
  static const Duration _dashboardCache = Duration(minutes: 3); // Aggregated data
  
  // Hive boxes for different data types
  static Box<dynamic>? _roomsBox;
  static Box<dynamic>? _tenantsBox;
  static Box<dynamic>? _complaintsBox;
  static Box<dynamic>? _paymentsBox;
  static Box<dynamic>? _buildingsBox;
  static Box<dynamic>? _serviceProvidersBox;
  static Box<dynamic>? _dashboardBox;
  static Box<String>? _timestampsBox;
  
  // Memory cache for ultra-fast access
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Request deduplication
  static final Map<String, Future<dynamic>> _ongoingRequests = {};
  
  // HTTP client with connection pooling
  static final http.Client _httpClient = http.Client();

  static Future<void> init() async {
    try {
      debugPrint('🚀 [HIVE API] Initializing Hive API service...');
      final stopwatch = Stopwatch()..start();
      
      // Open specialized Hive boxes for each data type
      final futures = await Future.wait([
        Hive.openBox('api_rooms'),
        Hive.openBox('api_tenants'),
        Hive.openBox('api_complaints'),
        Hive.openBox('api_payments'),
        Hive.openBox('api_buildings'),
        Hive.openBox('api_service_providers'),
        Hive.openBox('api_dashboard'),
        Hive.openBox<String>('api_timestamps'),
      ]);
      
      _roomsBox = futures[0];
      _tenantsBox = futures[1];
      _complaintsBox = futures[2];
      _paymentsBox = futures[3];
      _buildingsBox = futures[4];
      _serviceProvidersBox = futures[5];
      _dashboardBox = futures[6];
      _timestampsBox = futures[7] as Box<String>;
      
      // Load timestamps into memory for faster validation
      _loadTimestampsToMemory();
      
      debugPrint('✅ [HIVE API] Initialized in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 [HIVE API] Cache stats:');
      debugPrint('   - Rooms: ${_roomsBox?.length ?? 0} entries');
      debugPrint('   - Tenants: ${_tenantsBox?.length ?? 0} entries');
      debugPrint('   - Complaints: ${_complaintsBox?.length ?? 0} entries');
      debugPrint('   - Payments: ${_paymentsBox?.length ?? 0} entries');
      debugPrint('   - Buildings: ${_buildingsBox?.length ?? 0} entries');
      debugPrint('   - Service Providers: ${_serviceProvidersBox?.length ?? 0} entries');
      debugPrint('   - Dashboard: ${_dashboardBox?.length ?? 0} entries');
      
    } catch (e) {
      debugPrint('❌ [HIVE API] Initialization failed: $e');
    }
  }

  static void _loadTimestampsToMemory() {
    try {
      final timestampsBox = _timestampsBox;
      if (timestampsBox != null) {
        for (final key in timestampsBox.keys) {
          final timestampStr = timestampsBox.get(key);
          if (timestampStr != null) {
            _cacheTimestamps[key] = DateTime.parse(timestampStr);
          }
        }
        debugPrint('📥 [HIVE API] Loaded ${_cacheTimestamps.length} timestamps to memory');
      }
    } catch (e) {
      debugPrint('❌ [HIVE API] Failed to load timestamps: $e');
    }
  }

  static bool _isCacheValid(String key, Duration maxAge) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    final age = DateTime.now().difference(timestamp);
    return age < maxAge;
  }

  static Future<void> _updateTimestamp(String key) async {
    final now = DateTime.now();
    _cacheTimestamps[key] = now;
    await _timestampsBox?.put(key, now.toIso8601String());
  }

  // ===== ROOMS API WITH HIVE CACHING =====
  
  static Future<List<Room>> getRooms(String ownerId, {bool forceRefresh = false}) async {
    await init();
    final cacheKey = 'rooms_$ownerId';
    
    // Check memory cache first
    if (!forceRefresh && _memoryCache.containsKey(cacheKey) && _isCacheValid(cacheKey, _roomsCache)) {
      debugPrint('⚡ [HIVE API] Rooms memory hit for owner: $ownerId');
      return (_memoryCache[cacheKey] as List).map((json) => Room.fromJson(json)).toList();
    }
    
    // Check Hive cache
    if (!forceRefresh && _roomsBox?.containsKey(cacheKey) == true && _isCacheValid(cacheKey, _roomsCache)) {
      final cachedData = _roomsBox!.get(cacheKey) as List<dynamic>;
      final rooms = cachedData.map((json) => Room.fromJson(json)).toList();
      
      // Update memory cache
      _memoryCache[cacheKey] = cachedData;
      
      debugPrint('📦 [HIVE API] Rooms Hive hit for owner: $ownerId (${rooms.length} rooms)');
      return rooms;
    }
    
    // Deduplicate API requests
    if (_ongoingRequests.containsKey(cacheKey)) {
      debugPrint('🔄 [HIVE API] Deduplicating rooms request for owner: $ownerId');
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      return ApiService.parseRooms(response);
    }
    
    // Make API request
    debugPrint('🌐 [HIVE API] Fetching rooms from API for owner: $ownerId');
    _ongoingRequests[cacheKey] = ApiService.fetchRoomsByOwnerId(ownerId);
    
    try {
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      final rooms = ApiService.parseRooms(response);
      
      // Cache in Hive and memory
      final roomsJson = rooms.map((room) => room.toJson()).toList();
      await _roomsBox?.put(cacheKey, roomsJson);
      await _updateTimestamp(cacheKey);
      _memoryCache[cacheKey] = roomsJson;
      
      debugPrint('✅ [HIVE API] Cached ${rooms.length} rooms for owner: $ownerId');
      return rooms;
      
    } finally {
      _ongoingRequests.remove(cacheKey);
    }
  }

  // ===== TENANTS API WITH HIVE CACHING =====
  
  static Future<List<Tenant>> getTenants({bool forceRefresh = false}) async {
    await init();
    const cacheKey = 'tenants_all';
    
    // Check memory cache first
    if (!forceRefresh && _memoryCache.containsKey(cacheKey) && _isCacheValid(cacheKey, _tenantsCache)) {
      debugPrint('⚡ [HIVE API] Tenants memory hit');
      return (_memoryCache[cacheKey] as List).map((json) => Tenant.fromJson(json)).toList();
    }
    
    // Check Hive cache
    if (!forceRefresh && _tenantsBox?.containsKey(cacheKey) == true && _isCacheValid(cacheKey, _tenantsCache)) {
      final cachedData = _tenantsBox!.get(cacheKey) as List<dynamic>;
      final tenants = cachedData.map((json) => Tenant.fromJson(json)).toList();
      
      // Update memory cache
      _memoryCache[cacheKey] = cachedData;
      
      debugPrint('📦 [HIVE API] Tenants Hive hit (${tenants.length} tenants)');
      return tenants;
    }
    
    // Deduplicate API requests
    if (_ongoingRequests.containsKey(cacheKey)) {
      debugPrint('🔄 [HIVE API] Deduplicating tenants request');
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      return ApiService.parseTenants(response);
    }
    
    // Make API request
    debugPrint('🌐 [HIVE API] Fetching tenants from API');
    _ongoingRequests[cacheKey] = ApiService.fetchTenants();
    
    try {
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      final tenants = ApiService.parseTenants(response);
      
      // Cache in Hive and memory
      final tenantsJson = tenants.map((tenant) => tenant.toJson()).toList();
      await _tenantsBox?.put(cacheKey, tenantsJson);
      await _updateTimestamp(cacheKey);
      _memoryCache[cacheKey] = tenantsJson;
      
      debugPrint('✅ [HIVE API] Cached ${tenants.length} tenants');
      return tenants;
      
    } finally {
      _ongoingRequests.remove(cacheKey);
    }
  }

  // ===== COMPLAINTS API WITH HIVE CACHING =====
  
  static Future<List<Complaint>> getComplaints(String ownerId, {bool forceRefresh = false}) async {
    await init();
    final cacheKey = 'complaints_$ownerId';
    
    // Check memory cache first
    if (!forceRefresh && _memoryCache.containsKey(cacheKey) && _isCacheValid(cacheKey, _complaintsCache)) {
      debugPrint('⚡ [HIVE API] Complaints memory hit for owner: $ownerId');
      return (_memoryCache[cacheKey] as List).map((json) => Complaint.fromJson(json)).toList();
    }
    
    // Check Hive cache
    if (!forceRefresh && _complaintsBox?.containsKey(cacheKey) == true && _isCacheValid(cacheKey, _complaintsCache)) {
      final cachedData = _complaintsBox!.get(cacheKey) as List<dynamic>;
      final complaints = cachedData.map((json) => Complaint.fromJson(json)).toList();
      
      // Update memory cache
      _memoryCache[cacheKey] = cachedData;
      
      debugPrint('📦 [HIVE API] Complaints Hive hit for owner: $ownerId (${complaints.length} complaints)');
      return complaints;
    }
    
    // Deduplicate API requests
    if (_ongoingRequests.containsKey(cacheKey)) {
      debugPrint('🔄 [HIVE API] Deduplicating complaints request for owner: $ownerId');
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      return ApiService.parseApiComplaints(response);
    }
    
    // Make API request
    debugPrint('🌐 [HIVE API] Fetching complaints from API for owner: $ownerId');
    _ongoingRequests[cacheKey] = ApiService.fetchComplaintsByOwnerId(ownerId);
    
    try {
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      final complaints = ApiService.parseApiComplaints(response);
      
      // Cache in Hive and memory
      final complaintsJson = complaints.map((complaint) => complaint.toJson()).toList();
      await _complaintsBox?.put(cacheKey, complaintsJson);
      await _updateTimestamp(cacheKey);
      _memoryCache[cacheKey] = complaintsJson;
      
      debugPrint('✅ [HIVE API] Cached ${complaints.length} complaints for owner: $ownerId');
      return complaints;
      
    } finally {
      _ongoingRequests.remove(cacheKey);
    }
  }

  // ===== PAYMENTS API WITH HIVE CACHING =====
  
  static Future<List<Payment>> getPayments({bool forceRefresh = false}) async {
    await init();
    const cacheKey = 'payments_all';
    
    // Check memory cache first
    if (!forceRefresh && _memoryCache.containsKey(cacheKey) && _isCacheValid(cacheKey, _paymentsCache)) {
      debugPrint('⚡ [HIVE API] Payments memory hit');
      return (_memoryCache[cacheKey] as List).map((json) => Payment.fromJson(json)).toList();
    }
    
    // Check Hive cache
    if (!forceRefresh && _paymentsBox?.containsKey(cacheKey) == true && _isCacheValid(cacheKey, _paymentsCache)) {
      final cachedData = _paymentsBox!.get(cacheKey) as List<dynamic>;
      final payments = cachedData.map((json) => Payment.fromJson(json)).toList();
      
      // Update memory cache
      _memoryCache[cacheKey] = cachedData;
      
      debugPrint('📦 [HIVE API] Payments Hive hit (${payments.length} payments)');
      return payments;
    }
    
    // Deduplicate API requests
    if (_ongoingRequests.containsKey(cacheKey)) {
      debugPrint('🔄 [HIVE API] Deduplicating payments request');
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      return ApiService.parsePayments(response);
    }
    
    // Make API request
    debugPrint('🌐 [HIVE API] Fetching payments from API');
    _ongoingRequests[cacheKey] = ApiService.fetchPayments();
    
    try {
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      final payments = ApiService.parsePayments(response);
      
      // Cache in Hive and memory
      final paymentsJson = payments.map((payment) => payment.toJson()).toList();
      await _paymentsBox?.put(cacheKey, paymentsJson);
      await _updateTimestamp(cacheKey);
      _memoryCache[cacheKey] = paymentsJson;
      
      debugPrint('✅ [HIVE API] Cached ${payments.length} payments');
      return payments;
      
    } finally {
      _ongoingRequests.remove(cacheKey);
    }
  }

  // ===== BUILDINGS API WITH HIVE CACHING =====
  
  static Future<List<Building>> getBuildings(String ownerId, {bool forceRefresh = false}) async {
    await init();
    final cacheKey = 'buildings_$ownerId';
    
    // Check memory cache first
    if (!forceRefresh && _memoryCache.containsKey(cacheKey) && _isCacheValid(cacheKey, _buildingsCache)) {
      debugPrint('⚡ [HIVE API] Buildings memory hit for owner: $ownerId');
      return (_memoryCache[cacheKey] as List).map((json) => Building.fromJson(json)).toList();
    }
    
    // Check Hive cache
    if (!forceRefresh && _buildingsBox?.containsKey(cacheKey) == true && _isCacheValid(cacheKey, _buildingsCache)) {
      final cachedData = _buildingsBox!.get(cacheKey) as List<dynamic>;
      final buildings = cachedData.map((json) => Building.fromJson(json)).toList();
      
      // Update memory cache
      _memoryCache[cacheKey] = cachedData;
      
      debugPrint('📦 [HIVE API] Buildings Hive hit for owner: $ownerId (${buildings.length} buildings)');
      return buildings;
    }
    
    // Deduplicate API requests
    if (_ongoingRequests.containsKey(cacheKey)) {
      debugPrint('🔄 [HIVE API] Deduplicating buildings request for owner: $ownerId');
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      return ApiService.parseBuildings(response);
    }
    
    // Make API request
    debugPrint('🌐 [HIVE API] Fetching buildings from API for owner: $ownerId');
    _ongoingRequests[cacheKey] = ApiService.fetchBuildingsByOwnerId(ownerId);
    
    try {
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      final buildings = ApiService.parseBuildings(response);
      
      // Cache in Hive and memory
      final buildingsJson = buildings.map((building) => building.toJson()).toList();
      await _buildingsBox?.put(cacheKey, buildingsJson);
      await _updateTimestamp(cacheKey);
      _memoryCache[cacheKey] = buildingsJson;
      
      debugPrint('✅ [HIVE API] Cached ${buildings.length} buildings for owner: $ownerId');
      return buildings;
      
    } finally {
      _ongoingRequests.remove(cacheKey);
    }
  }

  // ===== SERVICE PROVIDERS API WITH HIVE CACHING =====
  
  static Future<List<ServiceProvider>> getServiceProviders({
    String? serviceType,
    bool forceRefresh = false,
  }) async {
    await init();
    final cacheKey = serviceType != null ? 'service_providers_$serviceType' : 'service_providers_all';
    
    // Check memory cache first
    if (!forceRefresh && _memoryCache.containsKey(cacheKey) && _isCacheValid(cacheKey, _serviceProvidersCache)) {
      debugPrint('⚡ [HIVE API] Service providers memory hit for type: ${serviceType ?? 'all'}');
      return (_memoryCache[cacheKey] as List).map((json) => ServiceProvider.fromJson(json)).toList();
    }
    
    // Check Hive cache
    if (!forceRefresh && _serviceProvidersBox?.containsKey(cacheKey) == true && _isCacheValid(cacheKey, _serviceProvidersCache)) {
      final cachedData = _serviceProvidersBox!.get(cacheKey) as List<dynamic>;
      final providers = cachedData.map((json) => ServiceProvider.fromJson(json)).toList();
      
      // Update memory cache
      _memoryCache[cacheKey] = cachedData;
      
      debugPrint('📦 [HIVE API] Service providers Hive hit for type: ${serviceType ?? 'all'} (${providers.length} providers)');
      return providers;
    }
    
    // Deduplicate API requests
    if (_ongoingRequests.containsKey(cacheKey)) {
      debugPrint('🔄 [HIVE API] Deduplicating service providers request for type: ${serviceType ?? 'all'}');
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      return ApiService.parseServiceProviders(response);
    }
    
    // Make API request
    debugPrint('🌐 [HIVE API] Fetching service providers from API for type: ${serviceType ?? 'all'}');
    _ongoingRequests[cacheKey] = ApiService.fetchServiceProviders(
      serviceType: serviceType,
      verified: true,
      sortBy: 'rating',
      sortOrder: 'desc',
      limit: 50,
    );
    
    try {
      final response = await _ongoingRequests[cacheKey] as Map<String, dynamic>;
      final providers = ApiService.parseServiceProviders(response);
      
      // Cache in Hive and memory
      final providersJson = providers.map((provider) => provider.toJson()).toList();
      await _serviceProvidersBox?.put(cacheKey, providersJson);
      await _updateTimestamp(cacheKey);
      _memoryCache[cacheKey] = providersJson;
      
      debugPrint('✅ [HIVE API] Cached ${providers.length} service providers for type: ${serviceType ?? 'all'}');
      return providers;
      
    } catch (e) {
      debugPrint('❌ [HIVE API] Service providers API failed: $e');
      return [];
    } finally {
      _ongoingRequests.remove(cacheKey);
    }
  }

  // ===== DASHBOARD DATA WITH HIVE CACHING =====
  
  static Future<Map<String, dynamic>> getDashboardData(String ownerId, {bool forceRefresh = false}) async {
    await init();
    final cacheKey = 'dashboard_$ownerId';
    
    debugPrint('🚀 [HIVE API] Loading dashboard data for owner: $ownerId');
    final stopwatch = Stopwatch()..start();
    
    // Check memory cache first
    if (!forceRefresh && _memoryCache.containsKey(cacheKey) && _isCacheValid(cacheKey, _dashboardCache)) {
      debugPrint('⚡ [HIVE API] Dashboard memory hit! Loaded in ${stopwatch.elapsedMilliseconds}ms');
      return _memoryCache[cacheKey] as Map<String, dynamic>;
    }
    
    // Check Hive cache
    if (!forceRefresh && _dashboardBox?.containsKey(cacheKey) == true && _isCacheValid(cacheKey, _dashboardCache)) {
      final cachedData = _dashboardBox!.get(cacheKey) as Map<String, dynamic>;
      
      // Update memory cache
      _memoryCache[cacheKey] = cachedData;
      
      debugPrint('📦 [HIVE API] Dashboard Hive hit! Loaded in ${stopwatch.elapsedMilliseconds}ms');
      return cachedData;
    }
    
    // Load all data in parallel
    debugPrint('🌐 [HIVE API] Loading dashboard data from APIs...');
    final futures = await Future.wait([
      getRooms(ownerId, forceRefresh: forceRefresh),
      getTenants(forceRefresh: forceRefresh),
      getComplaints(ownerId, forceRefresh: forceRefresh),
      getPayments(forceRefresh: forceRefresh),
      getBuildings(ownerId, forceRefresh: forceRefresh),
    ]);
    
    final dashboardData = {
      'rooms': futures[0],
      'tenants': futures[1],
      'complaints': futures[2],
      'payments': futures[3],
      'buildings': futures[4],
      'loadedAt': DateTime.now().toIso8601String(),
    };
    
    // Cache dashboard data
    await _dashboardBox?.put(cacheKey, dashboardData);
    await _updateTimestamp(cacheKey);
    _memoryCache[cacheKey] = dashboardData;
    
    debugPrint('✅ [HIVE API] Dashboard loaded and cached in ${stopwatch.elapsedMilliseconds}ms');
    return dashboardData;
  }

  // ===== CACHE MANAGEMENT =====
  
  static Future<void> invalidateCache(String dataType, [String? ownerId]) async {
    await init();
    
    switch (dataType) {
      case 'rooms':
        final key = 'rooms_${ownerId ?? AuthService.getOwnerId()}';
        await _roomsBox?.delete(key);
        await _timestampsBox?.delete(key);
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
        await _invalidateDashboard(ownerId);
        break;
        
      case 'tenants':
        const key = 'tenants_all';
        await _tenantsBox?.delete(key);
        await _timestampsBox?.delete(key);
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
        await _invalidateDashboard(ownerId);
        break;
        
      case 'complaints':
        final key = 'complaints_${ownerId ?? AuthService.getOwnerId()}';
        await _complaintsBox?.delete(key);
        await _timestampsBox?.delete(key);
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
        await _invalidateDashboard(ownerId);
        break;
        
      case 'payments':
        const key = 'payments_all';
        await _paymentsBox?.delete(key);
        await _timestampsBox?.delete(key);
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
        await _invalidateDashboard(ownerId);
        break;
        
      case 'buildings':
        final key = 'buildings_${ownerId ?? AuthService.getOwnerId()}';
        await _buildingsBox?.delete(key);
        await _timestampsBox?.delete(key);
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
        await _invalidateDashboard(ownerId);
        break;
        
      case 'service_providers':
        // Clear all service provider caches
        final keys = _serviceProvidersBox?.keys.toList() ?? [];
        for (final key in keys) {
          await _serviceProvidersBox?.delete(key);
          await _timestampsBox?.delete(key);
          _memoryCache.remove(key);
          _cacheTimestamps.remove(key);
        }
        break;
        
      case 'dashboard':
        final key = 'dashboard_${ownerId ?? AuthService.getOwnerId()}';
        await _dashboardBox?.delete(key);
        await _timestampsBox?.delete(key);
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
        break;
    }
    
    debugPrint('🗑️ [HIVE API] Invalidated $dataType cache');
  }
  
  static Future<void> _invalidateDashboard([String? ownerId]) async {
    final key = 'dashboard_${ownerId ?? AuthService.getOwnerId()}';
    await _dashboardBox?.delete(key);
    await _timestampsBox?.delete(key);
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  static Future<void> clearAllCache() async {
    await init();
    
    try {
      await Future.wait([
        _roomsBox?.clear() ?? Future.value(),
        _tenantsBox?.clear() ?? Future.value(),
        _complaintsBox?.clear() ?? Future.value(),
        _paymentsBox?.clear() ?? Future.value(),
        _buildingsBox?.clear() ?? Future.value(),
        _serviceProvidersBox?.clear() ?? Future.value(),
        _dashboardBox?.clear() ?? Future.value(),
        _timestampsBox?.clear() ?? Future.value(),
      ]);
      
      _memoryCache.clear();
      _cacheTimestamps.clear();
      
      debugPrint('🗑️ [HIVE API] Cleared all cache');
    } catch (e) {
      debugPrint('❌ [HIVE API] Failed to clear all cache: $e');
    }
  }

  static Map<String, dynamic> getCacheStats() {
    return {
      'memoryCache': _memoryCache.keys.toList(),
      'memoryCacheSize': _memoryCache.length,
      'ongoingRequests': _ongoingRequests.keys.toList(),
      'hiveCacheStats': {
        'rooms': _roomsBox?.length ?? 0,
        'tenants': _tenantsBox?.length ?? 0,
        'complaints': _complaintsBox?.length ?? 0,
        'payments': _paymentsBox?.length ?? 0,
        'buildings': _buildingsBox?.length ?? 0,
        'serviceProviders': _serviceProvidersBox?.length ?? 0,
        'dashboard': _dashboardBox?.length ?? 0,
        'timestamps': _timestampsBox?.length ?? 0,
      },
      'cacheTimestamps': _cacheTimestamps.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }

  static Future<void> compactAllBoxes() async {
    try {
      await Future.wait([
        _roomsBox?.compact() ?? Future.value(),
        _tenantsBox?.compact() ?? Future.value(),
        _complaintsBox?.compact() ?? Future.value(),
        _paymentsBox?.compact() ?? Future.value(),
        _buildingsBox?.compact() ?? Future.value(),
        _serviceProvidersBox?.compact() ?? Future.value(),
        _dashboardBox?.compact() ?? Future.value(),
        _timestampsBox?.compact() ?? Future.value(),
      ]);
      
      debugPrint('🗜️ [HIVE API] All boxes compacted successfully');
    } catch (e) {
      debugPrint('❌ [HIVE API] Failed to compact boxes: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      _httpClient.close();
      _ongoingRequests.clear();
      
      await Future.wait([
        _roomsBox?.close() ?? Future.value(),
        _tenantsBox?.close() ?? Future.value(),
        _complaintsBox?.close() ?? Future.value(),
        _paymentsBox?.close() ?? Future.value(),
        _buildingsBox?.close() ?? Future.value(),
        _serviceProvidersBox?.close() ?? Future.value(),
        _dashboardBox?.close() ?? Future.value(),
        _timestampsBox?.close() ?? Future.value(),
      ]);
      
      _memoryCache.clear();
      _cacheTimestamps.clear();
      
      debugPrint('🔒 [HIVE API] Disposed successfully');
    } catch (e) {
      debugPrint('❌ [HIVE API] Failed to dispose: $e');
    }
  }
}