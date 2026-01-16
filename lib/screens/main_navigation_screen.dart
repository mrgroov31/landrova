import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'dashboard_screen.dart';
import 'buildings_screen.dart';
import 'tenants_screen.dart';
import 'payments_screen.dart';
import 'settings_screen.dart';
import 'add_building_screen.dart';
import 'add_room_screen.dart';
import 'invite_tenant_screen.dart';
import 'complaints_screen.dart';
import 'service_providers_list_screen.dart';
import 'vacating_requests_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> get _screens => [
    const DashboardScreen(),
    const BuildingsScreen(),
    const TenantsScreen(),
    const PaymentsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (_isMenuOpen) _buildBlurOverlay(),
          if (_currentIndex == 0) _buildFloatingMenu(), // Only show menu on dashboard
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? _buildMainFAB() : null, // Only show FAB on dashboard
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBlurOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isMenuOpen = false),
      child: Container(
        color: Colors.black.withOpacity(0.4),
      ),
    );
  }

  Widget _buildFloatingMenu() {
    if (!_isMenuOpen) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 100,
      right: 24,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuOption(Icons.add_business, 'Add Building', Colors.blue, () {
              setState(() => _isMenuOpen = false);
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const AddBuildingScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            }),
            _buildMenuOption(Icons.add_home, 'Add Room', Colors.green, () {
              setState(() => _isMenuOpen = false);
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const AddRoomScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            }),
            _buildMenuOption(Icons.person_add, 'Add Tenant', Colors.purple, () {
              setState(() => _isMenuOpen = false);
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const InviteTenantScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            }),
            _buildMenuOption(Icons.report_problem, 'Complaints', Colors.orange, () {
              setState(() => _isMenuOpen = false);
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const ComplaintsScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            }),
            _buildMenuOption(Icons.payment, 'Payments', Colors.indigo, () {
              setState(() => _isMenuOpen = false);
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const PaymentsScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            }),
            _buildMenuOption(Icons.handyman, 'Service Providers', Colors.teal, () {
              setState(() => _isMenuOpen = false);
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const ServiceProvidersListScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            }),
            _buildMenuOption(Icons.exit_to_app, 'Vacating Requests', Colors.red, () {
              setState(() => _isMenuOpen = false);
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const VacatingRequestsScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.getTextPrimaryColor(context),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      minLeadingWidth: 24,
      dense: true,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'HOME', 0),
          _buildNavItem(Icons.apartment, 'PROPERTIES', 1),
          _buildNavItem(Icons.people, 'PEOPLE', 2),
          _buildNavItem(Icons.account_balance_wallet, 'FINANCE', 3),
          _buildNavItem(Icons.settings, 'ME', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool active = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active 
                  ? AppTheme.primaryColor 
                  : AppTheme.getTextSecondaryColor(context).withOpacity(0.5),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active 
                    ? AppTheme.primaryColor 
                    : AppTheme.getTextSecondaryColor(context).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFAB() {
    return FloatingActionButton(
      onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.primaryColor
          : Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 300),
        turns: _isMenuOpen ? 0.375 : 0,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
