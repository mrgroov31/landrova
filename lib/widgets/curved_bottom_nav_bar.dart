import 'package:flutter/material.dart';
import 'dart:ui';

class CurvedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<CurvedNavBarItem> items;

  const CurvedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Curved background
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 20, 85),
            painter: CurvedPainter(),
          ),
          // Navigation items
          SizedBox(
            width: MediaQuery.of(context).size.width - 20,
            height: 85,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = currentIndex == index;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 85,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? item.activeColor.withOpacity(0.15)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? item.activeColor
                                  : Colors.grey.shade600,
                              size: isSelected ? 26 : 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: isSelected ? 12 : 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? item.activeColor
                                  : Colors.grey.shade600,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color activeColor;

  const CurvedNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.activeColor,
  });
}

class CurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Start from left bottom
    path.moveTo(0, size.height);
    
    // Draw left curve - smooth transition
    path.quadraticBezierTo(
      size.width * 0.08,
      size.height,
      size.width * 0.12,
      size.height * 0.75,
    );
    
    // Draw left upward curve
    path.quadraticBezierTo(
      size.width * 0.18,
      size.height * 0.4,
      size.width * 0.25,
      size.height * 0.25,
    );
    
    // Draw center curve (the notch) - more pronounced
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.05,
      size.width * 0.5,
      size.height * 0.12,
    );
    
    // Draw right curve (mirror of left)
    path.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.05,
      size.width * 0.75,
      size.height * 0.25,
    );
    
    path.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.4,
      size.width * 0.88,
      size.height * 0.75,
    );
    
    // Draw right curve
    path.quadraticBezierTo(
      size.width * 0.92,
      size.height,
      size.width,
      size.height,
    );
    
    // Close the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow first (below)
    final shadowPath = Path()
      ..addPath(path, Offset.zero)
      ..addPath(path, const Offset(0, 2));
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw main shape
    canvas.drawPath(path, paint);
    
    // Add subtle border
    final borderPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

