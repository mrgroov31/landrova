class ApiConfig {
  // Base URL for all API calls
  static const String baseUrl = 'https://www.leranothrive.com/api';
  
  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Fallback configuration
  static const bool enableMockFallback = true;
}

// API endpoints helper class
class ApiEndpoints {
  static String rooms(String ownerId) => '${ApiConfig.baseUrl}/owners/$ownerId/rooms';
  static String tenants(String ownerId) => '${ApiConfig.baseUrl}/owners/$ownerId/tenants';
  static String buildings(String ownerId) => '${ApiConfig.baseUrl}/buildings?ownerId=$ownerId';
  static String complaints(String ownerId) => '${ApiConfig.baseUrl}/complaints?ownerId=$ownerId';
  static String get serviceProviders => '${ApiConfig.baseUrl}/service-providers';
  static String get payments => '${ApiConfig.baseUrl}/payments';
  static String ownerUpi(String ownerId) => '${ApiConfig.baseUrl}/owners/$ownerId/upi-details';
}