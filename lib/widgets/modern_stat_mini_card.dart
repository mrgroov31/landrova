import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import '../utils/responsive.dart';

class ModernStatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? imageUri; // Network image URI
  final String? lottieUri; // Lottie animation URI
  final String? subtitle;
  final bool showTrend;
  final String? heroTag; // Hero tag for shared element transition

  const ModernStatMiniCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
    this.imageUri,
    this.lottieUri,
    this.subtitle,
    this.showTrend = false,
    this.heroTag,
  }) : assert(
          icon != null || imageUri != null || lottieUri != null,
          'Either icon, imageUri, or lottieUri must be provided',
        );

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    Widget cardContent = Container(
        height: isMobile ? 160 : 200, // Increased fixed height for all cards
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              (color ?? Colors.blue).withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (color ?? Colors.blue).withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (color ?? Colors.blue).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Header with icon/image/animation
            // On mobile, just show icon. On larger screens, show icon + trend
            isMobile
                ? Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (color ?? Colors.blue).withOpacity(0.15),
                          (color ?? Colors.blue).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildIconWidget(isMobile),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (color ?? Colors.blue).withOpacity(0.15),
                              (color ?? Colors.blue).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildIconWidget(isMobile),
                      ),
                      if (showTrend)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 12,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '+12%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
            SizedBox(height: isMobile ? 10 : 16),
            // Value
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 4 : 6),
            // Title
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Subtitle (optional)
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      );

    if (heroTag != null && onTap != null) {
      return Hero(
        tag: heroTag!,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: onTap,
            child: cardContent,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: cardContent,
    );
  }

  Widget _buildIconWidget(bool isMobile) {
    final iconSize = isMobile ? 36.0 : 56.0;
    // Priority: Lottie > Image > Icon
    if (lottieUri != null && lottieUri!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Lottie.network(
          lottieUri!,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon(isMobile);
          },
        ),
      );
    } else if (imageUri != null && imageUri!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUri!,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: (color ?? Colors.blue).withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Colors.blue,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackIcon(isMobile),
        ),
      );
    } else {
      return _buildFallbackIcon(isMobile);
    }
  }

  Widget _buildFallbackIcon(bool isMobile) {
    return Center(
      child: Icon(
        icon ?? Icons.info_outline,
        color: color ?? Colors.blue,
        size: isMobile ? 20 : 32,
      ),
    );
  }
}
