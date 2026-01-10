import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../models/room.dart';
import '../models/complaint.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../services/optimized_api_service.dart';
import '../services/hive_api_service.dart';
import '../services/complaint_service.dart';
import '../widgets/modern_stat_card.dart';
import '../widgets/modern_stat_mini_card.dart';
import '../widgets/revenue_chart_card.dart';
import '../widgets/modern_quick_action.dart';
import '../widgets/room_listing_card.dart';
import '../widgets/room_status_card.dart';
import '../widgets/complaint_card.dart';
import '../widgets/performance_indicator.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/enhanced_skeleton_loader.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'rooms_screen.dart';
import 'tenants_screen.dart';
import 'complaints_screen.dart';
import 'complaint_detail_screen.dart';
import 'payments_screen.dart';
import 'buildings_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'register_service_provider_screen.dart';
import 'service_providers_list_screen.dart';
import 'vacating_requests_screen.dart';
import 'unified_login_screen.dart';
import 'add_room_screen.dart';
import 'invite_tenant_screen.dart';
import 'room_detail_screen.dart';
import '../services/auth_service.dart';
import '../constants/app_assets.dart';
import '../utils/custom_page_route.dart';
import '../models/building.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final String? selectedBuildingId;
  
  const DashboardScreen({super.key, this.selectedBuildingId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Tenant> tenants = [];
  List<Room> rooms = [];
  List<Complaint> complaints = [];
  List<Payment> payments = [];
  bool isLoading = true;
  String? currentBuildingId;
  PageController? _roomsPageController;
  PageController? _complaintsPageController;
  int _roomsCurrentPage = 0;
  int _complaintsCurrentPage = 0;
  List<Building> _buildings = [];

  @override
  void initState() {
    super.initState();
    currentBuildingId = widget.selectedBuildingId;
    _roomsPageController = PageController(viewportFraction: 0.9);
    _complaintsPageController = PageController(viewportFraction: 0.9);
    
    // Add listeners for page changes
    _roomsPageController!.addListener(() {
      if (mounted) {
        setState(() {
          _roomsCurrentPage = _roomsPageController!.page?.round() ?? 0;
        });
      }
    });
    
    _complaintsPageController!.addListener(() {
      if (mounted) {
        setState(() {
          _complaintsCurrentPage = _complaintsPageController!.page?.round() ?? 0;
        });
      }
    });
    
    loadDashboardData();
  }

  @override
  void dispose() {
    _roomsPageController?.dispose();
    _complaintsPageController?.dispose();
    super.dispose();
  }

  Future<void> loadDashboardData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final ownerId = AuthService.getOwnerId();
      
      // Use Hive API service for ultra-fast loading with persistent caching
      final dashboardData = await HiveApiService.getDashboardData(ownerId);
      
      // Extract data from Hive response
      var allRooms = (dashboardData['rooms'] as List<Room>?) ?? [];
      var allTenants = (dashboardData['tenants'] as List<Tenant>?) ?? [];
      var allComplaints = (dashboardData['complaints'] as List<Complaint>?) ?? [];
      var allPayments = (dashboardData['payments'] as List<Payment>?) ?? [];
      var allBuildings = (dashboardData['buildings'] as List<Building>?) ?? [];

      debugPrint('📊 [Dashboard] Loaded ${allRooms.length} rooms, ${allTenants.length} tenants, ${allComplaints.length} complaints from Hive');

      setState(() {
        _buildings = allBuildings;
        
        // Filter by building if selected
        if (currentBuildingId != null && currentBuildingId!.isNotEmpty) {
          rooms = allRooms.where((r) => r.buildingId == currentBuildingId || r.buildingId.isEmpty).toList();
          // If no rooms found with buildingId, show all rooms (fallback)
          if (rooms.isEmpty) {
            rooms = allRooms;
          }
          // Filter tenants, complaints, and payments based on room numbers in selected building
          final roomNumbers = rooms.map((r) => r.number).toSet();
          tenants = allTenants.where((t) => roomNumbers.contains(t.roomNumber)).toList();
          complaints = allComplaints.where((c) => roomNumbers.contains(c.roomNumber)).toList();
          payments = allPayments.where((p) => roomNumbers.contains(p.roomNumber)).toList();
        } else {
          // No building selected - show all data
          rooms = allRooms;
          tenants = allTenants;
          complaints = allComplaints;
          payments = allPayments;
        }
        isLoading = false;
      });
      
      // Preload service providers in background for faster access later
      HiveApiService.getServiceProviders();
      
    } catch (e) {
      // If Hive API fails, fallback to optimized API
      debugPrint('⚠️ [Dashboard] Hive API failed, falling back to optimized API: $e');
      await _loadDashboardDataOptimizedFallback();
    }
  }

  // Fallback method using optimized API service
  Future<void> _loadDashboardDataOptimizedFallback() async {
    try {
      final ownerId = AuthService.getOwnerId();
      
      // Use optimized API service as fallback
      final dashboardData = await OptimizedApiService.loadDashboardDataOptimized(ownerId);
      
      // Extract data from optimized response
      var allRooms = (dashboardData['rooms'] as List<Room>?) ?? [];
      var allTenants = (dashboardData['tenants'] as List<Tenant>?) ?? [];
      var allComplaints = (dashboardData['complaints'] as List<Complaint>?) ?? [];
      var allPayments = (dashboardData['payments'] as List<Payment>?) ?? [];
      var allBuildings = (dashboardData['buildings'] as List<Building>?) ?? [];

      setState(() {
        _buildings = allBuildings;
        
        // Filter by building if selected
        if (currentBuildingId != null && currentBuildingId!.isNotEmpty) {
          rooms = allRooms.where((r) => r.buildingId == currentBuildingId || r.buildingId.isEmpty).toList();
          if (rooms.isEmpty) {
            rooms = allRooms;
          }
          final roomNumbers = rooms.map((r) => r.number).toSet();
          tenants = allTenants.where((t) => roomNumbers.contains(t.roomNumber)).toList();
          complaints = allComplaints.where((c) => roomNumbers.contains(c.roomNumber)).toList();
          payments = allPayments.where((p) => roomNumbers.contains(p.roomNumber)).toList();
        } else {
          rooms = allRooms;
          tenants = allTenants;
          complaints = allComplaints;
          payments = allPayments;
        }
        isLoading = false;
      });
      
    } catch (e) {
      // Final fallback to original implementation
      debugPrint('⚠️ [Dashboard] Optimized API also failed, falling back to original: $e');
      await _loadDashboardDataFallback();
    }
  }

  // Fallback method using original API calls
  Future<void> _loadDashboardDataFallback() async {
    try {
      // Load buildings for selection
      try {
        final ownerId = AuthService.getOwnerId();
        final buildingsResponse = await ApiService.fetchBuildingsByOwnerId(ownerId);
        final buildings = ApiService.parseBuildings(buildingsResponse);
        setState(() {
          _buildings = buildings;
        });
      } catch (e) {
        debugPrint('Error loading buildings: $e');
      }

      // Load all data in parallel (except complaints which need to merge with Hive)
      final ownerId = AuthService.getOwnerId();
      final results = await Future.wait([
        ApiService.fetchRoomsByOwnerId(ownerId),
        ApiService.fetchTenants(),
        ApiService.fetchPayments(),
        ApiService.fetchComplaintsByOwnerId(ownerId), // Use new API method
      ]);

      // Parse all data
      var allRooms = ApiService.parseRooms(results[0]);
      debugPrint('📊 [Dashboard] Parsed ${allRooms.length} rooms from API');
      var allTenants = ApiService.parseTenants(results[1]);
      var allPayments = ApiService.parsePayments(results[2]);
      var allComplaints = ApiService.parseApiComplaints(results[3]); // Use new parser
      debugPrint('📊 [Dashboard] Parsed ${allComplaints.length} complaints from API');

      setState(() {
        // Filter by building if selected
        if (currentBuildingId != null && currentBuildingId!.isNotEmpty) {
          rooms = allRooms.where((r) => r.buildingId == currentBuildingId || r.buildingId.isEmpty).toList();
          // If no rooms found with buildingId, show all rooms (fallback)
          if (rooms.isEmpty) {
            rooms = allRooms;
          }
          // Filter tenants, complaints, and payments based on room numbers in selected building
          final roomNumbers = rooms.map((r) => r.number).toSet();
          tenants = allTenants.where((t) => roomNumbers.contains(t.roomNumber)).toList();
          complaints = allComplaints.where((c) => roomNumbers.contains(c.roomNumber)).toList();
          payments = allPayments.where((p) => roomNumbers.contains(p.roomNumber)).toList();
        } else {
          // No building selected - show all data
          rooms = allRooms;
          tenants = allTenants;
          complaints = allComplaints;
          payments = allPayments;
        }
        isLoading = false;
      });
    } catch (e) {
      // If API fails, show error but don't clear data
      setState(() {
        isLoading = false;
      });
      // Handle error - could show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      // Debug print
      debugPrint('Error loading dashboard data: $e');
    }
  }

  int getTotalRooms() => rooms.isEmpty ? 0 : rooms.length;
  int getOccupiedRooms() => rooms.isEmpty ? 0 : rooms.where((r) => r.hasTenant || r.isOccupied || r.status == 'occupied').length;
  int getVacantRooms() => rooms.isEmpty ? 0 : rooms.where((r) => !r.hasTenant && !r.isOccupied && r.status == 'vacant').length;
  
  // Active Tenants = Count actual tenants from room data + fallback to occupancy
  int getTotalTenants() {
    if (rooms.isEmpty) return 0;
    
    // First, count rooms with actual tenant data
    int tenantsFromRoomData = rooms
        .where((r) => r.hasTenant)
        .length;
    
    // If we have tenant data, use it; otherwise fallback to occupancy count
    if (tenantsFromRoomData > 0) {
      return tenantsFromRoomData;
    }
    
    // Fallback: use currentOccupancy for occupied rooms
    return rooms
        .where((r) => r.isOccupied || r.status == 'occupied')
        .fold(0, (sum, room) => sum + room.currentOccupancy);
  }
  
  // Alternative: Count active tenant records (if you want to track individual tenant records)
  int getActiveTenantRecords() => tenants.isEmpty ? 0 : tenants.where((t) => t.isActive).length;
  
  // Check if property has PG rooms (Paying Guest rooms)
  bool hasPGRooms() {
    if (rooms.isEmpty) return false;
    return rooms.any((room) => room.type == 'pg');
  }
  
  // Check if property is primarily PG (more than 50% are PG rooms)
  bool isPrimarilyPG() {
    if (rooms.isEmpty) return false;
    final pgRooms = rooms.where((r) => r.type == 'pg').length;
    return pgRooms > (rooms.length / 2);
  }
  int getPendingComplaints() => complaints.isEmpty ? 0 : complaints.where((c) => c.status == 'pending').length;
  int getOverduePayments() => payments.isEmpty ? 0 : payments.where((p) => p.status == 'overdue').length;
  
  double getTotalRevenue() {
    return payments
        .where((p) => p.status == 'paid')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double getPendingRevenue() {
    return payments
        .where((p) => p.status == 'pending' || p.status == 'overdue')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  List<double> getMonthlyRevenue() {
    // Mock monthly revenue data
    return [45000, 52000, 48000, 55000, 60000, 58000];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    return PerformanceIndicator(
      showDebugInfo: true, // Set to false in production
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        drawer: _buildNavigationDrawer(isMobile),
        floatingActionButton: _buildFloatingActionButton(),
        body: SafeArea(
          child: EnhancedSkeletonLoader(
            isLoading: isLoading,
            loadingMessage: 'Loading your dashboard...',
            showHiveHint: true,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildModernHeader(isMobile),
                  
                  SizedBox(height: isMobile ? 24 : 32),
                  
                  // Unified Super Card (replacing both daily score and quick stats)
                  _buildUnifiedSuperCard(isMobile),
                  
                  SizedBox(height: isMobile ? 24 : 32),
                  
                  // Activity Cards
                  _buildActivityCards(isMobile),
                  
                  SizedBox(height: isMobile ? 24 : 32),
                  
                  // Recent Activity
                  _buildRecentActivity(isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isMobile) {
    return Row(
      children: [
        // Menu Button
        Container(
          width: isMobile ? 44 : 48,
          height: isMobile ? 44 : 48,
          decoration: BoxDecoration(
            color: AppTheme.getTextPrimaryColor(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getTextPrimaryColor(context).withOpacity(0.1)),
          ),
          child: IconButton(
            icon: Icon(Icons.menu, color: AppTheme.getTextPrimaryColor(context), size: 20),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        
        SizedBox(width: isMobile ? 12 : 16),
        
        // Welcome Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: AppTheme.getTextSecondaryColor(context),
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              Text(
                'Property Owner',
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Action Buttons
        Row(
          children: [
            _buildHeaderButton(Icons.notifications_outlined, () {}),
            SizedBox(width: isMobile ? 8 : 12),
            _buildHeaderButton(Icons.settings_outlined, () {
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const SettingsScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            }),
            SizedBox(width: isMobile ? 8 : 12),
            // Profile Avatar
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const ProfileScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
              child: Container(
                width: isMobile ? 44 : 48,
                height: isMobile ? 44 : 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentColor, Color(0xFFFF8F00)],
                  ),
                  border: Border.all(color: AppTheme.getTextPrimaryColor(context).withOpacity(0.2), width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.getTextPrimaryColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getTextPrimaryColor(context).withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.getTextPrimaryColor(context), size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildUnifiedSuperCard(bool isMobile) {
    final totalRevenue = getTotalRevenue();
    final pendingRevenue = getPendingRevenue();
    final totalRooms = getTotalRooms();
    final totalComplaints = getPendingComplaints();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Gemini Gradient Header
          Container(
            padding: EdgeInsets.all(isMobile ? 28 : 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4285F4), // Google Blue
                  Color(0xFF9171F8), // Purple
                  Color(0xFFF06292), // Pink
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Stack(
              children: [
                // Blur effect background
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                   
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                // color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TOTAL REVENUE',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            '+12.5% UP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 8 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    // Animated Revenue Counter
                    _buildAnimatedCounter(
                      value: totalRevenue,
                      prefix: '₹',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 40 : 48,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'SETTLED EARNINGS • CURRENT CYCLE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isMobile ? 9 : 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Floating Stats Bar
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    // Pending Dues
                    Expanded(
                      child: Container(
                        color: AppTheme.getCardColor(context),
                        padding: EdgeInsets.all(isMobile ? 20 : 24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            _buildAnimatedCounter(
                              value: pendingRevenue,
                              prefix: '₹',
                              style: TextStyle(
                                color: AppTheme.getTextPrimaryColor(context),
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PENDING DUES',
                              style: TextStyle(
                                color: AppTheme.getTextSecondaryColor(context),
                                fontSize: isMobile ? 8 : 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 105, color: AppTheme.getTextSecondaryColor(context)),
                    // Live Rooms
                    Expanded(
                      child: Container(
                        color: AppTheme.getCardColor(context),
                        padding: EdgeInsets.all(isMobile ? 20 : 24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.business_outlined,
                              color: Color(0xFF6366F1),
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            _buildAnimatedCounter(
                              value: totalRooms.toDouble(),
                              style: TextStyle(
                                color: AppTheme.getTextPrimaryColor(context),
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'OUR ROOMS',
                              style: TextStyle(
                                color: AppTheme.getTextSecondaryColor(context),
                                fontSize: isMobile ? 8 : 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Enhanced Ticker Section
          Column(
            children: [
              // Ticker Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 28 : 32,
                  vertical: isMobile ? 12 : 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child:  AnimatedContainer(
                            duration: Duration(milliseconds: 1000),
                            curve: Curves.easeInOut,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tenant Complaints',
                          style: TextStyle(
                            color: AppTheme.getTextSecondaryColor(context),
                            fontSize: isMobile ? 8 : 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFF6366F1).withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(20),
                    //   ),
                    //   child: Text(
                    //     '$totalComplaints REPORTS',
                    //     style: TextStyle(
                    //       color: const Color(0xFF6366F1),
                    //       fontSize: isMobile ? 8 : 10,
                    //       fontWeight: FontWeight.w900,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              
              // Complaint Ticker
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceColor(context),
                    border: Border(
                      top: BorderSide(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2)),
                    ),
                  ),
                  child: _buildComplaintTicker(isMobile),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCounter({
    required double value,
    String prefix = '',
    required TextStyle style,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween<double>(begin: 0, end: value),
      curve: Curves.easeOutExpo,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix${animatedValue.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )}',
          style: style,
        );
      },
    );
  }

  Widget _buildComplaintTicker(bool isMobile) {
    if (complaints.isEmpty) {
      return Container(
        height: 112,
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          border: Border(
            top: BorderSide(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2)),
          ),
        ),
        child: Center(
          child: Text(
            'No active complaints',
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(context),
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Create extended list for seamless scrolling
    final extendedComplaints = [...complaints, ...complaints, ...complaints];
    
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          top: BorderSide(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2)),
        ),
      ),
      child: Stack(
        children: [
          // Fade masks
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.getSurfaceColor(context),
                    AppTheme.getSurfaceColor(context).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    AppTheme.getSurfaceColor(context),
                    AppTheme.getSurfaceColor(context).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          
          // Auto-scrolling content
          _AutoScrollingTicker(
            complaints: extendedComplaints,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCards(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(context),
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 4,
          childAspectRatio: isMobile ? 1.3 : 1.5,
          mainAxisSpacing: isMobile ? 12 : 16,
          crossAxisSpacing: isMobile ? 12 : 16,
          children: [
            // _buildActionCard(
            //   icon: Icons.person_add_outlined,
            //   title: 'Add Tenant',
            //   subtitle: 'Invite new tenant',
            //   color: const Color(0xFF4FC3F7),
            //   isMobile: isMobile,
            //   onTap: () {
            //     _showBuildingSelectionDialog(
            //       context,
            //       onBuildingSelected: (buildingId) {
            //         Navigator.push(
            //           context,
            //           CustomPageRoute(
            //             child: InviteTenantScreen(selectedBuildingId: buildingId),
            //             transition: CustomPageTransition.transform,
            //           ),
            //         ).then((result) {
            //           if (result == true) {
            //             loadDashboardData();
            //           }
            //         });
            //       },
            //     );
            //   },
            // ),
            
            // _buildActionCard(
            //   icon: Icons.add_home_outlined,
            //   title: 'Add Room',
            //   subtitle: 'Create new room',
            //   color: const Color(0xFF66BB6A),
            //   isMobile: isMobile,
            //   onTap: () {
            //     _showBuildingSelectionDialog(
            //       context,
            //       onBuildingSelected: (buildingId) {
            //         Navigator.push(
            //           context,
            //           CustomPageRoute(
            //             child: AddRoomScreen(buildingId: buildingId),
            //             transition: CustomPageTransition.transform,
            //           ),
            //         ).then((result) {
            //           if (result != null) {
            //             loadDashboardData();
            //           }
            //         });
            //       },
            //     );
            //   },
            // ),
           
            _buildActionCard(
              icon: Icons.report_problem_outlined,
              title: 'Complaints',
              subtitle: 'View & manage',
              color: const Color(0xFFFF7043),
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const ComplaintsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.payment_outlined,
              title: 'Payments',
              subtitle: 'Track payments',
              color: const Color(0xFFAB47BC),
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const PaymentsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.business_outlined,
              title: 'Buildings',
              subtitle: 'Manage properties',
              color: const Color(0xFF26A69A),
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const BuildingsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.handyman_outlined,
              title: 'Service Providers',
              subtitle: 'Manage services',
              color: const Color(0xFF5C6BC0),
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const ServiceProvidersListScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.exit_to_app_outlined,
              title: 'Vacating Requests',
              subtitle: 'Handle requests',
              color: const Color(0xFFFF5722),
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const VacatingRequestsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.assessment_outlined,
              title: 'View Reports',
              subtitle: 'Analytics & insights',
              color: const Color(0xFF8E24AA),
              isMobile: isMobile,
              onTap: () {
                // TODO: Implement reports screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reports feature coming soon!'),
                    backgroundColor: Color(0xFF8E24AA),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.build_outlined,
              title: 'Maintenance',
              subtitle: 'Service requests',
              color: const Color(0xFFD32F2F),
              isMobile: isMobile,
              onTap: () {
                // TODO: Implement maintenance screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maintenance feature coming soon!'),
                    backgroundColor: Color(0xFFD32F2F),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.people_outline,
              title: 'All Tenants',
              subtitle: 'View tenant list',
              color: const Color(0xFF00ACC1),
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const TenantsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.hotel_outlined,
              title: 'All Rooms',
              subtitle: 'View room list',
              color: const Color(0xFF43A047),
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const RoomsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Account settings',
              color: const Color(0xFF6A1B9A),
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const ProfileScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.getTextPrimaryColor(context).withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isMobile ? 36 : 40,
              height: isMobile ? 36 : 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: isMobile ? 18 : 20,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.getTextPrimaryColor(context),
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.getTextSecondaryColor(context),
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(context),
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        
        // Recent Rooms
        if (rooms.isNotEmpty) ...[
          _buildActivitySection(
            title: 'Recent Rooms',
            items: rooms.take(3).map((room) => _buildRoomActivityItem(room, isMobile)).toList(),
            onViewAll: () {
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const RoomsScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            },
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 20 : 24),
        ],
        
        // Recent Complaints
        if (complaints.isNotEmpty) ...[
          _buildActivitySection(
            title: 'Recent Complaints',
            items: complaints.take(3).map((complaint) => _buildComplaintActivityItem(complaint, isMobile)).toList(),
            onViewAll: () {
              Navigator.push(
                context,
                CustomPageRoute(
                  child: const ComplaintsScreen(),
                  transition: CustomPageTransition.transform,
                ),
              );
            },
            isMobile: isMobile,
          ),
        ],
      ],
    );
  }

  Widget _buildActivitySection({
    required String title,
    required List<Widget> items,
    required VoidCallback onViewAll,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getTextPrimaryColor(context).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildRoomActivityItem(Room room, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 48,
            height: isMobile ? 40 : 48,
            decoration: BoxDecoration(
              color: room.hasTenant ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              room.hasTenant ? Icons.check_circle : Icons.home_outlined,
              color: room.hasTenant ? Colors.green : Colors.blue,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room ${room.number}',
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(context),
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  room.hasTenant ? 'Occupied by ${room.tenant!.name}' : 'Available',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${room.rent.toStringAsFixed(0)}',
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(context),
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintActivityItem(Complaint complaint, bool isMobile) {
    Color statusColor = complaint.status == 'pending' 
        ? Colors.orange 
        : complaint.status == 'resolved' 
            ? Colors.green 
            : Colors.blue;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 48,
            height: isMobile ? 40 : 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              complaint.status == 'pending' 
                  ? Icons.pending_outlined
                  : complaint.status == 'resolved'
                      ? Icons.check_circle_outline
                      : Icons.build_outlined,
              color: statusColor,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.title,
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(context),
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Room ${complaint.roomNumber} • ${complaint.status}',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              complaint.priority.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatsSection(bool isMobile) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ModernStatMiniCard(
              title: 'Total Rooms',
              value: getTotalRooms().toString(),
              lottieUri: AppAssets.roomsLottie,
              icon: Icons.home_outlined, // Fallback icon
              color: Colors.blue,
              subtitle: 'Available spaces',
              showTrend: true,
              onTap: () {},
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: ModernStatMiniCard(
              title: 'Occupied',
              value: getOccupiedRooms().toString(),
              imageUri: AppAssets.occupiedRoomsImage,
              icon: Icons.check_circle_outline, // Fallback icon
              color: Colors.green,
              subtitle: 'Currently rented',
              heroTag: 'occupied_card',
              onTap: () {
                // Navigate to rooms screen
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const RoomsScreen(heroTag: 'occupied_card'),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: ModernStatMiniCard(
              title: 'Revenue',
              value: '₹${(getTotalRevenue() / 1000).toStringAsFixed(0)}K',
              lottieUri: AppAssets.revenueLottie,
              icon: Icons.account_balance_wallet_outlined, // Fallback icon
              color: Colors.purple,
              subtitle: 'This month',
              showTrend: true,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsListingSection(bool isMobile) {
    final displayedRooms = rooms.take(isMobile ? 3 : 6).toList();
    
    if (displayedRooms.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Rooms',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const RoomsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Show all',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 20),
        SizedBox(
          height: isMobile ? 420 : 480,
          child: PageView.builder(
            controller: _roomsPageController ?? PageController(viewportFraction: 0.9),
            scrollDirection: Axis.horizontal,
            itemCount: displayedRooms.length,
            itemBuilder: (context, index) {
              final room = displayedRooms[index];
              Tenant? tenant;
              if (tenants.isNotEmpty && room.status == 'occupied') {
                try {
                  tenant = tenants.firstWhere(
                    (t) => t.roomNumber == room.number,
                  );
                } catch (e) {
                  tenant = null;
                }
              }
              return Padding(
                padding: EdgeInsets.only(
                  right: isMobile ? 12 : 16,
                ),
                child: RoomListingCard(
                  room: room,
                  tenantName: tenant?.name,
                  buildingName: _buildings.isNotEmpty
                      ? _buildings.firstWhere(
                          (b) => b.id == room.buildingId,
                          orElse: () => Building(
                            id: room.buildingId,
                            name: 'Building',
                            address: '',
                            totalFloors: 1,
                            totalRooms: 1,
                            buildingType: 'standalone',
                            propertyType: 'rented',
                            createdAt: DateTime.now(),
                          ),
                        ).name
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: RoomDetailScreen(
                          room: room,
                          buildingName: _buildings.isNotEmpty
                              ? _buildings.firstWhere(
                                  (b) => b.id == room.buildingId,
                                  orElse: () => Building(
                                    id: room.buildingId,
                                    name: 'Building',
                                    address: '',
                                    totalFloors: 1,
                                    totalRooms: 1,
                                    buildingType: 'standalone',
                                    propertyType: 'rented',
                                    createdAt: DateTime.now(),
                                  ),
                                ).name
                              : null,
                        ),
                        transition: CustomPageTransition.containerTransform,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        // Page indicator dots
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              displayedRooms.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _roomsCurrentPage == index
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatsSection(bool isMobile, bool isTablet) {
    final isDesktop = Responsive.isDesktop(context);
    final hasPG = hasPGRooms();
    
    // Build list of stat cards conditionally
    final List<Widget> statCards = [
      ModernStatCard(
        title: 'Total Rooms',
        value: getTotalRooms().toString(),
        icon: Icons.home_outlined,
        startColor: const Color(0xFF667EEA),
        endColor: const Color(0xFF764BA2),
        percentageChange: 5.2,
        onTap: () {},
      ),
    ];
    
    // Show "Occupied" card only if property has PG rooms
    // (because for PG, occupied rooms vs active tenants can differ significantly)
    if (hasPG) {
      statCards.add(
        ModernStatCard(
          title: 'Occupied',
          value: getOccupiedRooms().toString(),
          icon: Icons.check_circle_outline,
          startColor: const Color(0xFF11998E),
          endColor: const Color(0xFF38EF7D),
          percentageChange: 2.1,
          onTap: () {
            // Navigate to rooms screen filtered by occupied status
            Navigator.push(
              context,
              CustomPageRoute(
                child: const RoomsScreen(),
                transition: CustomPageTransition.slideRight,
              ),
            );
          },
        ),
      );
    }
    
    statCards.addAll([
      ModernStatCard(
        title: 'Vacant',
        value: getVacantRooms().toString(),
        icon: Icons.hotel_outlined,
        startColor: const Color(0xFF4FACFE),
        endColor: const Color(0xFF00F2FE),
        percentageChange: -1.5,
        onTap: () {},
      ),
      ModernStatCard(
        title: 'Active Tenants',
        value: getTotalTenants().toString(),
        icon: Icons.people_outline,
        startColor: const Color(0xFFFA709A),
        endColor: const Color(0xFFFEE140),
        percentageChange: 8.3,
        heroTag: 'active_tenants_card',
        onTap: () {
          // Navigate to tenants screen to view all active tenants
          Navigator.push(
            context,
            CustomPageRoute(
              child: const TenantsScreen(heroTag: 'active_tenants_card'),
              transition: CustomPageTransition.transform,
            ),
          );
        },
      ),
      ModernStatCard(
        title: 'Total Revenue',
        value: '₹${(getTotalRevenue() / 1000).toStringAsFixed(0)}K',
        subtitle: 'This month',
        icon: Icons.account_balance_wallet_outlined,
        startColor: const Color(0xFF30CFD0),
        endColor: const Color(0xFF330867),
        percentageChange: 12.5,
        onTap: () {},
      ),
      ModernStatCard(
        title: 'Pending Revenue',
        value: '₹${(getPendingRevenue() / 1000).toStringAsFixed(0)}K',
        subtitle: 'To be collected',
        icon: Icons.pending_outlined,
        startColor: const Color(0xFFFF6B6B),
        endColor: const Color(0xFFEE5A6F),
        percentageChange: -3.2,
        onTap: () {},
      ),
      ModernStatCard(
        title: 'Pending Complaints',
        value: getPendingComplaints().toString(),
        icon: Icons.warning_amber_outlined,
        startColor: const Color(0xFFFFA726),
        endColor: const Color(0xFFFF7043),
        percentageChange: -5.0,
        heroTag: 'pending_complaints_card',
        onTap: () {
          Navigator.push(
            context,
            CustomPageRoute(
              child: const ComplaintsScreen(heroTag: 'pending_complaints_card'),
              transition: CustomPageTransition.transform,
            ),
          );
        },
      ),
      ModernStatCard(
        title: 'Overdue Payments',
        value: getOverduePayments().toString(),
        icon: Icons.error_outline,
        startColor: const Color(0xFFE91E63),
        endColor: const Color(0xFF880E4F),
        percentageChange: 1.8,
        onTap: () {},
      ),
    ]);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.getStatsCrossAxisCount(context),
      childAspectRatio: isMobile ? 1.0 : (isDesktop ? 1.2 : 1.3),
      children: statCards,
    );
  }

  Widget _buildRevenueSection(bool isMobile) {
    return RevenueChartCard(
      monthlyRevenue: getMonthlyRevenue(),
      totalRevenue: getTotalRevenue(),
      pendingRevenue: getPendingRevenue(),
    );
  }

  Widget _buildModernQuickActionsSection(bool isMobile, bool isTablet) {
    final isDesktop = Responsive.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isMobile ? 20 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : (isTablet ? 4 : 6),
          childAspectRatio: isMobile ? 1.1 : (isDesktop ? 1.0 : 1.1),
          mainAxisSpacing: isMobile ? 12 : 16,
          crossAxisSpacing: isMobile ? 12 : 16,
          children: [
            ModernQuickAction(
              label: 'Add Tenant',
              icon: Icons.person_add_outlined,
              color: Colors.blue,
              heroTag: 'add_tenant_button',
              onTap: () {
                _showBuildingSelectionDialog(
                  context,
                  onBuildingSelected: (buildingId) {
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: InviteTenantScreen(selectedBuildingId: buildingId),
                        transition: CustomPageTransition.transform,
                      ),
                    ).then((result) {
                      if (result == true) {
                        loadDashboardData();
                      }
                    });
                  },
                );
              },
            ),
            ModernQuickAction(
              label: 'Add Room',
              icon: Icons.add_home_outlined,
              color: Colors.green,
              heroTag: 'add_room_button',
              onTap: () {
                _showBuildingSelectionDialog(
                  context,
                  onBuildingSelected: (buildingId) {
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: AddRoomScreen(buildingId: buildingId),
                        transition: CustomPageTransition.transform,
                      ),
                    ).then((result) {
                      if (result != null) {
                        loadDashboardData();
                      }
                    });
                  },
                );
              },
            ),
            ModernQuickAction(
              label: 'New Complaint',
              icon: Icons.report_problem_outlined,
              color: Colors.orange,
              heroTag: 'new_complaint_button',
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const ComplaintsScreen(heroTag: 'new_complaint_button'),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            ModernQuickAction(
              label: 'Record Payment',
              icon: Icons.payment_outlined,
              color: Colors.purple,
              heroTag: 'record_payment_button',
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const PaymentsScreen(heroTag: 'record_payment_button'),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            ModernQuickAction(
              label: 'View Reports',
              icon: Icons.assessment_outlined,
              color: Colors.teal,
              onTap: () {},
            ),
            ModernQuickAction(
              label: 'Maintenance',
              icon: Icons.build_outlined,
              color: Colors.red,
              onTap: () {},
            ),
            ModernQuickAction(
              label: 'Service Providers',
              icon: Icons.handyman,
              color: Colors.indigo,
              heroTag: 'service_providers_button',
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const ServiceProvidersListScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
            ModernQuickAction(
              label: 'Vacating Requests',
              icon: Icons.exit_to_app,
              color: Colors.deepOrange,
              heroTag: 'vacating_requests_button',
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const VacatingRequestsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Room Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isMobile ? 20 : 22,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(88, 44),
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 20),
        ...rooms.take(isMobile ? 4 : 6).map((room) => RoomStatusCard(
              room: room,
              onTap: () {},
            )),
      ],
    );
  }

  Widget _buildComplaintsSection(bool isMobile) {
    final recentComplaints = complaints.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Complaints',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isMobile ? 20 : 22,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const ComplaintsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(88, 44),
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 20),
        if (recentComplaints.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No complaints',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else ...[
          SizedBox(
            height: isMobile ? 240 : 280,
            child: PageView.builder(
              controller: _complaintsPageController ?? PageController(viewportFraction: 0.9),
              scrollDirection: Axis.horizontal,
              itemCount: recentComplaints.length,
              itemBuilder: (context, index) {
                final complaint = recentComplaints[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: isMobile ? 12 : 16,
                  ),
                  child: ComplaintCard(
                    complaint: complaint,
                    onTap: () async {
                      // Navigate to detail screen
                      debugPrint('Dashboard: Navigating to complaint detail for ${complaint.title}');
                      final result = await Navigator.push(
                        context,
                        CustomPageRoute(
                          child: ComplaintDetailScreen(complaint: complaint),
                          transition: CustomPageTransition.containerTransform,
                        ),
                      );
                      debugPrint('Dashboard: Navigation returned with result: $result');
                      
                      // Reload complaints if updated
                      if (result == true) {
                        await loadDashboardData();
                      }
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          // Page indicator dots
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                recentComplaints.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _complaintsCurrentPage == index
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentPaymentsSection(bool isMobile) {
    final recentPayments = payments.take(isMobile ? 3 : 5).toList();
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Payments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isMobile ? 20 : 22,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(88, 44),
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 20),
        ...recentPayments.map((payment) {
          final statusColor = payment.status == 'paid'
              ? Colors.green
              : payment.status == 'overdue'
                  ? Colors.red
                  : Colors.orange;
          final theme = Theme.of(context);
          
          return Card(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 0 : 4,
              vertical: isMobile ? 8 : 10,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                splashColor: statusColor.withOpacity(0.1),
                highlightColor: statusColor.withOpacity(0.05),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Row(
                    children: [
                      Container(
                        width: isMobile ? 56 : 64,
                        height: isMobile ? 56 : 64,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          payment.status == 'paid'
                              ? Icons.check_circle
                              : payment.status == 'overdue'
                                  ? Icons.error_outline
                                  : Icons.pending_outlined,
                          color: statusColor,
                          size: isMobile ? 28 : 32,
                        ),
                      ),
                      SizedBox(width: isMobile ? 16 : 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.tenantName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: isMobile ? 16 : 18,
                              ),
                            ),
                            SizedBox(height: isMobile ? 6 : 8),
                            Wrap(
                              spacing: isMobile ? 8 : 12,
                              runSpacing: isMobile ? 6 : 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.room_outlined,
                                      size: isMobile ? 14 : 16,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                    SizedBox(width: isMobile ? 4 : 6),
                                    Text(
                                      'Room ${payment.roomNumber}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: isMobile ? 13 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: isMobile ? 14 : 16,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                    SizedBox(width: isMobile ? 4 : 6),
                                    Flexible(
                                      child: Text(
                                        dateFormat.format(payment.dueDate),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: isMobile ? 13 : 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '₹${payment.amount.toStringAsFixed(0)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: isMobile ? 18 : 20,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isMobile ? 6 : 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 10 : 12,
                                vertical: isMobile ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                payment.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (recentPayments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No payments',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showBuildingSelectionDialog(
    BuildContext context, {
    required Function(String buildingId) onBuildingSelected,
  }) async {
    List<Building> buildings = _buildings;
    
    // Load buildings if not loaded
    if (buildings.isEmpty) {
      try {
        final ownerId = AuthService.getOwnerId();
        final buildingsResponse = await ApiService.fetchBuildingsByOwnerId(ownerId);
        buildings = ApiService.parseBuildings(buildingsResponse);
        setState(() {
          _buildings = buildings;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading buildings: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (buildings.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No buildings found. Please add a building first.'),
            backgroundColor: Colors.orange,
          ),
        );
        // Navigate to add building screen
        Navigator.push(
          context,
          CustomPageRoute(
            child: const BuildingsScreen(),
            transition: CustomPageTransition.transform,
          ),
        );
      }
      return;
    }

    // If only one building, use it directly without showing dialog
    if (buildings.length == 1) {
      onBuildingSelected(buildings.first.id);
      return;
    }

    // Show dialog only for multiple buildings
    if (!mounted) return;
    
    final selectedBuilding = await showDialog<Building>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Building'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: buildings.length,
            itemBuilder: (context, index) {
              final building = buildings[index];
              return ListTile(
                leading: Icon(
                  Icons.business,
                  color: AppTheme.primaryColor,
                ),
                title: Text(
                  building.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(building.address),
                onTap: () {
                  Navigator.pop(context, building);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedBuilding != null) {
      onBuildingSelected(selectedBuilding.id);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(bool isMobile) {
    return Drawer(
      backgroundColor: AppTheme.getCardColor(context),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OwnHouse',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Property Management',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.business_outlined,
                    title: 'Buildings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: const BuildingsScreen(),
                          transition: CustomPageTransition.transform,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.hotel_outlined,
                    title: 'Rooms',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: const RoomsScreen(),
                          transition: CustomPageTransition.transform,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    title: 'Tenants',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: const TenantsScreen(),
                          transition: CustomPageTransition.transform,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.report_problem_outlined,
                    title: 'Complaints',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: const ComplaintsScreen(),
                          transition: CustomPageTransition.transform,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.payment_outlined,
                    title: 'Payments',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: const PaymentsScreen(),
                          transition: CustomPageTransition.transform,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.handyman_outlined,
                    title: 'Service Providers',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: const ServiceProvidersListScreen(),
                          transition: CustomPageTransition.transform,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.exit_to_app_outlined,
                    title: 'Vacating Requests',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: const VacatingRequestsScreen(),
                          transition: CustomPageTransition.transform,
                        ),
                      );
                    },
                  ),
                  Divider(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.3)),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: const ProfileScreen(),
                          transition: CustomPageTransition.transform,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: const SettingsScreen(),
                          transition: CustomPageTransition.transform,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout_outlined,
                    title: 'Logout',
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.getTextSecondaryColor(context),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.getTextPrimaryColor(context),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        _showQuickActionDialog();
      },
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text(
        'Quick Add',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showQuickActionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.getTextSecondaryColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quick Actions',
              style: TextStyle(
                color: AppTheme.getTextPrimaryColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildQuickActionButton(
                  icon: Icons.person_add_outlined,
                  title: 'Add Tenant',
                  color: const Color(0xFF4FC3F7),
                  onTap: () {
                    Navigator.pop(context);
                    _showBuildingSelectionDialog(
                      context,
                      onBuildingSelected: (buildingId) {
                        Navigator.push(
                          context,
                          CustomPageRoute(
                            child: InviteTenantScreen(selectedBuildingId: buildingId),
                            transition: CustomPageTransition.transform,
                          ),
                        );
                      },
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.add_home_outlined,
                  title: 'Add Room',
                  color: const Color(0xFF66BB6A),
                  onTap: () {
                    Navigator.pop(context);
                    _showBuildingSelectionDialog(
                      context,
                      onBuildingSelected: (buildingId) {
                        Navigator.push(
                          context,
                          CustomPageRoute(
                            child: AddRoomScreen(buildingId: buildingId),
                            transition: CustomPageTransition.transform,
                          ),
                        );
                      },
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.business_outlined,
                  title: 'Add Building',
                  color: const Color(0xFF26A69A),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: const BuildingsScreen(),
                        transition: CustomPageTransition.transform,
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.handyman_outlined,
                  title: 'Service Provider',
                  color: const Color(0xFF5C6BC0),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: const RegisterServiceProviderScreen(),
                        transition: CustomPageTransition.transform,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Auto-scrolling ticker widget for complaints
class _AutoScrollingTicker extends StatefulWidget {
  final List<Complaint> complaints;
  final bool isMobile;

  const _AutoScrollingTicker({
    required this.complaints,
    required this.isMobile,
  });

  @override
  State<_AutoScrollingTicker> createState() => _AutoScrollingTickerState();
}

class _AutoScrollingTickerState extends State<_AutoScrollingTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Create animation controller for continuous scrolling
    _controller = AnimationController(
      duration: const Duration(seconds: 45), // 45 seconds for full cycle
      vsync: this,
    );

    // Start the animation after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!mounted || widget.complaints.isEmpty) return;
    
    // Wait for the widget to be fully built
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      // Calculate total scroll distance
      final itemWidth = 220.0 + 80.0; // item width + margins
      final totalWidth = widget.complaints.length * itemWidth;
      
      _animation = Tween<double>(
        begin: 0.0,
        end: totalWidth / 2, // Scroll to halfway point for seamless loop
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ));

      _animation.addListener(() {
        if (_scrollController.hasClients && mounted) {
          _scrollController.jumpTo(_animation.value);
        }
      });

      _animation.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // Reset to beginning for seamless loop
          _controller.reset();
          _controller.forward();
        }
      });

      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: widget.complaints.asMap().entries.map((entry) {
          final complaint = entry.value;
          
          return GestureDetector(
            onTap: () {
              // Navigate to complaint detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComplaintDetailScreen(
                    complaint: complaint,
                  ),
                ),
              );
            },
            child: Container(
              width: 220,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: complaint.priority == 'high' 
                                ? const Color(0xFFEF4444)
                                : complaint.priority == 'urgent'
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            complaint.title,
                            style: TextStyle(
                              color: AppTheme.getTextPrimaryColor(context),
                              fontSize: widget.isMobile ? 12 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Raised by: ${complaint.tenantName} • Rm ${complaint.roomNumber}',
                      style: TextStyle(
                        color: const Color(0xFF6366F1), // Indigo color for tenant name
                        fontSize: widget.isMobile ? 10 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(complaint.createdAt),
                          style: TextStyle(
                            color: AppTheme.getTextSecondaryColor(context),
                            fontSize: widget.isMobile ? 8 : 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}