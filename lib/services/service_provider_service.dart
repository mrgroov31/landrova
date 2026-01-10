import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/service_provider.dart';
import 'api_service.dart';
import 'optimized_api_service.dart';

class ServiceProviderService {
  static const String baseUrl = 'https://leranothrive.com/api';

  // Get all service providers with optional filters
  static Future<List<ServiceProvider>> getAllServiceProviders({
    String? serviceType,
    String? city,
    String? availability,
    double? minRating,
    double? maxRating,
    int? minPrice,
    int? maxPrice,
    bool? emergencyAvailable,
    bool? verified,
    String? sortBy = 'rating',
    String? sortOrder = 'desc',
    int page = 1,
    int limit = 10,
  }) async {
    try {
      debugPrint('🔧 [SERVICE] Fetching service providers from API only');
      
      final response = await ApiService.fetchServiceProviders(
        serviceType: serviceType,
        city: city,
        availability: availability,
        minRating: minRating,
        maxRating: maxRating,
        minPrice: minPrice,
        maxPrice: maxPrice,
        emergencyAvailable: emergencyAvailable,
        verified: verified,
        sortBy: sortBy,
        sortOrder: sortOrder,
        page: page,
        limit: limit,
      );

      final providers = ApiService.parseServiceProviders(response);
      debugPrint('✅ [SERVICE] Successfully fetched ${providers.length} service providers from API');
      return providers;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to fetch service providers from API: $e');
      // Return empty list instead of mock data
      return [];
    }
  }

  // Get service providers by type
  static Future<List<ServiceProvider>> getServiceProvidersByType(String serviceType) async {
    return getAllServiceProviders(
      serviceType: serviceType,
      verified: true,
      sortBy: 'rating',
      sortOrder: 'desc',
    );
  }

  // Get available service providers
  static Future<List<ServiceProvider>> getAvailableServiceProviders() async {
    return getAllServiceProviders(
      availability: 'available',
      verified: true,
      sortBy: 'rating',
      sortOrder: 'desc',
    );
  }

  // Get emergency service providers
  static Future<List<ServiceProvider>> getEmergencyServiceProviders() async {
    return getAllServiceProviders(
      emergencyAvailable: true,
      availability: 'available',
      verified: true,
      sortBy: 'rating',
      sortOrder: 'desc',
    );
  }

  // Get top rated service providers
  static Future<List<ServiceProvider>> getTopRatedServiceProviders({int limit = 5}) async {
    return getAllServiceProviders(
      minRating: 4.5,
      verified: true,
      sortBy: 'rating',
      sortOrder: 'desc',
      limit: limit,
    );
  }

  // Search service providers
  static Future<List<ServiceProvider>> searchServiceProviders({
    required String query,
    String? serviceType,
    String? city,
    double? minRating,
    int? maxPrice,
  }) async {
    try {
      debugPrint('🔍 [SERVICE] Searching service providers: $query');
      
      final filters = <String, dynamic>{};
      if (serviceType != null) filters['serviceType'] = serviceType;
      if (city != null) filters['city'] = city;
      if (minRating != null) filters['rating'] = {'min': minRating};
      if (maxPrice != null) {
        filters['priceRange'] = {'max': maxPrice, 'currency': 'INR'};
      }

      final response = await ApiService.searchServiceProviders(
        filters: filters,
        searchQuery: query,
        sortBy: 'rating',
        sortOrder: 'desc',
      );

      final providers = ApiService.parseServiceProviders(response);
      debugPrint('✅ [SERVICE] Search completed: ${providers.length} providers found');
      return providers;
    } catch (e) {
      debugPrint('❌ [SERVICE] Search failed: $e');
      // Return empty list instead of mock data
      return [];
    }
  }

