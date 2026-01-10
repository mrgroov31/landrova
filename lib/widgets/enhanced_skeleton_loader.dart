import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class EnhancedSkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration animationDuration;
  final String? loadingMessage;
  final bool showHiveHint;

  const EnhancedSkeletonLoader({
    super.key,
    required this.child,
    required this.isLoading,
    this.animationDuration = const Duration(milliseconds: 300),
    this.loadingMessage,
    this.showHiveHint = true,
  });

  @override
  State<EnhancedSkeletonLoader> createState() => _EnhancedSkeletonLoaderState();
}

class _EnhancedSkeletonLoaderState extends State<EnhancedSkeletonLoader>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    if (!widget.isLoading) {
      _fadeController.forward();
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedSkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _fadeController.reverse();
        _scaleController.reverse();
      } else {
        _fadeController.forward();
        _scaleController.forward();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Skeleton loading overlay
        if (widget.isLoading)
          Positioned.fill(
            child: _buildSkeletonOverlay(),
          ),
        
        // Actual content with fade/scale animation
        AnimatedBuilder(
          animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: widget.child,
              ),
            );
          },
        ),
        
        // Loading message overlay
        if (widget.isLoading && widget.loadingMessage != null)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: _buildLoadingMessage(),
          ),
      ],
    );
  }

  Widget _buildSkeletonOverlay() {
    return Container(
      color: AppTheme.getBackgroundColor(context),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.grey[300]!,
        highlightColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700]!
            : Colors.grey[100]!,
        period: const Duration(milliseconds: 1500),
        child: widget.child,
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated loading indicator
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.3),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cached,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Loading message
            Text(
              widget.loadingMessage!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Hive hint
            if (widget.showHiveHint) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Icon(
                      Icons.storage,
                      size: 10,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Powered by Hive database',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getTextSecondaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Skeleton shimmer effect widget
class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

// Skeleton box widget
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Skeleton text widget
class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 14,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: 4,
      margin: margin,
    );
  }
}

// Skeleton circle widget
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    super.key,
    required this.size,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      borderRadius: size / 2,
      margin: margin,
    );
  }
}

// Skeleton list tile widget
class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final bool hasSubtitle;

  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.hasSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          // Leading
          if (hasLeading) ...[
            const SkeletonCircle(size: 48),
            const SizedBox(width: 16),
          ],
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: double.infinity, height: 16),
                if (hasSubtitle) ...[
                  const SizedBox(height: 8),
                  const SkeletonText(width: 200, height: 14),
                ],
              ],
            ),
          ),
          
          // Trailing
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            const SkeletonBox(width: 60, height: 32, borderRadius: 16),
          ],
        ],
      ),
    );
  }
}

// Skeleton card widget
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}