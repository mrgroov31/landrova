import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vacating_request.dart';

class VacatingRequestService {
  static const String _boxName = 'vacating_requests';
  static Box<VacatingRequest>? _box;

  // Initialize Hive and open the box
  static Future<void> _initialize() async {
    if (_box != null && _box!.isOpen) return;
    
    try {
      // Check if adapter is registered
      if (!Hive.isAdapterRegistered(4)) {
        throw Exception('VacatingRequestAdapter (typeId: 4) is not registered. Please restart the app.');
      }
      _box = await Hive.openBox<VacatingRequest>(_boxName);
    } catch (e) {
      debugPrint('Error initializing VacatingRequestService: $e');
      rethrow;
    }
  }

  // Get all vacating requests
  static Future<List<VacatingRequest>> getAllRequests() async {
    await _initialize();
    if (_box == null) return [];
    
    final requests = _box!.values.toList();
    // Sort by creation date (newest first)
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  // Get requests by tenant ID
  static Future<List<VacatingRequest>> getRequestsByTenant(String tenantId) async {
    await _initialize();
    if (_box == null) return [];
    
    final allRequests = _box!.values.toList();
    return allRequests.where((r) => r.tenantId == tenantId).toList();
  }

  // Get pending requests (for owners)
  static Future<List<VacatingRequest>> getPendingRequests() async {
    await _initialize();
    if (_box == null) return [];
    
    final allRequests = _box!.values.toList();
    return allRequests.where((r) => r.status == 'pending').toList();
  }

  // Get requests by room number
  static Future<List<VacatingRequest>> getRequestsByRoom(String roomNumber) async {
    await _initialize();
    if (_box == null) return [];
    
    final allRequests = _box!.values.toList();
    return allRequests.where((r) => r.roomNumber == roomNumber).toList();
  }

  // Add a new vacating request
  static Future<void> addRequest(VacatingRequest request) async {
    try {
      await _initialize();
      if (_box == null) {
        throw Exception('Hive box not initialized');
      }
      await _box!.put(request.id, request);
    } catch (e) {
      throw Exception('Failed to add vacating request: $e');
    }
  }

  // Update a vacating request
  static Future<void> updateRequest(VacatingRequest request) async {
    await _initialize();
    if (_box == null) return;
    await _box!.put(request.id, request);
  }

  // Delete a vacating request
  static Future<void> deleteRequest(String id) async {
    await _initialize();
    if (_box == null) return;
    await _box!.delete(id);
  }

  // Get request by ID
  static Future<VacatingRequest?> getRequestById(String id) async {
    await _initialize();
    if (_box == null) return null;
    return _box!.get(id);
  }

  // Get count of pending requests (for notification badge)
  static Future<int> getPendingCount() async {
    final pending = await getPendingRequests();
    return pending.length;
  }
}

