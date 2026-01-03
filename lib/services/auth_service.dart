import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/tenant.dart';
import '../models/building.dart';
import '../services/tenant_service.dart';
import '../services/api_service.dart';

class AuthService {
  static const String _boxName = 'auth';
  static const String _userKey = 'current_user';
  static Box? _box;
  static AppUser? _currentUser;

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
        return AuthResult.success(owner);
      } else {
        return AuthResult.failure('Invalid email or password. Use: owner@ownhouse.com / owner123');
      }
    } catch (e) {
      return AuthResult.failure('Login failed: $e');
    }
  }

  // Tenant login
  static Future<AuthResult> loginTenant({
    required String email,
    required String password,
  }) async {
    await _initialize();

    try {
      // In a real app, this would be an API call
      // For now, we'll check against tenant data
      final tenants = await TenantService.getAllTenants();
      
      // Try to find tenant by email
      final tenant = tenants.firstWhere(
        (t) => t.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Tenant not found'),
      );

      // In a real app, verify password hash
      // For now, accept any password if tenant exists
      // Default password: tenant123
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
      return AuthResult.failure('Invalid email or password');
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

