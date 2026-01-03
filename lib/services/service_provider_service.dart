import 'package:hive_flutter/hive_flutter.dart';
import '../models/service_provider.dart';

class ServiceProviderService {
  static const String _boxName = 'service_providers';
  static Box<ServiceProvider>? _box;

  // Initialize Hive and open the box
  static Future<void> _initialize() async {
    if (_box != null && _box!.isOpen) return;
    
    try {
      _box = await Hive.openBox<ServiceProvider>(_boxName);
    } catch (e) {
      // Handle error - adapter should be registered in main.dart
      rethrow;
    }
  }

  // Get all registered providers
  static Future<List<ServiceProvider>> getAllProviders() async {
    await _initialize();
    if (_box == null) return [];
    return _box!.values.toList();
  }

  // Add a new provider
  static Future<void> addProvider(ServiceProvider provider) async {
    await _initialize();
    if (_box == null) return;
    await _box!.put(provider.id, provider);
  }

  // Get providers by service type
  static Future<List<ServiceProvider>> getProvidersByType(String serviceType) async {
    await _initialize();
    if (_box == null) return [];
    return _box!.values
        .where((p) => p.serviceType.toLowerCase() == serviceType.toLowerCase())
        .toList();
  }

  // Get suggested providers based on complaint keywords
  static Future<List<ServiceProvider>> getSuggestedProviders({
    required String complaintTitle,
    required String complaintDescription,
  }) async {
    await _initialize();
    
    final title = complaintTitle.toLowerCase();
    final description = complaintDescription.toLowerCase();
    
    List<ServiceProvider> suggested = [];
    
    // Electrician suggestions
    if (title.contains('electric') || title.contains('power') || 
        title.contains('wiring') || title.contains('switch') ||
        description.contains('electric') || description.contains('power') ||
        description.contains('wiring') || description.contains('switch')) {
      suggested.addAll(await getProvidersByType('electrician'));
    }
    
    // Plumber suggestions
    if (title.contains('water') || title.contains('pipe') || 
        title.contains('leak') || title.contains('plumb') ||
        description.contains('water') || description.contains('pipe') ||
        description.contains('leak') || description.contains('plumb')) {
      suggested.addAll(await getProvidersByType('plumber'));
    }
    
    // AC Repair suggestions
    if (title.contains('ac') || title.contains('air') || 
        title.contains('cooling') || description.contains('ac') ||
        description.contains('cooling') || description.contains('air conditioning')) {
      suggested.addAll(await getProvidersByType('ac_repair'));
    }
    
    // Appliance Repair suggestions
    if (title.contains('appliance') || title.contains('washing') ||
        title.contains('refrigerator') || title.contains('microwave') ||
        description.contains('appliance') || description.contains('washing machine') ||
        description.contains('refrigerator')) {
      suggested.addAll(await getProvidersByType('appliance_repair'));
    }
    
    // Carpenter suggestions
    if (title.contains('door') || title.contains('window') ||
        title.contains('furniture') || title.contains('wood') ||
        description.contains('door') || description.contains('window') ||
        description.contains('furniture') || description.contains('carpenter')) {
      suggested.addAll(await getProvidersByType('carpenter'));
    }
    
    // Painter suggestions
    if (title.contains('paint') || title.contains('wall') ||
        description.contains('paint') || description.contains('wall')) {
      suggested.addAll(await getProvidersByType('painter'));
    }
    
    // Cleaning suggestions
    if (title.contains('clean') || title.contains('dirty') ||
        description.contains('clean') || description.contains('dirty')) {
      suggested.addAll(await getProvidersByType('cleaning'));
    }
    
    // Handyman suggestions (fallback for general issues)
    if (suggested.isEmpty) {
      suggested.addAll(await getProvidersByType('handyman'));
    }
    
    // Remove duplicates
    final uniqueProviders = <String, ServiceProvider>{};
    for (var provider in suggested) {
      if (!uniqueProviders.containsKey(provider.id)) {
        uniqueProviders[provider.id] = provider;
      }
    }
    
    return uniqueProviders.values.toList();
  }

  // Get provider by ID
  static Future<ServiceProvider?> getProviderById(String id) async {
    await _initialize();
    if (_box == null) return null;
    return _box!.get(id);
  }

  // Update provider
  static Future<void> updateProvider(ServiceProvider updatedProvider) async {
    await _initialize();
    if (_box == null) return;
    await _box!.put(updatedProvider.id, updatedProvider);
  }

  // Delete provider
  static Future<void> deleteProvider(String id) async {
    await _initialize();
    if (_box == null) return;
    await _box!.delete(id);
  }
}

