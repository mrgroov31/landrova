import 'package:hive_flutter/hive_flutter.dart';
import '../models/complaint.dart';
import '../services/api_service.dart';

class ComplaintService {
  static const String _boxName = 'complaints';
  static Box<Complaint>? _box;

  // Initialize Hive and open the box
  static Future<void> _initialize() async {
    if (_box != null && _box!.isOpen) return;
    
    try {
      _box = await Hive.openBox<Complaint>(_boxName);
    } catch (e) {
      rethrow;
    }
  }

  // Get all complaints (from Hive and merge with API data)
  static Future<List<Complaint>> getAllComplaints() async {
    await _initialize();
    
    // Load from API first
    List<Complaint> apiComplaints = [];
    try {
      final response = await ApiService.fetchComplaints();
      apiComplaints = ApiService.parseComplaints(response);
    } catch (e) {
      // If API fails, continue with local data
    }
    
    // Load from Hive
    List<Complaint> localComplaints = [];
    if (_box != null) {
      localComplaints = _box!.values.toList();
    }
    
    // Merge: Hive (local) complaints take precedence over API (since they have latest updates)
    // but add API complaints that don't exist in Hive
    final Map<String, Complaint> merged = {};
    
    // Add local (Hive) complaints first - these have the latest updates
    for (var complaint in localComplaints) {
      merged[complaint.id] = complaint;
    }
    
    // Add API complaints that aren't in Hive (new complaints from API)
    for (var complaint in apiComplaints) {
      if (!merged.containsKey(complaint.id)) {
        merged[complaint.id] = complaint;
      }
    }
    
    // Sort by creation date (newest first)
    final sorted = merged.values.toList();
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return sorted;
  }

  // Add a new complaint
  static Future<void> addComplaint(Complaint complaint) async {
    await _initialize();
    if (_box == null) return;
    await _box!.put(complaint.id, complaint);
  }

  // Update a complaint
  static Future<void> updateComplaint(Complaint complaint) async {
    await _initialize();
    if (_box == null) return;
    await _box!.put(complaint.id, complaint);
  }

  // Delete a complaint
  static Future<void> deleteComplaint(String id) async {
    await _initialize();
    if (_box == null) return;
    await _box!.delete(id);
  }

  // Get complaint by ID
  static Future<Complaint?> getComplaintById(String id) async {
    await _initialize();
    if (_box == null) return null;
    return _box!.get(id);
  }
}

