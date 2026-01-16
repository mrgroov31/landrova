import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/custom_page_route.dart';
import 'owner_upi_management_screen.dart';
import 'profile_screen.dart';
import 'unified_login_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROFILE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            Text(
              'Thomas Anderson',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.getBackgroundColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _buildProfileCard(context, isMobile),
            
            SizedBox(height: isMobile ? 24 : 32),
            
            // Appearance Section
            _buildSectionHeader(context, 'APPEARANCE', isMobile),
            SizedBox(height: isMobile ? 12 : 16),
            _buildAppearanceSection(context, isMobile, themeService),
            
            SizedBox(height: isMobile ? 24 : 32),
            
            // Finance & UPI Section
            _buildSectionHeader(context, 'FINANCE & UPI', isMobile),
            SizedBox(height: isMobile ? 12 : 16),
            _buildFinanceSection(context, isMobile),
            
            SizedBox(height: isMobile ? 24 : 32),
            
            // Account Control Section
            _buildSectionHeader(context, 'ACCOUNT CONTROL', isMobile),
            SizedBox(height: isMobile ? 12 : 16),
            _buildAccountSection(context, isMobile),
            
            SizedBox(height: isMobile ? 32 : 40),
            
            // Logout Button
            _buildLogoutButton(context, isMobile),
            
            SizedBox(height: isMobile ? 24 : 32),
            
            // App Version
            Center(
              child: Text(
                'PROPMANAGER V2.4.9 (BUILD 982)',
                style: TextStyle(
                  color: AppTheme.getTextSecondaryColor(context).withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              Container(
                width: isMobile ? 64 : 72,
                height: isMobile ? 64 : 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFBBDEFB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person,
                  size: isMobile ? 32 : 40,
                  color: const Color(0xFF2196F3),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.getCardColor(context),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: isMobile ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thomas Anderson',
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(context),
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Premium Owner Plan',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppTheme.getTextSecondaryColor(context),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context, bool isMobile, ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          _buildThemeTile(
            context,
            icon: Icons.light_mode,
            iconColor: const Color(0xFFFFA726),
            iconBgColor: const Color(0xFFFFA726).withOpacity(0.1),
            title: 'Light Mode',
            isSelected: themeService.themeMode == AppThemeMode.light,
            onTap: () => themeService.setThemeMode(AppThemeMode.light),
            isMobile: isMobile,
          ),
          Divider(
            height: 1,
            color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
          ),
          _buildThemeTile(
            context,
            icon: Icons.dark_mode,
            iconColor: const Color(0xFF5C6BC0),
            iconBgColor: const Color(0xFF5C6BC0).withOpacity(0.1),
            title: 'Dark Mode',
            isSelected: themeService.themeMode == AppThemeMode.dark,
            onTap: () => themeService.setThemeMode(AppThemeMode.dark),
            isMobile: isMobile,
          ),
          Divider(
            height: 1,
            color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
          ),
          _buildThemeTile(
            context,
            icon: Icons.brightness_auto,
            iconColor: const Color(0xFF26A69A),
            iconBgColor: const Color(0xFF26A69A).withOpacity(0.1),
            title: 'System Default',
            isSelected: themeService.themeMode == AppThemeMode.system,
            onTap: () => themeService.setThemeMode(AppThemeMode.system),
            isMobile: isMobile,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isMobile,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isLast ? 20 : 0),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 16 : 18,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              SizedBox(width: isMobile ? 14 : 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(context),
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 24,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: AppTheme.getTextSecondaryColor(context).withOpacity(0.3),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isMobile) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.getTextSecondaryColor(context),
        fontSize: isMobile ? 11 : 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildFinanceSection(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.qr_code_2,
            iconColor: const Color(0xFF4CAF50),
            iconBgColor: const Color(0xFF4CAF50).withOpacity(0.1),
            title: 'UPI Settings',
            subtitle: 'thomas@upi • Verified',
            onTap: () {
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const OwnerUpiManagementScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            },
            isMobile: isMobile,
          ),
          Divider(
            height: 1,
            color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.account_balance,
            iconColor: const Color(0xFF2196F3),
            iconBgColor: const Color(0xFF2196F3).withOpacity(0.1),
            title: 'Bank Accounts',
            subtitle: 'HDFC Bank • • • • 4492',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bank accounts coming soon!')),
              );
            },
            isMobile: isMobile,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            iconColor: const Color(0xFF9C27B0),
            iconBgColor: const Color(0xFF9C27B0).withOpacity(0.1),
            title: 'Profile Details',
            subtitle: 'Contact Information',
            onTap: () {
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const ProfileScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            },
            isMobile: isMobile,
          ),
          Divider(
            height: 1,
            color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            iconColor: const Color(0xFFFF9800),
            iconBgColor: const Color(0xFFFF9800).withOpacity(0.1),
            title: 'Security',
            subtitle: 'Biometrics & 2FA',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings coming soon!')),
              );
            },
            isMobile: isMobile,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isMobile,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isLast ? 20 : 0),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 16 : 18,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              SizedBox(width: isMobile ? 14 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.getTextSecondaryColor(context).withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isMobile) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          _showLogoutDialog(context);
        },
        icon: const Icon(
          Icons.logout,
          color: Color(0xFFEF5350),
          size: 20,
        ),
        label: Text(
          'LOG OUT FROM APP',
          style: TextStyle(
            color: const Color(0xFFEF5350),
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 32,
            vertical: isMobile ? 14 : 16,
          ),
          backgroundColor: const Color(0xFFEF5350).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
