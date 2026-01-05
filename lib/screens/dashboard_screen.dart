import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../models/room.dart';
import '../models/complaint.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../services/complaint_service.dart';
import '../widgets/modern_stat_card.dart';
import '../widgets/modern_stat_mini_card.dart';
import '../widgets/revenue_chart_card.dart';
import '../widgets/modern_quick_action.dart';
import '../widgets/hero_section.dart';
import '../widgets/room_listing_card.dart';
import '../widgets/room_status_card.dart';
import '../widgets/complaint_card.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'rooms_screen.dart';
import 'tenants_screen.dart';
import 'complaints_screen.dart';
import 'complaint_detail_screen.dart';
import 'payments_screen.dart';
import 'buildings_screen.dart';
import 'profile_screen.dart';
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
import 'dart:io';

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
      ]);

      // Load complaints from ComplaintService (which merges API and Hive data)
      final allComplaints = await ComplaintService.getAllComplaints();

      setState(() {
        var allRooms = ApiService.parseRooms(results[0]);
        debugPrint('📊 [Dashboard] Parsed ${allRooms.length} rooms from API');
        var allTenants = ApiService.parseTenants(results[1]);
        var allPayments = ApiService.parsePayments(results[2]);
        
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
            duration: const Duration(seconds: 3),
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
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'OwnHouse',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 22,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Building Selector
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.business),
              onPressed: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const BuildingsScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
              },
              tooltip: 'Select Building',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
              tooltip: 'Settings',
            ),
          ),
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: const ProfileScreen(),
                        transition: CustomPageTransition.transform,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 20, color: AppTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Owner',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Profile button for mobile
          if (isMobile)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.push(
                    context,
                    CustomPageRoute(
                      child: const ProfileScreen(),
                      transition: CustomPageTransition.transform,
                    ),
                  );
                },
                tooltip: 'Profile',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: isMobile ? 16 : 24,
          right: isMobile ? 16 : 24,
          top: isMobile ? 16 : 24,
          bottom: isMobile ? 16 : 24, // Remove extra padding since no nav bar
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 1400,
            ),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Section with Search
                      HeroSection(
                        greeting: 'Hey, Owner! 👋',
                        subtitle: 'Here\'s what\'s happening with your property today',
                        onSearchTap: () {},
                      ),

                      // Mini Stats Row
                      _buildMiniStatsSection(isMobile),

                SizedBox(height: isMobile ? 24 : 28),

                // Main Stats Cards
                _buildModernStatsSection(isMobile, isTablet),

                SizedBox(height: isMobile ? 24 : 28),

                // Revenue Chart
                if (!isMobile) _buildRevenueSection(isMobile),

                if (!isMobile) SizedBox(height: isMobile ? 24 : 28),

                // Rooms Section - Listing Style
                _buildRoomsListingSection(isMobile),

                SizedBox(height: isMobile ? 24 : 28),

                // Quick Actions
                _buildModernQuickActionsSection(isMobile, isTablet),

                SizedBox(height: isMobile ? 24 : 28),

                      // Main Content Grid
                      if (isMobile)
                        Column(
                          children: [
                            _buildRoomsSection(isMobile),
                            const SizedBox(height: 24),
                            _buildComplaintsSection(isMobile),
                            const SizedBox(height: 24),
                            _buildRecentPaymentsSection(isMobile),
                          ],
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      _buildRoomsSection(isMobile),
                                      const SizedBox(height: 24),
                                      _buildRecentPaymentsSection(isMobile),
                                    ],
                                  ),
                                ),
                                SizedBox(width: isTablet ? 16 : 20),
                                Expanded(
                                  flex: 1,
                                  child: _buildComplaintsSection(isMobile),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
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
}

