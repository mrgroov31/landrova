import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class InvitationService {
  // Generate a unique invitation token
  static String generateInvitationToken() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        32,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Generate invitation link
  static String generateInvitationLink(String token, {String? roomNumber, String? buildingId, String? roomId}) {
    final baseUrl = 'ownhouse://tenant/register?token=$token';
    String link = baseUrl;
    
    // Prioritize roomId if provided, otherwise use roomNumber + buildingId
    if (roomId != null) {
      link = '$link&roomId=$roomId';
    } else {
      if (buildingId != null) {
        link = '$link&buildingId=$buildingId';
      }
      if (roomNumber != null) {
        link = '$link&room=$roomNumber';
      }
    }
    
    debugPrint('');
    debugPrint('🔗 ===== INVITATION LINK GENERATION =====');
    debugPrint('🔗 [GENERATE] Token: $token');
    debugPrint('🔗 [GENERATE] Room ID: $roomId');
    debugPrint('🔗 [GENERATE] Room Number: $roomNumber');
    debugPrint('🔗 [GENERATE] Building ID: $buildingId');
    debugPrint('🔗 [GENERATE] Generated Link: $link');
    debugPrint('🔗 ===== INVITATION LINK GENERATION END =====');
    debugPrint('');
    
    return link;
  }

  // Share invitation link
  static Future<void> shareInvitationLink(String link, String tenantName) async {
    final message = '''
Hi $tenantName,

You've been invited to register as a tenant in our property management system.

Please click the link below to complete your registration:
$link

Thank you!
''';
    
    await Share.share(
      message,
      subject: 'Tenant Registration Invitation',
    );
  }

  // Parse invitation link parameters
  static Map<String, String> parseInvitationLink(String link) {
    final params = <String, String>{};
    
    debugPrint('');
    debugPrint('🔗 ===== INVITATION LINK PARSING =====');
    debugPrint('🔗 [PARSE] Input Link: $link');
    
    try {
      final uri = Uri.parse(link);
      debugPrint('🔗 [PARSE] Parsed URI: $uri');
      debugPrint('🔗 [PARSE] Query Parameters: ${uri.queryParameters}');
      
      params['token'] = uri.queryParameters['token'] ?? '';
      params['room'] = uri.queryParameters['room'] ?? '';
      params['buildingId'] = uri.queryParameters['buildingId'] ?? '';
      params['roomId'] = uri.queryParameters['roomId'] ?? '';
      
      debugPrint('🔗 [PARSE] Extracted token: ${params['token']}');
      debugPrint('🔗 [PARSE] Extracted room: ${params['room']}');
      debugPrint('🔗 [PARSE] Extracted buildingId: ${params['buildingId']}');
      debugPrint('🔗 [PARSE] Extracted roomId: ${params['roomId']}');
    } catch (e) {
      debugPrint('❌ [PARSE] Error parsing link: $e');
    }
    
    debugPrint('🔗 [PARSE] Final params: $params');
    debugPrint('🔗 ===== INVITATION LINK PARSING END =====');
    debugPrint('');
    
    return params;
  }
}

