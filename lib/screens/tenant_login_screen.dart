import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'tenant_dashboard_screen.dart';

class TenantLoginScreen extends StatefulWidget {
  const TenantLoginScreen({super.key});

  @override
  State<TenantLoginScreen> createState() => _TenantLoginScreenState();
}

class _TenantLoginScreenState extends State<TenantLoginScreen> {
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.loginTenant(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result.success && mounted) {
      // Return true to indicate successful login
      Navigator.pop(context, true);
      // Navigate to tenant dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const TenantDashboardScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.getSurfaceColor(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getTextPrimaryColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tenant Login',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: isMobile ? 20 : 40),
              
              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: isMobile ? 60 : 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              
              SizedBox(height: isMobile ? 32 : 40),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'your.email@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
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
              
              SizedBox(height: isMobile ? 20 : 24),
              
              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
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
              
              SizedBox(height: isMobile ? 8 : 12),
              
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forgot password feature coming soon'),
                      ),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              
              SizedBox(height: isMobile ? 32 : 40),
              
              // Login Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              // Demo Credentials
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppTheme.getTextSecondaryColor(context)),
                        const SizedBox(width: 8),
                        Text(
                          'Demo Credentials',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextSecondaryColor(context),
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use your registered tenant email',
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Password: tenant123',
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Example: rajesh@example.com / tenant123',
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context).withOpacity(0.7),
                        fontSize: isMobile ? 11 : 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

