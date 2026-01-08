import 'package:flutter/material.dart';
import '../models/building.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/complaint.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../services/complaint_service.dart';
import '../widgets/modern_stat_mini_card.dart';
import '../widgets/modern_quick_action.dart';
import '../widgets/room_listing_card.dart';
import '../widgets/complaint_card.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'rooms_screen.dart';
import 'tenants_screen.dart';
import 'complaints_screen.dart';
import 'payments_screen.dart';
import 'add_room_screen.dart';
import 'complaint_detail_screen.dart';
import 'room_detail_screen.dart';
import 'dart:io';

class BuildingDetailScreen extends StatefulWidget {
  final Building building;

  const BuildingDetailScreen({
    super.key,
    required this.building,
  });

  @override
  State<BuildingDetailScreen> createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen> {
  List<Room> rooms = [];
  List<Tenant> tenants = [];
  List<Complaint> complaints = [];
  List<Payment> payments = [];
  bool isLoading = true;
  PageController? _roomsPageController;
  PageController? _complaintsPageController;
  int _roomsCurrentPage = 0;
  int _complaintsCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    _roomsPageController = PageController(viewportFraction: 0.9);
    _complaintsPageController = PageController(viewportFraction: 0.9);

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

    loadBuildingData();
  }

  @override
  void dispose() {
    _roomsPageController?.dispose();
    _complaintsPageController?.dispose();
    super.dispose();
  }

  Future<void> loadBuildingData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load all data in parallel
      final results = await Future.wait([
        ApiService.fetchRooms(),
        ApiService.fetchTenants(),
        ApiService.fetchPayments(),
      ]);

      // Load complaints from ComplaintService
      final allComplaints = await ComplaintService.getAllComplaints();

