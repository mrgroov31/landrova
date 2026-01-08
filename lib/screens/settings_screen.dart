import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
            SizedBox(height: isMobile ? 16 : 20),
            _buildThemeSelector(context, isMobile),
            
            SizedBox(height: isMobile ? 32 : 40),
            
            // App Section
            _buildSectionHeader(context, 'App Settings', Icons.settings_outlined),
            SizedBox(height: isMobile ? 16 : 20),
            _buildAppSettings(context, isMobile),
            
            SizedBox(height: isMobile ? 32 : 40),
            
            // About Section
            _buildSectionHeader(context, 'About', Icons.info_outline),
            SizedBox(height: isMobile ? 16 : 20),
            _buildAboutSection(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.getTextPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, bool isMobile) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Current Theme Display
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.secondaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isMobile ? 48 : 56,
                      height: isMobile ? 48 : 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        themeService.themeModeIcon,
                        color: AppTheme.primaryColor,
                        size: isMobile ? 24 : 28,
                      ),
                    ),
                    SizedBox(width: isMobile ? 16 : 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Theme',
                            style: TextStyle(
                              color: AppTheme.getTextSecondaryColor(context),
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            themeService.themeModeString,
                            style: TextStyle(
                              color: AppTheme.getTextPrimaryColor(context),
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Theme Options
              ...AppThemeMode.values.map((mode) {
                final isSelected = themeService.themeMode == mode;
                final isLast = mode == AppThemeMode.values.last;
                
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade100,
                      ),
                    ),
                    borderRadius: isLast ? const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ) : null,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 20,
                      vertical: isMobile ? 8 : 12,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getThemeModeIcon(mode),
                        color: isSelected 
                            ? AppTheme.primaryColor
                            : AppTheme.getTextSecondaryColor(context),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      _getThemeModeString(mode),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _getThemeModeDescription(mode),
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                            size: 24,
                          )
                        : null,
                    onTap: () {
                      themeService.setThemeMode(mode);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppSettings(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              // TODO: Navigate to notifications settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings coming soon!'),
                ),
              );
            },
            isMobile: isMobile,
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English (US)',
            onTap: () {
              // TODO: Navigate to language settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language settings coming soon!'),
                ),
              );
            },
            isMobile: isMobile,
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () {
              // TODO: Navigate to privacy settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy settings coming soon!'),
                ),
              );
            },
            isMobile: isMobile,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0 (Build 1)',
            onTap: null,
            isMobile: isMobile,
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              // TODO: Navigate to help
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support coming soon!'),
                ),
              );
            },
            isMobile: isMobile,
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms & Privacy',
            subtitle: 'Read our terms and privacy policy',
            onTap: () {
              // TODO: Navigate to terms
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms & Privacy coming soon!'),
                ),
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
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isMobile,
    bool isLast = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 8 : 12,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.getTextPrimaryColor(context),
          fontSize: isMobile ? 16 : 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.getTextSecondaryColor(context),
          fontSize: isMobile ? 12 : 14,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: AppTheme.getTextSecondaryColor(context),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.shade100,
    );
  }

  IconData _getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeModeString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Default';
    }
  }

  String _getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system settings';
    }
  }
}