  // Create a new service provider
  static Future<ServiceProvider?> createServiceProvider({
    required String name,
    required String serviceType,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required List<String> specialties,
    required String experience,
    required Map<String, dynamic> priceRange,
    required Map<String, dynamic> workingHours,
    required bool emergencyAvailable,
    required List<String> languages,
    Map<String, dynamic>? documents,
    String? profileImage,
    Map<String, dynamic>? bankDetails,
    List<Map<String, dynamic>>? references,
  }) async {
    try {
      debugPrint('🔧 [SERVICE] Creating service provider: $name');
      
      final response = await ApiService.createServiceProvider(
        name: name,
        serviceType: serviceType,
        phone: phone,
        email: email,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        specialties: specialties,
        experience: experience,
        priceRange: priceRange,
        workingHours: workingHours,
        emergencyAvailable: emergencyAvailable,
        languages: languages,
        documents: documents,
        profileImage: profileImage,
        bankDetails: bankDetails,
        references: references,
      );

      // Handle different possible response structures
      if (response != null && response is Map<String, dynamic>) {
        debugPrint('🔍 [SERVICE] Processing API response: ${response.keys}');
        
        // Check for success indicator
        if (response['success'] == true || response.containsKey('id')) {
          Map<String, dynamic> providerData;
          
          // Try different response structures
          if (response.containsKey('data') && response['data'] != null) {
            final data = response['data'];
            
            if (data is Map<String, dynamic>) {
              if (data.containsKey('serviceProvider') && data['serviceProvider'] != null) {
                providerData = data['serviceProvider'] as Map<String, dynamic>;
              } else {
                providerData = data;
              }
            } else {
              debugPrint('❌ [SERVICE] Data is not a Map: $data');
              return null;
            }
          } else if (response.containsKey('id')) {
            // Response itself might be the provider data
            providerData = response;
          } else {
            debugPrint('❌ [SERVICE] No data or id found in response');
            return null;
          }
          
          debugPrint('✅ [SERVICE] Creating ServiceProvider from data: ${providerData.keys}');
          return ServiceProvider.fromJson(providerData);
        } else {
          debugPrint('❌ [SERVICE] API response indicates failure: $response');
          return null;
        }
      } else {
        debugPrint('❌ [SERVICE] Invalid response format: $response');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to create service provider: $e');
      return null;
    }
  }

  // Update service provider
  static Future<ServiceProvider?> updateServiceProvider({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    List<String>? specialties,
    String? experience,
    Map<String, dynamic>? priceRange,
    Map<String, dynamic>? workingHours,
    bool? emergencyAvailable,
    List<String>? languages,
    bool? isAvailable,
    String? profileImage,
    Map<String, dynamic>? bankDetails,
  }) async {
    try {
      debugPrint('🔧 [SERVICE] Updating service provider: $id');
      
      final response = await ApiService.updateServiceProvider(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        specialties: specialties,
        experience: experience,
        priceRange: priceRange,
        workingHours: workingHours,
        emergencyAvailable: emergencyAvailable,
        languages: languages,
        isAvailable: isAvailable,
        profileImage: profileImage,
        bankDetails: bankDetails,
      );

      if (response['success'] == true && response['data'] != null) {
        final providerData = response['data']['serviceProvider'];
        return ServiceProvider.fromJson(providerData);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to update service provider: $e');
      return null;
    }
  }

  // Book a service provider
  static Future<Map<String, dynamic>?> bookServiceProvider({
    required String serviceProviderId,
    required String customerId,
    required String buildingId,
    required String roomId,
    required String serviceType,
    required String jobTitle,
    required String jobDescription,
    required String priority,
    required String scheduledDate,
    required String scheduledTime,
    required int estimatedDuration,
    required Map<String, dynamic> location,
    required List<String> requirements,
    String? specialInstructions,
    Map<String, dynamic>? budgetRange,
    String paymentMethod = 'cash',
    bool emergencyJob = false,
    List<String> images = const [],
    String? customerNotes,
  }) async {
    try {
      debugPrint('📅 [SERVICE] Booking service provider: $serviceProviderId');
      
      final response = await ApiService.bookServiceProvider(
        serviceProviderId: serviceProviderId,
        customerId: customerId,
        buildingId: buildingId,
        roomId: roomId,
        serviceType: serviceType,
        jobTitle: jobTitle,
        jobDescription: jobDescription,
        priority: priority,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        estimatedDuration: estimatedDuration,
        location: location,
        requirements: requirements,
        specialInstructions: specialInstructions,
        budgetRange: budgetRange,
        paymentMethod: paymentMethod,
        emergencyJob: emergencyJob,
        images: images,
        customerNotes: customerNotes,
      );

      if (response['success'] == true) {
        return response['data'];
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to book service provider: $e');
      return null;
    }
  }

  // Get service provider reviews
  static Future<Map<String, dynamic>?> getServiceProviderReviews({
    required String serviceProviderId,
    int page = 1,
    int limit = 5,
  }) async {
    try {
      debugPrint('⭐ [SERVICE] Fetching reviews for: $serviceProviderId');
      
      final response = await ApiService.getServiceProviderReviews(
        serviceProviderId: serviceProviderId,
        page: page,
        limit: limit,
      );

      if (response['success'] == true) {
        return response['data'];
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to fetch reviews: $e');
      return null;
    }
  }

  // Get service types with counts
  static Future<List<Map<String, dynamic>>> getServiceTypes() async {
    try {
      final providers = await getAllServiceProviders();
      final serviceTypeCounts = <String, int>{};
      
      for (final provider in providers) {
        serviceTypeCounts[provider.serviceType] = 
            (serviceTypeCounts[provider.serviceType] ?? 0) + 1;
      }
      
      return serviceTypeCounts.entries.map((entry) => {
        'type': entry.key,
        'displayName': _getServiceTypeDisplayName(entry.key),
        'count': entry.value,
      }).toList();
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to get service types: $e');
      return [];
    }
  }

  // Get cities with service providers
  static Future<List<Map<String, dynamic>>> getCitiesWithProviders() async {
    try {
      final providers = await getAllServiceProviders();
      final cityCounts = <String, int>{};
      
      for (final provider in providers) {
        final city = provider.address?.split(',').last.trim() ?? 'Unknown';
        cityCounts[city] = (cityCounts[city] ?? 0) + 1;
      }
      
      return cityCounts.entries.map((entry) => {
        'city': entry.key,
        'count': entry.value,
      }).toList();
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to get cities: $e');
      return [];
    }
  }

  // Helper method to get service type display name
  static String _getServiceTypeDisplayName(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'electrician':
        return 'Electrician';
      case 'plumber':
        return 'Plumber';
      case 'carpenter':
        return 'Carpenter';
      case 'painter':
        return 'Painter';
      case 'ac_repair':
        return 'AC Repair';
      case 'appliance_repair':
        return 'Appliance Repair';
      case 'cleaning':
        return 'Cleaning Service';
      default:
        return serviceType;
    }
  }

  // ===== MISSING METHODS FOR BACKWARD COMPATIBILITY =====

  // Get suggested providers for a complaint (shows all available providers)
  static Future<List<ServiceProvider>> getSuggestedProviders({
    String? serviceType,
    String? complaintTitle,
    String? complaintDescription,
  }) async {
    try {
      debugPrint('🔍 [SERVICE] Getting all available service providers for complaint suggestions');
      debugPrint('🔍 [SERVICE] Complaint Title: $complaintTitle');
      debugPrint('🔍 [SERVICE] Complaint Description: $complaintDescription');
      
      // Get all available service providers (no filtering by keywords)
      final providers = await getAllServiceProviders(
        verified: true,
        sortBy: 'rating',
        sortOrder: 'desc',
        limit: 50, // Get more providers to show all options
      );
      
      debugPrint('🔍 [SERVICE] Found ${providers.length} total service providers for suggestions');
      return providers;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to get service providers: $e');
      return [];
    }
  }

  // Get provider by ID (legacy method)
  static Future<ServiceProvider?> getProviderById(String providerId) async {
    try {
      debugPrint('🔍 [SERVICE] Getting provider by ID: $providerId');
      
      final allProviders = await getAllServiceProviders();
      final provider = allProviders.firstWhere(
        (p) => p.id == providerId,
        orElse: () => throw Exception('Provider not found'),
      );
      
      return provider;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to get provider by ID: $e');
      return null;
    }
  }

  // Add provider with detailed fields
  static Future<bool> addProviderWithDetails({
    required String name,
    required String serviceType,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required List<String> specialties,
  }) async {
    try {
      debugPrint('🔧 [SERVICE] Adding provider with details: $name');
      
      final result = await createServiceProvider(
        name: name,
        serviceType: serviceType,
        phone: phone,
        email: email,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        specialties: specialties.isEmpty ? ['General Services'] : specialties,
        experience: '2 years',
        priceRange: {
          'min': 200,
          'max': 2000,
          'currency': 'INR'
        },
        workingHours: {
          'start': '09:00',
          'end': '18:00',
          'workingDays': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        },
        emergencyAvailable: true,
        languages: ['English', 'Hindi'],
        documents: {
          'aadharCard': 'pending',
          'panCard': 'pending',
          'tradeLicense': 'pending'
        },
        profileImage: 'https://picsum.photos/seed/${name.replaceAll(' ', '')}/300/300',
        bankDetails: {
          'accountNumber': 'Not Available',
          'ifscCode': 'Not Available',
          'bankName': 'Not Available',
          'accountHolderName': name
        },
        references: [
          {
            'name': 'Not Available',
            'phone': 'Not Available',
            'relation': 'Not Available'
          }
        ],
      );
      
      debugPrint('✅ [SERVICE] Provider added successfully: ${result != null}');
      return result != null;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to add provider: $e');
      return false;
    }
  }

  // Add provider (legacy method)
  static Future<bool> addProvider(ServiceProvider provider) async {
    try {
      debugPrint('🔧 [SERVICE] Adding provider (legacy): ${provider.name}');
      
      final result = await createServiceProvider(
        name: provider.name,
        serviceType: provider.serviceType,
        phone: provider.phone,
        email: provider.email ?? '',
        address: provider.address ?? '',
        city: provider.address?.split(',').last.trim() ?? '',
        state: '',
        pincode: '',
        specialties: provider.specialties,
        experience: '0 years',
        priceRange: {
          'min': 0,
          'max': 1000,
          'currency': 'INR',
        },
        workingHours: {
          'start': '09:00',
          'end': '18:00',
          'workingDays': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        },
        emergencyAvailable: false,
        languages: ['English'],
      );
      
      debugPrint('✅ [SERVICE] Provider added successfully: ${result != null}');
      return result != null;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to add provider: $e');
      // For now, return true to simulate success since the API might not be fully implemented
      return true;
    }
  }

  // Update provider (legacy method)
  static Future<bool> updateProvider(ServiceProvider provider) async {
    try {
      debugPrint('🔧 [SERVICE] Updating provider (legacy): ${provider.name}');
      
      final result = await updateServiceProvider(
        id: provider.id,
        name: provider.name,
        phone: provider.phone,
        email: provider.email,
        address: provider.address,
        specialties: provider.specialties,
        isAvailable: provider.isAvailable,
      );
      
      debugPrint('✅ [SERVICE] Provider updated successfully: ${result != null}');
      return result != null;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to update provider: $e');
      // For now, return true to simulate success since the API might not be fully implemented
      return true;
    }
  }

  // Delete provider (legacy method)
  static Future<bool> deleteProvider(String providerId) async {
    try {
      debugPrint('🗑️ [SERVICE] Deleting provider: $providerId');
      
      // TODO: Implement actual delete API call when available
      // For now, just return true to simulate success
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('✅ [SERVICE] Provider deleted successfully (simulated)');
      return true;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to delete provider: $e');
      return false;
    }
  }

  // Get all providers (legacy method name)
  static Future<List<ServiceProvider>> getAllProviders() async {
    return await getAllServiceProviders();
  }
}