import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'unified_login_screen.dart';

class AdvancedOnboardingScreen extends StatefulWidget {
  const AdvancedOnboardingScreen({super.key});

  @override
  State<AdvancedOnboardingScreen> createState() => _AdvancedOnboardingScreenState();
}

class _AdvancedOnboardingScreenState extends State<AdvancedOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _backgroundAnimation;
  late List<AnimationController> _featureAnimationControllers;

  @override
  void initState() {
    super.initState();
    
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    )..repeat();
    
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _backgroundAnimationController,
    );
    
    // Create animation controllers for each feature
    _featureAnimationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 200)),
        vsync: this,
      ),
    );
    
    _contentAnimationController.forward();
    _animateFeatures();
  }

  void _animateFeatures() {
    for (int i = 0; i < _featureAnimationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _featureAnimationControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _contentAnimationController.dispose();
    for (var controller in _featureAnimationControllers) {
      controller.dispose();
    }
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
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    
    // Reset and restart feature animations
    for (var controller in _featureAnimationControllers) {
      controller.reset();
    }
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _animateFeatures();
    });
  }

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Property\nManagement\nMade Easy',
      subtitle: 'Manage your properties, tenants,\nand maintenance all in one place',
      primaryColor: const Color(0xFF4CAF50),
      secondaryColor: const Color(0xFF66BB6A),
      icon: FontAwesomeIcons.house,
      features: [
        FeatureData(
          icon: FontAwesomeIcons.users,
          label: 'Tenant\nManagement',
          color: const Color(0xFF2196F3),
        ),
        FeatureData(
          icon: FontAwesomeIcons.wrench,
          label: 'Maintenance\nRequests',
          color: const Color(0xFFFF9800),
        ),
        FeatureData(
          icon: FontAwesomeIcons.chartLine,
          label: 'Analytics\n& Reports',
          color: const Color(0xFF9C27B0),
        ),
        FeatureData(
          icon: FontAwesomeIcons.creditCard,
          label: 'Payment\nTracking',
          color: const Color(0xFFF44336),
        ),
      ],
    ),
    OnboardingPageData(
      title: 'Smart Tenant\nOnboarding',
      subtitle: 'Seamlessly onboard new tenants\nwith digital documentation',
      primaryColor: const Color(0xFF2196F3),
      secondaryColor: const Color(0xFF42A5F5),
      icon: FontAwesomeIcons.userPlus,
      features: [
        FeatureData(
          icon: FontAwesomeIcons.qrcode,
          label: 'QR Code\nInvitations',
          color: const Color(0xFF4CAF50),
        ),
        FeatureData(
          icon: FontAwesomeIcons.fileContract,
          label: 'Digital\nContracts',
          color: const Color(0xFFFF9800),
        ),
        FeatureData(
          icon: FontAwesomeIcons.camera,
          label: 'Document\nUpload',
          color: const Color(0xFF9C27B0),
        ),
        FeatureData(
          icon: FontAwesomeIcons.bell,
          label: 'Instant\nNotifications',
          color: const Color(0xFFF44336),
        ),
      ],
    ),
    OnboardingPageData(
      title: 'Real-time\nCommunication',
      subtitle: 'Stay connected with tenants\nand service providers instantly',
      primaryColor: const Color(0xFF9C27B0),
      secondaryColor: const Color(0xFFBA68C8),
      icon: FontAwesomeIcons.comments,
      features: [
        FeatureData(
          icon: FontAwesomeIcons.message,
          label: 'Chat\nSupport',
          color: const Color(0xFF4CAF50),
        ),
        FeatureData(
          icon: FontAwesomeIcons.exclamationTriangle,
          label: 'Emergency\nAlerts',
          color: const Color(0xFFF44336),
        ),
        FeatureData(
          icon: FontAwesomeIcons.calendar,
          label: 'Appointment\nScheduling',
          color: const Color(0xFF2196F3),
        ),
        FeatureData(
          icon: FontAwesomeIcons.star,
          label: 'Service\nRatings',
          color: const Color(0xFFFF9800),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _pages[_currentPage].primaryColor,
                      _pages[_currentPage].secondaryColor,
                    ],
                    transform: GradientRotation(_backgroundAnimation.value * 2 * 3.14159),
                  ),
                ),
              );
            },
          ),
          
          // Floating background elements
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                final offset = (_backgroundAnimation.value + index * 0.2) % 1.0;
                return Positioned(
                  left: -50 + (MediaQuery.of(context).size.width + 100) * offset,
                  top: 100 + (index * 80.0),
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      Icons.home,
                      size: 40 + (index * 10.0),
                      color: Colors.white,
                    ),
                  ),
                );
              },
            );
          }),
          
          // Main content
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return AdvancedOnboardingPage(
                data: _pages[index],
                isActive: index == _currentPage,
                featureAnimationControllers: _featureAnimationControllers,
                contentAnimationController: _contentAnimationController,
              );
            },
          ),
          
          // Skip button
          Positioned(
            top: 60.h,
            right: 32.w,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          // Page indicators
          Positioned(
            bottom: 140.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  height: 8.h,
                  width: _currentPage == index ? 32.w : 8.w,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom buttons
          Positioned(
            bottom: 40.h,
            left: 32.w,
            right: 32.w,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _pages[_currentPage].primaryColor,
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Already have an account? Sign In',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdvancedOnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final bool isActive;
  final List<AnimationController> featureAnimationControllers;
  final AnimationController contentAnimationController;

  const AdvancedOnboardingPage({
    super.key,
    required this.data,
    required this.isActive,
    required this.featureAnimationControllers,
    required this.contentAnimationController,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          children: [
            SizedBox(height: 60.h),
            // App Logo/Name
            AnimatedBuilder(
              animation: contentAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -50 * (1 - contentAnimationController.value)),
                  child: Opacity(
                    opacity: contentAnimationController.value,
                    child: Text(
                      'Own House',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 80.h),
            
            // Main illustration area
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Feature widgets positioned around the center
                  ...data.features.asMap().entries.map((entry) {
                    final index = entry.key;
                    final feature = entry.value;
                    final positions = [
                      const Offset(-100, -100),
                      const Offset(100, -80),
                      const Offset(-80, 80),
                      const Offset(90, 100),
                    ];
                    
                    return AnimatedBuilder(
                      animation: featureAnimationControllers[index],
                      builder: (context, child) {
                        final animation = featureAnimationControllers[index];
                        return Transform.translate(
                          offset: positions[index] * animation.value,
                          child: Transform.scale(
                            scale: animation.value,
                            child: Opacity(
                              opacity: animation.value,
                              child: AdvancedFeatureWidget(feature: feature),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  
                  // Main central icon
                  AnimatedBuilder(
                    animation: contentAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: contentAnimationController.value,
                        child: Container(
                          width: 140.w,
                          height: 140.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            data.icon,
                            size: 60.sp,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Text content
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: contentAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - contentAnimationController.value)),
                        child: Opacity(
                          opacity: contentAnimationController.value,
                          child: Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  AnimatedBuilder(
                    animation: contentAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - contentAnimationController.value)),
                        child: Opacity(
                          opacity: contentAnimationController.value * 0.9,
                          child: Text(
                            data.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 200.h), // Space for buttons
          ],
        ),
      ),
    );
  }
}

class AdvancedFeatureWidget extends StatelessWidget {
  final FeatureData feature;

  const AdvancedFeatureWidget({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              feature.icon,
              size: 24.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            feature.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final List<FeatureData> features;

  OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.features,
  });
}

class FeatureData {
  final IconData icon;
  final String label;
  final Color color;

  FeatureData({
    required this.icon,
    required this.label,
    required this.color,
  });
}