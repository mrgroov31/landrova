import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'unified_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Property Management \n Made Easy',
      subtitle: 'Manage your properties, tenants,\nand maintenance all in one place',
      icon: FontAwesomeIcons.house,
      backgroundColor: const Color(0xFF4CAF50),
      iconColor: Colors.white,
      features: [
        OnboardingFeature(
          icon: FontAwesomeIcons.users,
          label: 'Tenant\nManagement',
          position: const Offset(-80, -120),
        ),
        OnboardingFeature(
          icon: FontAwesomeIcons.wrench,
          label: 'Maintenance\nRequests',
          position: const Offset(100, -80),
        ),
        OnboardingFeature(
          icon: FontAwesomeIcons.chartLine,
          label: 'Analytics\n& Reports',
          position: const Offset(-60, 60),
        ),
        OnboardingFeature(
          icon: FontAwesomeIcons.creditCard,
          label: 'Payment\nTracking',
          position: const Offset(80, 100),
        ),
      ],
    ),
    OnboardingData(
      title: 'Smart Tenant\nOnboarding',
      subtitle: 'Seamlessly onboard new tenants\nwith digital documentation',
      icon: FontAwesomeIcons.userPlus,
      backgroundColor: const Color(0xFF2196F3),
      iconColor: Colors.white,
      features: [
        OnboardingFeature(
          icon: FontAwesomeIcons.qrcode,
          label: 'QR Code\nInvitations',
          position: const Offset(-90, -100),
        ),
        OnboardingFeature(
          icon: FontAwesomeIcons.fileContract,
          label: 'Digital\nContracts',
          position: const Offset(90, -60),
        ),
        OnboardingFeature(
          icon: FontAwesomeIcons.camera,
          label: 'Document\nUpload',
          position: const Offset(-70, 80),
        ),
        OnboardingFeature(
          icon: FontAwesomeIcons.bell,
          label: 'Instant\nNotifications',
          position: const Offset(100, 120),
        ),
      ],
    ),
    OnboardingData(
      title: 'Real-time\nCommunication',
      subtitle: 'Stay connected with tenants\nand service providers instantly',
      icon: FontAwesomeIcons.comments,
      backgroundColor: const Color(0xFF9C27B0),
      iconColor: Colors.white,
      features: [
        OnboardingFeature(
          icon: FontAwesomeIcons.message,
          label: 'Chat\nSupport',
          position: const Offset(-80, -110),
        ),
        OnboardingFeature(
          icon: FontAwesomeIcons.exclamationTriangle,
          label: 'Emergency\nAlerts',
          position: const Offset(90, -70),
        ),
        OnboardingFeature(
          icon: FontAwesomeIcons.calendar,
          label: 'Appointment\nScheduling',
          position: const Offset(-90, 70),
        ),
        OnboardingFeature(
          icon: FontAwesomeIcons.star,
          label: 'Service\nRatings',
          position: const Offset(80, 110),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
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
                );
              },
            ),
            // Skip button
            Positioned(
              top: 60.h,
              right: 32.w,
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
            // Page indicators
            Positioned(
              bottom: 120.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    height: 8.h,
                    width: _currentPage == index ? 24.w : 8.w,
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
                        foregroundColor: _onboardingData[_currentPage].backgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: Text(
                        _currentPage == _onboardingData.length - 1
                            ? 'Get Started'
                            : 'Next',
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
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final bool isActive;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.backgroundColor,
            data.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              SizedBox(height: 60.h),
              // App Logo/Name
              Text(
                'Own House',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 80.h),
              // Main illustration area
              Expanded(
                flex: 3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background decorative elements
                    ...data.features.map((feature) => AnimatedPositioned(
                      duration: Duration(milliseconds: 800 + (data.features.indexOf(feature) * 100)),
                      curve: Curves.elasticOut,
                      left: MediaQuery.of(context).size.width / 2 + feature.position.dx,
                      top: MediaQuery.of(context).size.height * 0.3 + feature.position.dy,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        opacity: isActive ? 1.0 : 0.0,
                        child: FeatureWidget(feature: feature),
                      ),
                    )),
                    // Main central icon
                    AnimatedScale(
                      duration: const Duration(milliseconds: 600),
                      scale: isActive ? 1.0 : 0.8,
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          data.icon,
                          size: 48.sp,
                          color: data.iconColor,
                        ),
                      ),
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
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 800),
                      opacity: isActive ? 1.0 : 0.0,
                      child: Text(
                        data.title,
                        
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 1000),
                      opacity: isActive ? 1.0 : 0.0,
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
                  ],
                ),
              ),
              SizedBox(height: 200.h), // Space for buttons
            ],
          ),
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            feature.icon,
            size: 20.sp,
            color: Colors.white,
          ),
          SizedBox(height: 4.h),
          Text(
            feature.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
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
  final Color backgroundColor;
  final Color iconColor;
  final List<OnboardingFeature> features;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.features,
  });
}

class OnboardingFeature {
  final IconData icon;
  final String label;
  final Offset position;

  OnboardingFeature({
    required this.icon,
    required this.label,
    required this.position,
  });
}