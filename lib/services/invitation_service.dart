import 'dart:math';
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
  static String generateInvitationLink(String token, {String? roomNumber}) {
    final baseUrl = 'ownhouse://tenant/register?token=$token';
    if (roomNumber != null) {
      return '$baseUrl&room=$roomNumber';
    }
    return baseUrl;
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
    
    try {
      final uri = Uri.parse(link);
      params['token'] = uri.queryParameters['token'] ?? '';
      params['room'] = uri.queryParameters['room'] ?? '';
    } catch (e) {
      // Handle parsing error
    }
    
    return params;
  }
}

