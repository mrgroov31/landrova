import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class HeroSection extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final VoidCallback? onSearchTap;

  const HeroSection({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: isMobile ? 16 : 18,
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 14 : 18,
              ),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2)),
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
                  Icon(
                    Icons.search,
                    color: AppTheme.getTextSecondaryColor(context),
                    size: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search rooms, tenants, or payments',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: AppTheme.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.tune,
                    color: AppTheme.getTextSecondaryColor(context),
                    size: isMobile ? 20 : 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

