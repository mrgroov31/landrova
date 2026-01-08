import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/tenant.dart';
import '../services/tenant_service.dart';
import '../services/api_service.dart';

class AuthService {
  static const String _boxName = 'auth';
  static const String _userKey = 'current_user';
  static const String _ownerIdKey = 'owner_id';
  static Box? _box;
  static AppUser? _currentUser;
  
  // Centralized Owner ID - can be updated from API response or stored locally
  static const String defaultOwnerId = '44a93012-8edb-49cf-8fc2-619c7dfbc679';

  // Initialize Hive box
  static Future<void> _initialize() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox(_boxName);
    _loadCurrentUser();
  }

  // Load current user from storage
  static void _loadCurrentUser() {
    if (_box != null) {
      final userData = _box!.get(_userKey);
      if (userData != null) {
        _currentUser = AppUser.fromJson(Map<String, dynamic>.from(userData));
      }
    }
  }

  // Get current user
  static AppUser? get currentUser => _currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;

  // Get owner ID - centralized location
  static String getOwnerId() {
    // First, try to get from stored value
    if (_box != null && _box!.isOpen) {
      final storedOwnerId = _box!.get(_ownerIdKey);
      if (storedOwnerId != null && storedOwnerId.toString().isNotEmpty) {
        return storedOwnerId.toString();
      }
    }
    
    // Fallback to default owner ID
    return defaultOwnerId;
  }

  // Set owner ID (can be called after login or API response)
  static Future<void> setOwnerId(String ownerId) async {
    await _initialize();
    if (_box != null) {
      await _box!.put(_ownerIdKey, ownerId);
    }
  }

  // Owner login
  static Future<AuthResult> loginOwner({
    required String email,
    required String password,
  }) async {
    await _initialize();

    try {
      // Normalize email (trim and lowercase)
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPassword = password.trim();
      
      // In a real app, this would be an API call
      // For now, we'll use mock data
      // Owner credentials: owner@ownhouse.com / owner123
      if (normalizedEmail == 'owner@ownhouse.com' && normalizedPassword == 'owner123') {
        final owner = AppUser.owner(
          id: 'owner_001',
          email: normalizedEmail,
          phone: '+91 9876543200',
          name: 'Property Owner',
          profileImage: null,
          buildingId: '1',
        );

        await _saveUser(owner);
        // Store the centralized owner ID after login
        await setOwnerId(defaultOwnerId);
        return AuthResult.success(owner);
      } else {
        return AuthResult.failure('Invalid email or password. Use: owner@ownhouse.com / owner123');
      }
    } catch (e) {
      return AuthResult.failure('Login failed: $e');
    }
  }

  // Tenant login with API integration
  static Future<AuthResult> loginTenant({
    required String email,
    required String password,
  }) async {
    await _initialize();

    try {
      // First, try to authenticate against API tenants
      final ownerId = getOwnerId();
      
      try {
        // Fetch tenants from API
        final tenantsResponse = await ApiService.fetchTenantsByOwnerId(ownerId);
        final apiTenants = ApiService.parseApiTenants(tenantsResponse);
        
        // Try to find tenant by email in API data
        final apiTenant = apiTenants.firstWhere(
          (t) => t.email.toLowerCase() == email.toLowerCase(),
          orElse: () => throw Exception('Tenant not found in API'),
        );

        // For API tenants, use a simple password check
        // In a real app, this would be a proper API authentication call
        // For now, accept common passwords or tenant phone number
        if (password == 'tenant123' || 
            password == '123456' || 
            password == apiTenant.phone ||
            password == apiTenant.phone.substring(apiTenant.phone.length - 4)) { // Last 4 digits of phone
          
          final user = AppUser.tenant(
            id: apiTenant.tenantId, // Use tenantId instead of id
            email: apiTenant.email,
            phone: apiTenant.phone,
            name: apiTenant.name,
            profileImage: null,
            roomNumber: apiTenant.roomNumber,
            tenantId: apiTenant.tenantId, // Use tenantId instead of id
          );

          await _saveUser(user);
          return AuthResult.success(user);
        }
      } catch (apiError) {
        // If API fails, fall back to local tenant data
        debugPrint('API tenant login failed, trying local: $apiError');
      }

      // Fallback: Try local tenant data
      final tenants = await TenantService.getAllTenants();
      
      // Try to find tenant by email in local data
      final tenant = tenants.firstWhere(
        (t) => t.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Tenant not found'),
      );

      // For local tenants, use default passwords
      if (password == 'tenant123' || password == '123456') {
        final user = AppUser.tenant(
          id: tenant.id,
          email: tenant.email,
          phone: tenant.phone,
          name: tenant.name,
          profileImage: tenant.profileImage,
          roomNumber: tenant.roomNumber,
          tenantId: tenant.id,
        );

        await _saveUser(user);
        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Invalid email or password');
      }
    } catch (e) {
      return AuthResult.failure('Invalid email or password. Try: tenant123, 123456, or your phone number');
    }
  }

  // Sync API tenants to local storage for offline access
  static Future<void> syncApiTenants() async {
    try {
      final ownerId = getOwnerId();
      final tenantsResponse = await ApiService.fetchTenantsByOwnerId(ownerId);
      final apiTenants = ApiService.parseApiTenants(tenantsResponse);
      
      // Convert API tenants to local tenant format and save
      for (final apiTenant in apiTenants) {
        final localTenant = Tenant(
          id: apiTenant.tenantId, // Use tenantId instead of id
          name: apiTenant.name,
          email: apiTenant.email,
          phone: apiTenant.phone,
          roomNumber: apiTenant.roomNumber,
          moveInDate: apiTenant.moveInDate ?? DateTime.now(),
          monthlyRent: apiTenant.monthlyRent,
          type: apiTenant.type,
          isActive: apiTenant.isActive,
          aadharNumber: apiTenant.aadharNumber,
          emergencyContact: apiTenant.emergencyContact,
          occupation: apiTenant.occupation,
        );
        
        // Save to local storage
        await TenantService.addTenant(localTenant);
      }
      
      debugPrint('✅ [AUTH] Synced ${apiTenants.length} API tenants to local storage');
    } catch (e) {
      debugPrint('❌ [AUTH] Failed to sync API tenants: $e');
    }
  }

  // Enhanced tenant login that works with rooms API data
  static Future<AuthResult> loginTenantEnhanced({
    required String email,
    required String password,
  }) async {
    await _initialize();

    try {
      debugPrint('🔐 [AUTH] Starting enhanced tenant login for: $email');
      
      // First, try to get tenant data from rooms API (workaround for tenant API issue)
      final ownerId = getOwnerId();
      
      try {
        debugPrint('🔐 [AUTH] Fetching rooms to extract tenant data...');
        final roomsResponse = await ApiService.fetchRoomsByOwnerId(ownerId);
        final rooms = ApiService.parseRooms(roomsResponse);
        
        // Extract tenants from rooms data
        final roomTenants = rooms
            .where((room) => room.hasTenant && room.tenant != null)
            .map((room) => room.tenant!)
            .toList();
        
        debugPrint('🔐 [AUTH] Found ${roomTenants.length} tenants from rooms API');
        
        // Try to find tenant by email
        final roomTenant = roomTenants.firstWhere(
          (t) => t.email.toLowerCase() == email.toLowerCase(),
          orElse: () => throw Exception('Tenant not found in rooms data'),
        );
        
        debugPrint('🔐 [AUTH] Found tenant: ${roomTenant.name} (${roomTenant.email})');
        
        // Multiple password options for tenant login
        final validPasswords = [
          'tenant123',           // Default password
          '123456',             // Alternative default
          roomTenant.phone,     // Full phone number
          roomTenant.phone.length >= 4 ? roomTenant.phone.substring(roomTenant.phone.length - 4) : '', // Last 4 digits
          roomTenant.name.toLowerCase().replaceAll(' ', ''), // Name without spaces
        ].where((p) => p.isNotEmpty).toList();
        
        debugPrint('🔐 [AUTH] Valid passwords: ${validPasswords.map((p) => p.length > 4 ? '${p.substring(0, 2)}***' : p).toList()}');
        
        if (validPasswords.contains(password)) {
          debugPrint('🔐 [AUTH] Password match found! Creating user session...');
          
          final user = AppUser.tenant(
            id: roomTenant.id,
            email: roomTenant.email,
            phone: roomTenant.phone,
            name: roomTenant.name,
            profileImage: null,
            roomNumber: rooms.firstWhere((r) => r.tenant?.id == roomTenant.id).number,
            tenantId: roomTenant.id,
          );

          await _saveUser(user);
          debugPrint('✅ [AUTH] Tenant login successful!');
          return AuthResult.success(user);
        } else {
          debugPrint('❌ [AUTH] Password does not match any valid options');
          return AuthResult.failure('Invalid password. Try: tenant123, your phone number, or your name');
        }
        
      } catch (roomsError) {
        debugPrint('❌ [AUTH] Rooms API tenant extraction failed: $roomsError');
      }

      // Fallback: Try the original tenant API approach
      try {
        debugPrint('🔐 [AUTH] Trying original tenant API approach...');
        final tenantsResponse = await ApiService.fetchTenantsByOwnerId(ownerId);
        final apiTenants = ApiService.parseApiTenants(tenantsResponse);
        
        final apiTenant = apiTenants.firstWhere(
          (t) => t.email.toLowerCase() == email.toLowerCase(),
          orElse: () => throw Exception('Tenant not found in API'),
        );

        final validPasswords = [
          'tenant123',
          '123456',
          apiTenant.phone,
          apiTenant.phone.length >= 4 ? apiTenant.phone.substring(apiTenant.phone.length - 4) : '',
          apiTenant.name.toLowerCase().replaceAll(' ', ''),
        ].where((p) => p.isNotEmpty).toList();

        if (validPasswords.contains(password)) {
          final user = AppUser.tenant(
            id: apiTenant.tenantId,
            email: apiTenant.email,
            phone: apiTenant.phone,
            name: apiTenant.name,
            profileImage: null,
            roomNumber: apiTenant.roomNumber,
            tenantId: apiTenant.tenantId,
          );

          await _saveUser(user);
          return AuthResult.success(user);
        }
      } catch (apiError) {
        debugPrint('❌ [AUTH] API tenant login also failed: $apiError');
      }

      // Final fallback: Try local tenant data
      debugPrint('🔐 [AUTH] Trying local tenant data as final fallback...');
      final tenants = await TenantService.getAllTenants();
      
      final tenant = tenants.firstWhere(
        (t) => t.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Tenant not found'),
      );

      final validPasswords = [
        'tenant123',
        '123456',
        tenant.phone,
        tenant.phone.length >= 4 ? tenant.phone.substring(tenant.phone.length - 4) : '',
        tenant.aadharNumber ?? '',
        tenant.name.toLowerCase().replaceAll(' ', ''),
      ].where((p) => p.isNotEmpty).toList();

      if (validPasswords.contains(password)) {
        final user = AppUser.tenant(
          id: tenant.id,
          email: tenant.email,
          phone: tenant.phone,
          name: tenant.name,
          profileImage: tenant.profileImage,
          roomNumber: tenant.roomNumber,
          tenantId: tenant.id,
        );

        await _saveUser(user);
        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Invalid password. Try: tenant123, your phone number, or your name');
      }
    } catch (e) {
      debugPrint('💥 [AUTH] All tenant login methods failed: $e');
      return AuthResult.failure('Tenant not found or invalid credentials. Try: tenant123, 123456, or your phone number');
    }
  }

  // Debug method to check available tenants
  static Future<void> debugAvailableTenants() async {
    try {
      final ownerId = getOwnerId();
      debugPrint('🔍 [DEBUG] Checking available tenants for owner: $ownerId');
      
      // Check rooms API for tenant data
      try {
        final roomsResponse = await ApiService.fetchRoomsByOwnerId(ownerId);
        final rooms = ApiService.parseRooms(roomsResponse);
        final roomTenants = rooms
            .where((room) => room.hasTenant && room.tenant != null)
            .map((room) => room.tenant!)
            .toList();
        
        debugPrint('🔍 [DEBUG] Tenants from rooms API (${roomTenants.length}):');
        for (final tenant in roomTenants) {
          debugPrint('  - ${tenant.name} (${tenant.email}) - Phone: ${tenant.phone}');
        }
      } catch (e) {
        debugPrint('❌ [DEBUG] Rooms API failed: $e');
      }
      
      // Check tenant API
      try {
        final tenantsResponse = await ApiService.fetchTenantsByOwnerId(ownerId);
        final apiTenants = ApiService.parseApiTenants(tenantsResponse);
        
        debugPrint('🔍 [DEBUG] Tenants from tenant API (${apiTenants.length}):');
        for (final tenant in apiTenants) {
          debugPrint('  - ${tenant.name} (${tenant.email}) - Phone: ${tenant.phone}');
        }
      } catch (e) {
        debugPrint('❌ [DEBUG] Tenant API failed: $e');
      }
      
      // Check local storage
      try {
        final localTenants = await TenantService.getAllTenants();
        debugPrint('🔍 [DEBUG] Tenants from local storage (${localTenants.length}):');
        for (final tenant in localTenants) {
          debugPrint('  - ${tenant.name} (${tenant.email}) - Phone: ${tenant.phone}');
        }
      } catch (e) {
        debugPrint('❌ [DEBUG] Local storage failed: $e');
      }
    } catch (e) {
      debugPrint('💥 [DEBUG] Debug method failed: $e');
    }
  }

  // Save user to storage
  static Future<void> _saveUser(AppUser user) async {
    await _initialize();
    if (_box != null) {
      try {
        final userJson = user.toJson();
        await _box!.put(_userKey, userJson);
        _currentUser = user;
        // Verify it was saved
        final saved = _box!.get(_userKey);
        if (saved == null) {
          throw Exception('Failed to save user to storage');
        }
      } catch (e) {
        throw Exception('Error saving user: $e');
      }
    } else {
      throw Exception('Hive box not initialized');
    }
  }

  // Logout
  static Future<void> logout() async {
    await _initialize();
    if (_box != null) {
      await _box!.delete(_userKey);
      _currentUser = null;
    }
  }

  // Clear all auth data
  static Future<void> clearAuth() async {
    await logout();
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final AppUser? user;
  final String? error;

  AuthResult.success(this.user)
      : success = true,
        error = null;

  AuthResult.failure(this.error)
      : success = false,
        user = null;
}

