import 'package:hive_flutter/hive_flutter.dart';
import '../models/tenant.dart';
import '../services/api_service.dart';

class TenantService {
  static const String _boxName = 'tenants';
  static Box<Tenant>? _box;

  // Initialize Hive and open the box
  static Future<void> _initialize() async {
    if (_box != null && _box!.isOpen) return;
    
    try {
      _box = await Hive.openBox<Tenant>(_boxName);
    } catch (e) {
      rethrow;
    }
  }

  // Get all tenants (from Hive and merge with API data)
  static Future<List<Tenant>> getAllTenants() async {
    await _initialize();
    
    // Load from API first
    List<Tenant> apiTenants = [];
    try {
      final response = await ApiService.fetchTenants();
      apiTenants = ApiService.parseTenants(response);
    } catch (e) {
      // If API fails, continue with local data
    }
    
    // Load from Hive
    List<Tenant> localTenants = [];
    if (_box != null) {
      localTenants = _box!.values.toList();
    }
    
    // Merge: API tenants take precedence, but add local ones that don't exist in API
    final Map<String, Tenant> merged = {};
    
    // Add API tenants first
    for (var tenant in apiTenants) {
      merged[tenant.id] = tenant;
    }
    
    // Add local tenants that aren't in API
    for (var tenant in localTenants) {
      if (!merged.containsKey(tenant.id)) {
        merged[tenant.id] = tenant;
      }
    }
    
    // Sort by move-in date (newest first)
    final sorted = merged.values.toList();
    sorted.sort((a, b) => b.moveInDate.compareTo(a.moveInDate));
    
    return sorted;
  }

  // Add a new tenant
  static Future<void> addTenant(Tenant tenant) async {
    await _initialize();
    if (_box == null) return;
    await _box!.put(tenant.id, tenant);
  }

  // Update a tenant
  static Future<void> updateTenant(Tenant tenant) async {
    await _initialize();
    if (_box == null) return;
    await _box!.put(tenant.id, tenant);
  }

  // Delete a tenant
  static Future<void> deleteTenant(String id) async {
    await _initialize();
    if (_box == null) return;
    await _box!.delete(id);
  }

  // Get tenant by ID
  static Future<Tenant?> getTenantById(String id) async {
    await _initialize();
    if (_box == null) return null;
    return _box!.get(id);
  }

  // Get tenant by invitation token
  static Future<Tenant?> getTenantByInvitationToken(String token) async {
    await _initialize();
    if (_box == null) return null;
    try {
      return _box!.values.firstWhere(
        (tenant) => tenant.invitationToken == token,
      );
    } catch (e) {
      return null;
    }
  }
}

