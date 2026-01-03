import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'owner_login_screen.dart';
import 'tenant_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isMobile ? 40 : 60),
              
              // Logo/Icon
              Container(
                width: isMobile ? 100 : 120,
                height: isMobile ? 100 : 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home,
                  size: isMobile ? 60 : 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              SizedBox(height: isMobile ? 32 : 40),
              
              // App Name
              Text(
                'OwnHouse',
                style: TextStyle(
                  fontSize: isMobile ? 32 : 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              
              SizedBox(height: isMobile ? 8 : 12),
              
              Text(
                'Property Management System',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  color: Colors.grey.shade600,
                ),
              ),
              
              SizedBox(height: isMobile ? 48 : 64),
              
              // Role Selection Title
              Text(
                'Login as',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              // Owner Login Card
              _buildRoleCard(
                context: context,
                title: 'Property Owner',
                subtitle: 'Manage your properties, tenants, and payments',
                icon: Icons.business,
                color: AppTheme.primaryColor,
                isMobile: isMobile,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OwnerLoginScreen(),
                    ),
                  );
                },
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              // Tenant Login Card
              _buildRoleCard(
                context: context,
                title: 'Tenant',
                subtitle: 'Access your room details and submit complaints',
                icon: Icons.person,
                color: Colors.green,
                isMobile: isMobile,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TenantLoginScreen(),
                    ),
                  );
                },
              ),
              
              SizedBox(height: isMobile ? 32 : 40),
              
              // Demo Credentials Info
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Demo Credentials',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCredentialRow('Owner:', 'owner@ownhouse.com / owner123', isMobile),
                    const SizedBox(height: 8),
                    _buildCredentialRow('Tenant:', 'Use registered tenant email / tenant123', isMobile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: isMobile ? 32 : 40,
                color: color,
              ),
            ),
            SizedBox(width: isMobile ? 16 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: isMobile ? 18 : 20,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 60 : 70,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
              fontSize: isMobile ? 12 : 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: isMobile ? 12 : 13,
            ),
          ),
        ),
      ],
    );
  }
}

