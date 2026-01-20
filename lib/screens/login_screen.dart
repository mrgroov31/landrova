// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../utils/responsive.dart';
// import '../theme/app_theme.dart';
// import 'owner_login_screen.dart';
// import 'tenant_login_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
    
//     // Set status bar style
//     SystemChrome.setSystemUIOverlayStyle(
//       SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.dark,
//         systemNavigationBarColor: AppTheme.lightBackground,
//         systemNavigationBarIconBrightness: Brightness.dark,
//       ),
//     );
    
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
    
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
    
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
//     );
    
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOutCubic,
//     ));
    
//     _startAnimations();
//   }

//   void _startAnimations() async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     _fadeController.forward();
//     await Future.delayed(const Duration(milliseconds: 300));
//     _slideController.forward();
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = Responsive.isMobile(context);
//     final size = MediaQuery.of(context).size;
    
//     return Scaffold(
//       backgroundColor: AppTheme.lightBackground,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minHeight: size.height - MediaQuery.of(context).padding.top,
//             ),
//             child: Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: isMobile ? 24 : 32,
//               vertical: isMobile ? 20 : 32,
//             ),
//             child: Column(
//               children: [
//                 // Header section with logo and branding
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: SlideTransition(
//                     position: _slideAnimation,
//                     child: _buildHeader(isMobile),
//                   ),
//                 ),
                
//                 SizedBox(height: isMobile ? 40 : 60),
                
//                 // Role selection cards
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: SlideTransition(
//                     position: _slideAnimation,
//                     child: _buildRoleSelection(context, isMobile),
//                   ),
//                 ),
                
//                 SizedBox(height: isMobile ? 40 : 60),
                
//                 // Demo credentials section
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: SlideTransition(
//                     position: _slideAnimation,
//                     child: _buildDemoCredentials(isMobile),
//                   ),
//                 ),
                
//                 const SizedBox(height: 40),
                
//                 // Footer
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: _buildFooter(isMobile),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ));
//   }

//   Widget _buildHeader(bool isMobile) {
//     return Column(
//       children: [
//         SizedBox(height: isMobile ? 20 : 40),
        
//         // Logo with modern design
//         Container(
//           width: isMobile ? 120 : 140,
//           height: isMobile ? 120 : 140,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 AppTheme.primaryColor,
//                 AppTheme.secondaryColor,
//               ],
//             ),
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: AppTheme.primaryColor.withOpacity(0.3),
//                 blurRadius: 30,
//                 offset: const Offset(0, 15),
//                 spreadRadius: 5,
//               ),
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // Inner glow effect
//               Container(
//                 width: isMobile ? 100 : 120,
//                 height: isMobile ? 100 : 120,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: RadialGradient(
//                     colors: [
//                       Colors.white.withOpacity(0.3),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//               ),
//               // Home icon
//               Icon(
//                 Icons.home_rounded,
//                 size: isMobile ? 60 : 70,
//                 color: Colors.white,
//               ),
//             ],
//           ),
//         ),
        
//         SizedBox(height: isMobile ? 32 : 40),
        
//         // App name with modern typography
//         Text(
//           'OwnHouse',
//           style: TextStyle(
//             fontSize: isMobile ? 36 : 44,
//             fontWeight: FontWeight.bold,
//             color: AppTheme.lightTextPrimary,
//             letterSpacing: -1,
//             height: 1.1,
//           ),
//         ),
        
//         const SizedBox(height: 8),
        
//         // Subtitle with accent
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           decoration: BoxDecoration(
//             color: AppTheme.primaryColor.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: AppTheme.primaryColor.withOpacity(0.2),
//               width: 1,
//             ),
//           ),
//           child: Text(
//             'Property Management System',
//             style: TextStyle(
//               fontSize: isMobile ? 14 : 16,
//               color: AppTheme.primaryColor,
//               fontWeight: FontWeight.w600,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRoleSelection(BuildContext context, bool isMobile) {
//     return Column(
//       children: [
//         // Section title
//         Text(
//           'Choose Your Role',
//           style: TextStyle(
//             fontSize: isMobile ? 24 : 28,
//             fontWeight: FontWeight.bold,
//             color: AppTheme.lightTextPrimary,
//             letterSpacing: -0.5,
//           ),
//         ),
        
//         const SizedBox(height: 8),
        
//         Text(
//           'Select how you want to access the platform',
//           style: TextStyle(
//             fontSize: isMobile ? 15 : 16,
//             color: AppTheme.lightTextSecondary,
//             height: 1.4,
//           ),
//         ),
        
//         SizedBox(height: isMobile ? 32 : 40),
        
//         // Role cards
//         _buildRoleCard(
//           context: context,
//           title: 'Property Owner',
//           subtitle: 'Manage properties, tenants, and track payments with comprehensive analytics',
//           icon: Icons.business_rounded,
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               AppTheme.primaryColor,
//               AppTheme.primaryColor.withOpacity(0.8),
//             ],
//           ),
//           isMobile: isMobile,
//           onTap: () => _navigateWithAnimation(context, const OwnerLoginScreen()),
//         ),
        
//         SizedBox(height: isMobile ? 20 : 24),
        
//         _buildRoleCard(
//           context: context,
//           title: 'Tenant',
//           subtitle: 'Access room details, submit maintenance requests, and manage payments',
//           icon: Icons.person_rounded,
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               AppTheme.secondaryColor,
//               AppTheme.secondaryColor.withOpacity(0.8),
//             ],
//           ),
//           isMobile: isMobile,
//           onTap: () => _navigateWithAnimation(context, const TenantLoginScreen()),
//         ),
//       ],
//     );
//   }

//   Widget _buildRoleCard({
//     required BuildContext context,
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Gradient gradient,
//     required bool isMobile,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(20),
//           child: Container(
//             padding: EdgeInsets.all(isMobile ? 24 : 28),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: Colors.grey.shade100,
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               children: [
//                 // Icon container with gradient
//                 Container(
//                   width: isMobile ? 60 : 70,
//                   height: isMobile ? 60 : 70,
//                   decoration: BoxDecoration(
//                     gradient: gradient,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: gradient.colors.first.withOpacity(0.3),
//                         blurRadius: 15,
//                         offset: const Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   child: Icon(
//                     icon,
//                     size: isMobile ? 32 : 36,
//                     color: Colors.white,
//                   ),
//                 ),
                
//                 SizedBox(width: isMobile ? 20 : 24),
                
//                 // Text content
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: TextStyle(
//                           fontSize: isMobile ? 20 : 22,
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.lightTextPrimary,
//                           height: 1.2,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         subtitle,
//                         style: TextStyle(
//                           fontSize: isMobile ? 14 : 15,
//                           color: AppTheme.lightTextSecondary,
//                           height: 1.4,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Arrow icon
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: gradient.colors.first.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     Icons.arrow_forward_ios_rounded,
//                     size: isMobile ? 16 : 18,
//                     color: gradient.colors.first,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDemoCredentials(bool isMobile) {
//     return Container(
//       padding: EdgeInsets.all(isMobile ? 20 : 24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Colors.blue.shade50,
//             Colors.indigo.shade50,
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.blue.shade200.withOpacity(0.5),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade100,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   Icons.info_outline_rounded,
//                   color: Colors.blue.shade700,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 'Demo Credentials',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue.shade800,
//                   fontSize: isMobile ? 16 : 18,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           _buildCredentialRow(
//             'Property Owner:',
//             'owner@ownhouse.com / owner123',
//             isMobile,
//             Icons.business_rounded,
//           ),
//           const SizedBox(height: 12),
//           _buildCredentialRow(
//             'Tenant:',
//             'Use registered tenant email / tenant123',
//             isMobile,
//             Icons.person_rounded,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCredentialRow(String label, String value, bool isMobile, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.7),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: Colors.blue.shade200.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             size: 16,
//             color: Colors.blue.shade600,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: Colors.blue.shade800,
//                     fontSize: isMobile ? 13 : 14,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     color: Colors.blue.shade700,
//                     fontSize: isMobile ? 12 : 13,
//                     height: 1.3,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFooter(bool isMobile) {
//     return Column(
//       children: [
//         Text(
//           '© 2024 OwnHouse. All rights reserved.',
//           style: TextStyle(
//             color: AppTheme.lightTextSecondary,
//             fontSize: isMobile ? 12 : 13,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Secure • Reliable • Professional',
//           style: TextStyle(
//             color: AppTheme.primaryColor,
//             fontSize: isMobile ? 11 : 12,
//             fontWeight: FontWeight.w500,
//             letterSpacing: 0.5,
//           ),
//         ),
//       ],
//     );
//   }

//   void _navigateWithAnimation(BuildContext context, Widget screen) {
//     Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => screen,
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           return SlideTransition(
//             position: Tween<Offset>(
//               begin: const Offset(1.0, 0.0),
//               end: Offset.zero,
//             ).animate(CurvedAnimation(
//               parent: animation,
//               curve: Curves.easeOutCubic,
//             )),
//             child: FadeTransition(
//               opacity: animation,
//               child: child,
//             ),
//           );
//         },
//         transitionDuration: const Duration(milliseconds: 400),
//       ),
//     );
//   }
// }

