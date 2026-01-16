import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';
import 'tenant_dashboard_screen.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement Google Sign-In
      // For now, show a message
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In coming soon! Please use email/password for now.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
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

      // Debug: Check available tenants
      await AuthService.debugAvailableTenants();

      // Try owner login first
      var result = await AuthService.loginOwner(
        email: email,
        password: password,
      );

      // If owner login fails, try enhanced tenant login
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
          // Navigate based on user role
          if (user.isOwner) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Invalid email or password'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive font sizes
    final titleFontSize = isMobile ? screenWidth * 0.08 : 48.0;
    final subtitleFontSize = isMobile ? screenWidth * 0.04 : 20.0;
    final labelFontSize = isMobile ? screenWidth * 0.035 : 16.0;
    final buttonFontSize = isMobile ? screenWidth * 0.04 : 18.0;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? screenWidth * 0.06 : 48,
              vertical: isMobile ? 32 : 48,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isMobile ? screenHeight * 0.05 : 60),
                  
                  // Logo/Icon with modern design
                  Center(
                    child: Container(
                      width: isMobile ? screenWidth * 0.25 : 120,
                      height: isMobile ? screenWidth * 0.25 : 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.home_rounded,
                        size: isMobile ? screenWidth * 0.15 : 70,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? screenHeight * 0.04 : 40),
                  
                  // App Name with modern typography
                  Text(
                    'OwnHouse',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: Colors.grey.shade900,
                      height: 1.1,
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 8 : 12),
                  
                  // Subtitle
                  Text(
                    'Welcome back! Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? screenHeight * 0.06 : 64),
                  
                  // Email Field with modern design
                  Container(
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: labelFontSize + 2,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade900,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'your.email@example.com',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: labelFontSize + 2,
                        ),
                        labelStyle: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppTheme.primaryColor,
                          size: isMobile ? 22 : 24,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: isMobile ? 18 : 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 20 : 24),
                  
                  // Password Field with modern design
                  Container(
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
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        fontSize: labelFontSize + 2,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade900,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: labelFontSize + 2,
                        ),
                        labelStyle: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: AppTheme.primaryColor,
                          size: isMobile ? 22 : 24,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.grey.shade600,
                            size: isMobile ? 22 : 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: isMobile ? 18 : 20,
                        ),
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
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 16 : 20),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Forgot password feature coming soon'),
                          ),
                        );
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
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 28 : 32),
                  
                  // Login Button with modern design
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
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: buttonFontSize,
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
                            color: Colors.grey.shade500,
                            fontSize: labelFontSize,
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
                  
                  // Google Sign In Button with modern design
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
                            // Google colors representation
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
                          fontSize: buttonFontSize - 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 32 : 40),
                  
                  // Demo Credentials Info with modern design
                  Container(
                    padding: EdgeInsets.all(isMobile ? 18 : 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1.5,
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
                                size: isMobile ? 20 : 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Demo Credentials',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                fontSize: labelFontSize + 1,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCredentialRow(
                          'Owner:',
                          'owner@ownhouse.com / owner123',
                          isMobile,
                          labelFontSize,
                        ),
                        const SizedBox(height: 10),
                        _buildCredentialRow(
                          'Tenant:',
                          'Use registered tenant email / tenant123',
                          isMobile,
                          labelFontSize,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 20 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, bool isMobile, double fontSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 70 : 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade800,
              fontSize: fontSize,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: fontSize - 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
