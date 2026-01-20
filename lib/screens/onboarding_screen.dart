import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'unified_login_screen.dart';
// Import math for trigonometric functions
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    _floatingController.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const UnifiedLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Smart Property\nManagement',
      subtitle: 'Streamline your property operations with our comprehensive management platform',
      icon: Icons.home_work_rounded,
      primaryColor: AppTheme.primaryColor,
      secondaryColor: AppTheme.primaryColor.withOpacity(0.7),
      features: [
        OnboardingFeature(
          icon: Icons.people_rounded,
          label: 'Tenant\nManagement',
          color: Colors.blue.shade400,
        ),
        OnboardingFeature(
          icon: Icons.build_rounded,
          label: 'Maintenance\nTracking',
          color: Colors.orange.shade400,
        ),
        OnboardingFeature(
          icon: Icons.analytics_rounded,
          label: 'Analytics &\nReports',
          color: Colors.green.shade400,
        ),
        OnboardingFeature(
          icon: Icons.payment_rounded,
          label: 'Payment\nProcessing',
          color: Colors.purple.shade400,
        ),
      ],
    ),
    OnboardingData(
      title: 'Seamless Tenant\nOnboarding',
      subtitle: 'Digital documentation and instant communication for smooth tenant experiences',
      icon: Icons.person_add_rounded,
      primaryColor: AppTheme.secondaryColor,
      secondaryColor: AppTheme.secondaryColor.withOpacity(0.7),
      features: [
        OnboardingFeature(
          icon: Icons.qr_code_rounded,
          label: 'QR Code\nInvitations',
          color: Colors.indigo.shade400,
        ),
        OnboardingFeature(
          icon: Icons.description_rounded,
          label: 'Digital\nContracts',
          color: Colors.teal.shade400,
        ),
        OnboardingFeature(
          icon: Icons.camera_alt_rounded,
          label: 'Document\nCapture',
          color: Colors.pink.shade400,
        ),
        OnboardingFeature(
          icon: Icons.notifications_active_rounded,
          label: 'Real-time\nNotifications',
          color: Colors.amber.shade400,
        ),
      ],
    ),
    OnboardingData(
      title: 'Advanced\nCommunication',
      subtitle: 'Stay connected with tenants and service providers through integrated messaging',
      icon: Icons.forum_rounded,
      primaryColor: const Color(0xFF00BCD4),
      secondaryColor: const Color(0xFF00BCD4).withOpacity(0.7),
      features: [
        OnboardingFeature(
          icon: Icons.chat_rounded,
          label: 'Instant\nMessaging',
          color: Colors.cyan.shade400,
        ),
        OnboardingFeature(
          icon: Icons.emergency_rounded,
          label: 'Emergency\nAlerts',
          color: Colors.red.shade400,
        ),
        OnboardingFeature(
          icon: Icons.schedule_rounded,
          label: 'Appointment\nScheduling',
          color: Colors.blue.shade400,
        ),
        OnboardingFeature(
          icon: Icons.star_rounded,
          label: 'Service\nRatings',
          color: Colors.yellow.shade600,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background with animated gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _onboardingData[_currentPage].primaryColor,
                  _onboardingData[_currentPage].secondaryColor,
                  _onboardingData[_currentPage].primaryColor.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Floating background elements
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                final offset = _floatingAnimation.value * (index + 1) * 0.1;
                return Positioned(
                  top: size.height * (0.1 + index * 0.12) + (offset * 50),
                  left: size.width * (0.1 + (index % 2) * 0.8) - (offset * 30),
                  child: Opacity(
                    opacity: 0.1,
                    child: Transform.rotate(
                      angle: offset * 2,
                      child: Container(
                        width: 40 + (index * 10),
                        height: 40 + (index * 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // Main content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                data: _onboardingData[index],
                isActive: index == _currentPage,
                fadeAnimation: _fadeAnimation,
                slideAnimation: _slideAnimation,
                floatingAnimation: _floatingAnimation,
              );
            },
          ),
          
          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: TextButton(
                onPressed: _completeOnboarding,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom section with indicators and buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 32,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 32 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      Row(
                        children: [
                          if (_currentPage > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Previous',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          
                          if (_currentPage > 0) const SizedBox(width: 16),
                          
                          Expanded(
                            flex: _currentPage == 0 ? 1 : 2,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_currentPage == _onboardingData.length - 1) {
                                  _completeOnboarding();
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _onboardingData[_currentPage].primaryColor,
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _currentPage == _onboardingData.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Sign in link
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Already have an account? Sign In',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final bool isActive;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> floatingAnimation;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.isActive,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.floatingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 80),
            
            // App branding
            FadeTransition(
              opacity: fadeAnimation,
              child: Text(
                'OwnHouse',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Main illustration area
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Feature bubbles
                  ...data.features.asMap().entries.map((entry) {
                    final index = entry.key;
                    final feature = entry.value;
                    final angle = (index * 90.0) * (3.14159 / 180);
                    final radius = 120.0;
                    
                    return AnimatedBuilder(
                      animation: floatingAnimation,
                      builder: (context, child) {
                        final offset = floatingAnimation.value * 10;
                        return AnimatedPositioned(
                          duration: Duration(milliseconds: 600 + (index * 100)),
                          curve: Curves.elasticOut,
                          left: size.width / 2 + (radius * cos(angle)) - 40 + offset,
                          top: size.height * 0.35 + (radius * sin(angle)) - 40 - offset,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 800),
                            opacity: isActive ? 1.0 : 0.0,
                            child: FeatureWidget(feature: feature),
                          ),
                        );
                      },
                    );
                  }),
                  
                  // Central icon
                  AnimatedScale(
                    duration: const Duration(milliseconds: 800),
                    scale: isActive ? 1.0 : 0.8,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: data.primaryColor.withOpacity(0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  data.primaryColor.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            data.icon,
                            size: 60,
                            color: data.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Text content
            Expanded(
              flex: 2,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 200), // Space for bottom controls
          ],
        ),
      ),
    );
  }
}

class FeatureWidget extends StatelessWidget {
  final OnboardingFeature feature;

  const FeatureWidget({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: feature.color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              feature.icon,
              size: 24,
              color: feature.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feature.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: feature.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<OnboardingFeature> features;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.features,
  });
}

class OnboardingFeature {
  final IconData icon;
  final String label;
  final Color color;

  OnboardingFeature({
    required this.icon,
    required this.label,
    required this.color,
  });
}

// Helper function for positioning
double cos(double angle) => math.cos(angle);
double sin(double angle) => math.sin(angle);

