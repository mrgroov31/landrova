import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/unified_login_screen.dart';
import 'screens/tenant_onboarding_screen.dart';
import 'screens/tenant_dashboard_screen.dart';
import 'screens/public_rooms_listing_screen.dart';
import 'models/service_provider_adapter.dart';
import 'models/complaint_adapter.dart';
import 'models/tenant_adapter.dart';
import 'models/vacating_request_adapter.dart';
import 'services/invitation_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ServiceProviderAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ComplaintAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(TenantAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(VacatingRequestAdapter());
  }
  
  // Verify all adapters are registered
  assert(Hive.isAdapterRegistered(0), 'ServiceProviderAdapter not registered');
  assert(Hive.isAdapterRegistered(1), 'ComplaintAdapter not registered');
  assert(Hive.isAdapterRegistered(2), 'TenantAdapter not registered');
  assert(Hive.isAdapterRegistered(4), 'VacatingRequestAdapter not registered');
  
  // Initialize theme service
  final themeService = ThemeService();
  await themeService.loadTheme();
  
  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatefulWidget {
  final ThemeService themeService;
  
  const MyApp({super.key, required this.themeService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Get initial link if app was opened via deep link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink.toString());
    }

    // Listen for deep links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri.toString());
    });
  }

  void _handleDeepLink(String link) {
    debugPrint('');
    debugPrint('🔗 ===== DEEP LINK HANDLING START =====');
    debugPrint('🔗 [DEEPLINK] Received link: $link');
    
    final params = InvitationService.parseInvitationLink(link);
    debugPrint('🔗 [DEEPLINK] Parsed parameters: $params');
    
    final token = params['token'];
    final roomNumber = params['room'];
    final buildingId = params['buildingId'];
    final roomId = params['roomId'];
    
    debugPrint('🔗 [DEEPLINK] Token: $token');
    debugPrint('🔗 [DEEPLINK] Room Number: $roomNumber');
    debugPrint('🔗 [DEEPLINK] Building ID: $buildingId');
    debugPrint('🔗 [DEEPLINK] Room ID: $roomId');
    debugPrint('🔗 ===== DEEP LINK HANDLING END =====');
    debugPrint('');

    if (token != null && token.isNotEmpty) {
      // Navigate to tenant onboarding screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => TenantOnboardingScreen(
              invitationToken: token,
              roomNumber: roomNumber,
              buildingId: buildingId,
              roomId: roomId,
            ),
          ),
          (route) => false, // Remove all previous routes
        );
      });
    }
  }

  Widget _getInitialScreen() {
    // Check if user is logged in
    if (AuthService.isLoggedIn) {
      final user = AuthService.currentUser;
      if (user?.isOwner == true) {
        return const DashboardScreen();
      } else if (user?.isTenant == true) {
        return const TenantDashboardScreen();
      }
    }
    // Show unified login screen if not logged in
    return const UnifiedLoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Own House - Property Management',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode == AppThemeMode.light
                ? ThemeMode.light
                : themeService.themeMode == AppThemeMode.dark
                    ? ThemeMode.dark
                    : ThemeMode.system,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),
            // Check authentication and route accordingly
            home: _getInitialScreen(),
          );
        },
      ),
    );
  }
}
