import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class SkeletonWidgets {
  // Base shimmer configuration
  static Widget _buildShimmer({
    required Widget child,
    required BuildContext context,
  }) {
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

  // Skeleton container
  static Widget _skeletonContainer({
    required double width,
    required double height,
    double borderRadius = 8,
    Color? color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  // Dashboard header skeleton
  static Widget buildHeaderSkeleton(BuildContext context, bool isMobile) {
    return _buildShimmer(
      context: context,
      child: Row(
        children: [
          // Menu button skeleton
          _skeletonContainer(
            width: isMobile ? 44 : 48,
            height: isMobile ? 44 : 48,
            borderRadius: 12,
          ),
          
          SizedBox(width: isMobile ? 12 : 16),
          
          // Welcome text skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonContainer(
                  width: 120,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                _skeletonContainer(
                  width: 160,
                  height: 18,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          
          // Action buttons skeleton
          Row(
            children: [
              _skeletonContainer(width: 44, height: 44, borderRadius: 12),
              SizedBox(width: isMobile ? 8 : 12),
              _skeletonContainer(width: 44, height: 44, borderRadius: 12),
              SizedBox(width: isMobile ? 8 : 12),
              _skeletonContainer(width: 44, height: 44, borderRadius: 22),
            ],
          ),
        ],
      ),
    );
  }

  // Super card skeleton (main revenue card)
  static Widget buildSuperCardSkeleton(BuildContext context, bool isMobile) {
    return _buildShimmer(
      context: context,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            // Gradient header skeleton
            Container(
              padding: EdgeInsets.all(isMobile ? 28 : 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _skeletonContainer(width: 32, height: 32, borderRadius: 12),
                          const SizedBox(width: 8),
                          _skeletonContainer(width: 100, height: 12, borderRadius: 4),
                        ],
                      ),
                      _skeletonContainer(width: 80, height: 24, borderRadius: 8),
                    ],
                  ),
                  
                  SizedBox(height: isMobile ? 16 : 20),
                  
                  // Revenue amount skeleton
                  _skeletonContainer(
                    width: 200,
                    height: isMobile ? 40 : 48,
                    borderRadius: 8,
                  ),
                  
                  SizedBox(height: isMobile ? 12 : 16),
                  
                  // Subtitle skeleton
                  _skeletonContainer(width: 250, height: 12, borderRadius: 4),
                ],
              ),
            ),
            
            // Floating stats bar skeleton
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Pending dues skeleton
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 20 : 24),
                        child: Column(
                          children: [
                            _skeletonContainer(width: 18, height: 18, borderRadius: 9),
                            const SizedBox(height: 4),
                            _skeletonContainer(width: 60, height: 20, borderRadius: 4),
                            const SizedBox(height: 4),
                            _skeletonContainer(width: 80, height: 10, borderRadius: 4),
                          ],
                        ),
                      ),
                    ),
                    
                    Container(width: 1, height: 105, color: Colors.grey[300]),
                    
                    // Live rooms skeleton
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 20 : 24),
                        child: Column(
                          children: [
                            _skeletonContainer(width: 18, height: 18, borderRadius: 9),
                            const SizedBox(height: 4),
                            _skeletonContainer(width: 40, height: 20, borderRadius: 4),
                            const SizedBox(height: 4),
                            _skeletonContainer(width: 70, height: 10, borderRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Complaint ticker skeleton
            Container(
              height: 112,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Ticker header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 28 : 32,
                      vertical: isMobile ? 12 : 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _skeletonContainer(width: 6, height: 6, borderRadius: 3),
                            const SizedBox(width: 8),
                            _skeletonContainer(width: 120, height: 10, borderRadius: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Ticker content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        children: [
                          _skeletonContainer(width: 100, height: 12, borderRadius: 4),
                          const SizedBox(width: 20),
                          _skeletonContainer(width: 80, height: 12, borderRadius: 4),
                          const SizedBox(width: 20),
                          _skeletonContainer(width: 120, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick actions grid skeleton
  static Widget buildQuickActionsSkeleton(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title skeleton
        _buildShimmer(
          context: context,
          child: _skeletonContainer(
            width: 150,
            height: isMobile ? 18 : 22,
            borderRadius: 4,
          ),
        ),
        
        SizedBox(height: isMobile ? 16 : 20),
        
        // Grid skeleton
        _buildShimmer(
          context: context,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 4,
            childAspectRatio: isMobile ? 1.3 : 1.5,
            mainAxisSpacing: isMobile ? 12 : 16,
            crossAxisSpacing: isMobile ? 12 : 16,
            children: List.generate(8, (index) => _buildActionCardSkeleton(isMobile)),
          ),
        ),
      ],
    );
  }

  // Single action card skeleton
  static Widget _buildActionCardSkeleton(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon skeleton
          _skeletonContainer(
            width: isMobile ? 36 : 40,
            height: isMobile ? 36 : 40,
            borderRadius: 12,
          ),
          
          const Spacer(),
          
          // Title skeleton
          _skeletonContainer(
            width: double.infinity,
            height: isMobile ? 14 : 16,
            borderRadius: 4,
          ),
          
          SizedBox(height: isMobile ? 4 : 6),
          
          // Subtitle skeleton
          _skeletonContainer(
            width: 80,
            height: isMobile ? 11 : 12,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }

  // Recent activity skeleton
  static Widget buildRecentActivitySkeleton(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title skeleton
        _buildShimmer(
          context: context,
          child: _skeletonContainer(
            width: 140,
            height: isMobile ? 18 : 22,
            borderRadius: 4,
          ),
        ),
        
        SizedBox(height: isMobile ? 16 : 20),
        
        // Recent rooms section
        _buildActivitySectionSkeleton(context, isMobile, 'Recent Rooms'),
        
        SizedBox(height: isMobile ? 20 : 24),
        
        // Recent complaints section
        _buildActivitySectionSkeleton(context, isMobile, 'Recent Complaints'),
      ],
    );
  }

  // Activity section skeleton
  static Widget _buildActivitySectionSkeleton(BuildContext context, bool isMobile, String title) {
    return _buildShimmer(
      context: context,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _skeletonContainer(
                  width: 120,
                  height: isMobile ? 16 : 18,
                  borderRadius: 4,
                ),
                _skeletonContainer(
                  width: 60,
                  height: isMobile ? 14 : 16,
                  borderRadius: 4,
                ),
              ],
            ),
            
            SizedBox(height: isMobile ? 12 : 16),
            
            // Activity items
            ...List.generate(3, (index) => Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
              child: _buildActivityItemSkeleton(isMobile),
            )),
          ],
        ),
      ),
    );
  }

  // Activity item skeleton
  static Widget _buildActivityItemSkeleton(bool isMobile) {
    return Row(
      children: [
        // Icon skeleton
        _skeletonContainer(
          width: isMobile ? 40 : 48,
          height: isMobile ? 40 : 48,
          borderRadius: 12,
        ),
        
        SizedBox(width: isMobile ? 12 : 16),
        
        // Content skeleton
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeletonContainer(
                width: double.infinity,
                height: isMobile ? 14 : 16,
                borderRadius: 4,
              ),
              const SizedBox(height: 4),
              _skeletonContainer(
                width: 150,
                height: isMobile ? 12 : 14,
                borderRadius: 4,
              ),
            ],
          ),
        ),
        
        // Value skeleton
        _skeletonContainer(
          width: 60,
          height: isMobile ? 14 : 16,
          borderRadius: 4,
        ),
      ],
    );
  }

  // Complete dashboard skeleton
  static Widget buildDashboardSkeleton(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          buildHeaderSkeleton(context, isMobile),
          
          SizedBox(height: isMobile ? 24 : 32),
          
          // Super card skeleton
          buildSuperCardSkeleton(context, isMobile),
          
          SizedBox(height: isMobile ? 24 : 32),
          
          // Quick actions skeleton
          buildQuickActionsSkeleton(context, isMobile),
          
          SizedBox(height: isMobile ? 24 : 32),
          
          // Recent activity skeleton
          buildRecentActivitySkeleton(context, isMobile),
        ],
      ),
    );
  }

  // Service providers list skeleton
  static Widget buildServiceProvidersListSkeleton(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Column(
      children: [
        // Filter chips skeleton
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildShimmer(
            context: context,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(6, (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _skeletonContainer(
                    width: 80,
                    height: 32,
                    borderRadius: 16,
                  ),
                )),
              ),
            ),
          ),
        ),
        
        // Providers list skeleton
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            itemCount: 6,
            itemBuilder: (context, index) => _buildProviderCardSkeleton(context, isMobile),
          ),
        ),
      ],
    );
  }

  // Service provider card skeleton
  static Widget _buildProviderCardSkeleton(BuildContext context, bool isMobile) {
    return _buildShimmer(
      context: context,
      child: Container(
        margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon skeleton
            _skeletonContainer(
              width: isMobile ? 56 : 64,
              height: isMobile ? 56 : 64,
              borderRadius: 12,
            ),
            
            SizedBox(width: isMobile ? 12 : 16),
            
            // Details skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonContainer(
                    width: double.infinity,
                    height: isMobile ? 16 : 18,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 4),
                  _skeletonContainer(
                    width: 120,
                    height: isMobile ? 13 : 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _skeletonContainer(width: 16, height: 16, borderRadius: 8),
                      const SizedBox(width: 4),
                      _skeletonContainer(width: 30, height: 14, borderRadius: 4),
                      const SizedBox(width: 8),
                      _skeletonContainer(width: 60, height: 12, borderRadius: 4),
                      const SizedBox(width: 8),
                      _skeletonContainer(width: 60, height: 16, borderRadius: 8),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _skeletonContainer(width: 14, height: 14, borderRadius: 7),
                      const SizedBox(width: 4),
                      _skeletonContainer(width: 100, height: 12, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action buttons skeleton
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _skeletonContainer(width: 40, height: 40, borderRadius: 20),
                const SizedBox(height: 8),
                _skeletonContainer(width: 40, height: 40, borderRadius: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Animated skeleton with pulse effect
  static Widget buildAnimatedSkeleton({
    required Widget child,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: 0.3, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: _buildShimmer(context: context, child: child!),
          ),
        );
      },
      child: child,
    );
  }
}