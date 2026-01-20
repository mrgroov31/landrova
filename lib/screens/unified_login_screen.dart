import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'tenant_dashboard_screen.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
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
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.lightBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
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
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          'Google Sign-In coming soon! Please use email/password for now.',
          Colors.blue,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await AuthService.debugAvailableTenants();

      var result = await AuthService.loginOwner(
        email: email,
        password: password,
      );

      if (!result.success) {
        result = await AuthService.loginTenantEnhanced(
          email: email,
          password: password,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (result.success && mounted) {
        final user = result.user;
        if (user != null) {
          if (user.isOwner) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          } else if (user.isTenant) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const TenantDashboardScreen()),
              (route) => false,
            );
          }
        }
      } else if (mounted) {
        _showSnackBar(
          result.error ?? 'Invalid email or password',
          Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showSnackBar('Login error: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Stack(
        children: [
          // Floating background elements
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                final offset = _floatingAnimation.value * (index + 1) * 0.05;
                return Positioned(
                  top: size.height * (0.1 + index * 0.15) + (offset * 100),
                  left: size.width * (0.1 + (index % 2) * 0.8) - (offset * 50),
                  child: Opacity(
                    opacity: 0.05,
                    child: Transform.rotate(
                      angle: offset * 2,
                      child: Container(
                        width: 40 + (index * 15),
                        height: 40 + (index * 15),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
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
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 48,
                  vertical: isMobile ? 32 : 48,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isMobile ? 40 : 60),
                      
                      // Header with logo and branding
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildHeader(isMobile),
                        ),
                      ),
                      
                      SizedBox(height: isMobile ? 50 : 70),
                      
                      // Login form
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildLoginForm(isMobile),
                        ),
                      ),
                      
                      SizedBox(height: isMobile ? 40 : 50),
                      
                      // Demo credentials
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildDemoCredentials(isMobile),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
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

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        // Logo with modern design
        Container(
          width: isMobile ? 120 : 140,
          height: isMobile ? 120 : 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inner glow effect
              Container(
                width: isMobile ? 100 : 120,
                height: isMobile ? 100 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Home icon
              Icon(
                Icons.home_rounded,
                size: isMobile ? 60 : 70,
                color: Colors.white,
              ),
            ],
          ),
        ),
        
        SizedBox(height: isMobile ? 32 : 40),
        
        // App name with modern typography
        Text(
          'OwnHouse',
          style: TextStyle(
            fontSize: isMobile ? 36 : 44,
            fontWeight: FontWeight.bold,
            color: AppTheme.lightTextPrimary,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Welcome message
        Text(
          'Welcome back! Sign in to continue',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: AppTheme.lightTextSecondary,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isMobile) {
    return Column(
      children: [
        // Email field
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'your.email@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
          isMobile: isMobile,
        ),
        
        SizedBox(height: isMobile ? 20 : 24),
        
        // Password field
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppTheme.lightTextSecondary,
              size: isMobile ? 22 : 24,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          isMobile: isMobile,
        ),
        
        SizedBox(height: isMobile ? 16 : 20),
        
        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              _showSnackBar('Forgot password feature coming soon', Colors.blue);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 8 : 10,
              ),
            ),
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        
        SizedBox(height: isMobile ? 28 : 32),
        
        // Login button
        Container(
          height: isMobile ? 56 : 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.zero,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        
        SizedBox(height: isMobile ? 24 : 28),
        
        // Divider
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: AppTheme.lightTextSecondary,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
          ],
        ),
        
        SizedBox(height: isMobile ? 24 : 28),
        
        // Google sign in button
        Container(
          height: isMobile ? 56 : 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _loginWithGoogle,
            style: OutlinedButton.styleFrom(
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
            ),
            icon: Container(
              width: isMobile ? 24 : 28,
              height: isMobile ? 24 : 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: isMobile ? 12 : 14,
                      height: isMobile ? 12 : 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: isMobile ? 12 : 14,
                      height: isMobile ? 12 : 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA4335),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: isMobile ? 12 : 14,
                      height: isMobile ? 12 : 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBBC05),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: isMobile ? 12 : 14,
                      height: isMobile ? 12 : 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34A853),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            label: Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: isMobile ? 15 : 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTextPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: isMobile ? 16 : 18,
          fontWeight: FontWeight.w500,
          color: AppTheme.lightTextPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.lightTextSecondary.withOpacity(0.7),
            fontSize: isMobile ? 16 : 18,
          ),
          labelStyle: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTextSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: isMobile ? 22 : 24,
          ),
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isMobile ? 18 : 20,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDemoCredentials(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.indigo.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade200.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Demo Credentials',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  fontSize: isMobile ? 16 : 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCredentialRow(
            'Property Owner:',
            'owner@ownhouse.com / owner123',
            isMobile,
            Icons.business_rounded,
          ),
          const SizedBox(height: 12),
          _buildCredentialRow(
            'Tenant:',
            'Use registered tenant email / tenant123',
            isMobile,
            Icons.person_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, bool isMobile, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.shade200.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: isMobile ? 12 : 13,
                    height: 1.3,
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
