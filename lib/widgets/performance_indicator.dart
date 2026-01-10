import 'package:flutter/material.dart';
import '../services/optimized_api_service.dart';
import '../services/hive_api_service.dart';
import '../services/preloader_service.dart';

class PerformanceIndicator extends StatefulWidget {
  final Widget child;
  final bool showDebugInfo;

  const PerformanceIndicator({
    super.key,
    required this.child,
    this.showDebugInfo = false,
  });

  @override
  State<PerformanceIndicator> createState() => _PerformanceIndicatorState();
}

class _PerformanceIndicatorState extends State<PerformanceIndicator> {
  Map<String, dynamic>? _cacheStats;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    if (widget.showDebugInfo) {
      _loadCacheStats();
    }
  }

  void _loadCacheStats() {
    setState(() {
      _cacheStats = PreloaderService.getPerformanceMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Debug info overlay
        if (widget.showDebugInfo)
          Positioned(
            top: 100,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showStats = !_showStats;
                });
                _loadCacheStats();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.speed,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        
        // Stats overlay
        if (_showStats && _cacheStats != null)
          Positioned(
            top: 140,
            right: 16,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚡ Hive Performance Stats',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Hive cache info
                  if (_cacheStats!['hiveStats'] != null) ...[
                    Text(
                      'Hive Cache Stats:',
                      style: const TextStyle(color: Colors.yellow, fontSize: 10),
                    ),
                    ...(_cacheStats!['hiveStats']['hiveCacheStats'] as Map<String, dynamic>).entries.map(
                      (entry) => Text(
                        '• ${entry.key}: ${entry.value} entries',
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Memory cache info
                  Text(
                    'Memory Cache: ${(_cacheStats!['hiveStats']['memoryCacheSize'] ?? 0)} items',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  
                  // Ongoing requests
                  Text(
                    'Active Requests: ${(_cacheStats!['hiveStats']['ongoingRequests'] as List).length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Status indicators
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _cacheStats!['isInitialized'] == true ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Initialized',
                        style: TextStyle(color: Colors.white, fontSize: 9),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _cacheStats!['isPreloading'] == true ? Colors.orange : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Ready',
                        style: TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Refresh button
                  GestureDetector(
                    onTap: _loadCacheStats,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: const Text(
                        'Refresh Stats',
                        style: TextStyle(color: Colors.green, fontSize: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Loading indicator with performance hints
class FastLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool showCacheHint;

  const FastLoadingIndicator({
    super.key,
    this.message,
    this.showCacheHint = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 3,
                  value: showCacheHint ? null : value,
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Loading message
          Text(
            message ?? 'Loading...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Cache hint
          if (showCacheHint) ...[
            const SizedBox(height: 8),
            const Text(
              '⚡ Using Hive database for lightning-fast loading',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}