      setState(() {
        var allRooms = ApiService.parseRooms(results[0]);
        var allTenants = ApiService.parseTenants(results[1]);
        var allPayments = ApiService.parsePayments(results[2]);

        // Filter by building ID
        rooms = allRooms.where((r) => r.buildingId == widget.building.id).toList();
        
        // Filter tenants, complaints, and payments based on room numbers in this building
        final roomNumbers = rooms.map((r) => r.number).toSet();
        tenants = allTenants.where((t) => roomNumbers.contains(t.roomNumber)).toList();
        complaints = allComplaints.where((c) => roomNumbers.contains(c.roomNumber)).toList();
        payments = allPayments.where((p) => roomNumbers.contains(p.roomNumber)).toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading building data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int get totalRooms => rooms.length;
  int get occupiedRooms => rooms.where((r) => r.currentOccupancy > 0).length;
  int get totalTenants => tenants.length;
  double get totalRevenue => payments.fold(0.0, (sum, p) => sum + p.amount);
  int get pendingComplaints => complaints.where((c) => c.status == 'pending').length;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // App Bar with Building Info
          SliverAppBar(
            expandedHeight: isMobile ? 200 : 250,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.building.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Building Image or Gradient
                  widget.building.image != null && File(widget.building.image!).existsSync()
                      ? Image.file(
                          File(widget.building.image!),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                  // Dark overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  // Building Info
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.building.address,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.building.city != null || widget.building.state != null)
                          Text(
                            '${widget.building.city ?? ''}${widget.building.city != null && widget.building.state != null ? ', ' : ''}${widget.building.state ?? ''}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  // TODO: Navigate to edit building screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit building feature coming soon')),
                  );
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Building Details Card
                      _buildBuildingDetailsCard(isMobile),

                      // Statistics Cards
                      Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: isMobile ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimaryColor(context),
                              ),
                            ),
                            SizedBox(height: isMobile ? 16 : 20),
                            _buildStatsSection(isMobile),
                            SizedBox(height: isMobile ? 24 : 32),
                            
                            // Quick Actions
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: isMobile ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimaryColor(context),
                              ),
                            ),
                            SizedBox(height: isMobile ? 16 : 20),
                            _buildQuickActionsSection(isMobile),
                            SizedBox(height: isMobile ? 24 : 32),

                            // Available Rooms
                            if (rooms.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Available Rooms',
                                    style: TextStyle(
                                      fontSize: isMobile ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.getTextPrimaryColor(context),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            CustomPageRoute(
                                              child: AddRoomScreen(buildingId: widget.building.id),
                                              transition: CustomPageTransition.transform,
                                            ),
                                          );
                                          if (result != null) {
                                            loadBuildingData();
                                          }
                                        },
                                        tooltip: 'Add Room',
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            CustomPageRoute(
                                              child: RoomsScreen(selectedBuildingId: widget.building.id),
                                              transition: CustomPageTransition.transform,
                                            ),
                                          );
                                        },
                                        child: const Text('View All'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 16 : 20),
                              _buildRoomsSection(isMobile),
                              SizedBox(height: isMobile ? 24 : 32),
                            ],

                            // Recent Complaints
                            if (complaints.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Complaints',
                                    style: TextStyle(
                                      fontSize: isMobile ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.getTextPrimaryColor(context),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CustomPageRoute(
                                          child: ComplaintsScreen(selectedBuildingId: widget.building.id),
                                          transition: CustomPageTransition.transform,
                                        ),
                                      );
                                    },
                                    child: const Text('View All'),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 16 : 20),
                              _buildComplaintsSection(isMobile),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingDetailsCard(bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Building Details',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildDetailRow('Property Type', widget.building.propertyTypeDisplayName, isMobile),
          _buildDetailRow('Building Type', widget.building.buildingType.toUpperCase(), isMobile),
          _buildDetailRow('Total Floors', widget.building.totalFloors.toString(), isMobile),
          _buildDetailRow('Total Rooms', widget.building.totalRooms.toString(), isMobile),
          if (widget.building.description != null && widget.building.description!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.building.description!,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.building.facilities.isNotEmpty) ...[
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'Facilities',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.building.facilities.map((facility) {
                return Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        facility.name,
                        style: TextStyle(
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      if (facility.isPaid) ...[
                        SizedBox(width: 4),
                        Icon(Icons.attach_money, size: 14, color: Colors.orange),
                      ],
                    ],
                  ),
                  backgroundColor: facility.isPaid 
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 100 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 13 : 15,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 13 : 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      mainAxisSpacing: isMobile ? 12 : 16,
      crossAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile ? 1.1 : 1.2,
      children: [
        ModernStatMiniCard(
          title: 'Total Rooms',
          value: totalRooms.toString(),
          icon: Icons.door_front_door,
          color: Colors.blue,
        ),
        ModernStatMiniCard(
          title: 'Occupied',
          value: occupiedRooms.toString(),
          icon: Icons.people,
          color: Colors.green,
        ),
        ModernStatMiniCard(
          title: 'Tenants',
          value: totalTenants.toString(),
          icon: Icons.person,
          color: Colors.purple,
        ),
        ModernStatMiniCard(
          title: 'Revenue',
          value: '₹${totalRevenue.toStringAsFixed(0)}',
          icon: Icons.currency_rupee,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      mainAxisSpacing: isMobile ? 12 : 16,
      crossAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile ? 1.3 : 1.4,
      children: [
        ModernQuickAction(
          icon: Icons.door_front_door,
          label: 'Rooms',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              CustomPageRoute(
                child: RoomsScreen(selectedBuildingId: widget.building.id),
                transition: CustomPageTransition.transform,
              ),
            );
          },
        ),
        ModernQuickAction(
          icon: Icons.people,
          label: 'Tenants',
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              CustomPageRoute(
                child: TenantsScreen(selectedBuildingId: widget.building.id),
                transition: CustomPageTransition.transform,
              ),
            );
          },
        ),
        ModernQuickAction(
          icon: Icons.report_problem,
          label: pendingComplaints > 0 
              ? 'Complaints ($pendingComplaints)'
              : 'Complaints',
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              CustomPageRoute(
                child: ComplaintsScreen(selectedBuildingId: widget.building.id),
                transition: CustomPageTransition.transform,
              ),
            );
          },
        ),
        ModernQuickAction(
          icon: Icons.payment,
          label: 'Payments',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              CustomPageRoute(
                child: PaymentsScreen(selectedBuildingId: widget.building.id),
                transition: CustomPageTransition.transform,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoomsSection(bool isMobile) {
    final availableRooms = rooms.where((r) => r.currentOccupancy < r.capacity).take(5).toList();
    
    if (availableRooms.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No available rooms',
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(context),
              fontSize: isMobile ? 14 : 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: isMobile ? 200 : 240,
      child: PageView.builder(
        controller: _roomsPageController,
        itemCount: availableRooms.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
            child: RoomListingCard(
              room: availableRooms[index],
              buildingName: widget.building.name,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: RoomDetailScreen(
                      room: availableRooms[index],
                      buildingName: widget.building.name,
                    ),
                    transition: CustomPageTransition.containerTransform,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildComplaintsSection(bool isMobile) {
    final recentComplaints = complaints.take(5).toList();
    
    if (recentComplaints.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No complaints',
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(context),
              fontSize: isMobile ? 14 : 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: isMobile ? 140 : 160,
      child: PageView.builder(
        controller: _complaintsPageController,
        itemCount: recentComplaints.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
            child: ComplaintCard(
              complaint: recentComplaints[index],
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  CustomPageRoute(
                    child: ComplaintDetailScreen(complaint: recentComplaints[index]),
                    transition: CustomPageTransition.containerTransform,
                  ),
                );
                if (result == true) {
                  loadBuildingData();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

