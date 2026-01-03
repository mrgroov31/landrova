import 'package:flutter/material.dart';

/// Custom page route with transform animations
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final CustomPageTransition transition;

  CustomPageRoute({
    required this.child,
    this.transition = CustomPageTransition.transform, // Changed default to transform
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: transition == CustomPageTransition.transform 
              ? const Duration(milliseconds: 350) // Faster transform
              : transition == CustomPageTransition.containerTransform
                  ? const Duration(milliseconds: 400) // Container transform
                  : const Duration(milliseconds: 300),
          reverseTransitionDuration: transition == CustomPageTransition.transform
              ? const Duration(milliseconds: 200) // Faster reverse too
              : transition == CustomPageTransition.containerTransform
                  ? const Duration(milliseconds: 300) // Container transform reverse
                  : const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(animation, secondaryAnimation, child, transition);
          },
        );

  static Widget _buildTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    CustomPageTransition transition,
  ) {
    switch (transition) {
      case CustomPageTransition.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case CustomPageTransition.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case CustomPageTransition.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case CustomPageTransition.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case CustomPageTransition.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case CustomPageTransition.rotate:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.5,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );

      case CustomPageTransition.slideScale:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );

      case CustomPageTransition.transform:
        // Smooth scale zoom that goes directly to final position without overshoot
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.85, // Start slightly smaller
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic, // Smooth curve without bounce
          )),
          alignment: Alignment.center,
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut, // Smooth fade
            )),
            child: child,
          ),
        );

      case CustomPageTransition.containerTransform:
        // Container transform animation - expands from card to full screen
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            alignment: Alignment.topCenter,
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          ),
        );
    }
  }
}

/// Types of page transitions available
enum CustomPageTransition {
  slideRight, // Default: slides from right
  slideLeft,  // Slides from left
  slideUp,    // Slides from bottom
  scale,      // Scales up from center
  fade,       // Simple fade
  rotate,     // Rotates while scaling
  slideScale, // Slides up with scale (modern iOS-like)
  transform,  // Button transforms to screen (dramatic scale from small to full)
  containerTransform, // Container transform (Material Design shared element)
}

