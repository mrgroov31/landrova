import 'package:flutter/material.dart';
import 'package:own_house/models/room.dart';
import '../models/api_tenant.dart';
import '../models/building.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'invite_tenant_screen.dart';
import 'tenant_detail_screen.dart';
import 'package:intl/intl.dart';

class TenantsScreen extends StatefulWidget {
  final String? heroTag;
  final String? selectedBuildingId;
  
  const TenantsScreen({super.key, this.heroTag, this.selectedBuildingId});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  List<ApiTenant> tenants = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTenants();
  }

  Future<void> loadTenants() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      // WORKAROUND: Using rooms API to get tenant data
      // The tenants API endpoint has a database schema issue: "column t.room_number does not exist"
      // TODO: Fix the backend API to properly handle the tenants endpoint
      // Expected API: GET /api/owners/{owner_id}/tenants
      // Current workaround: Extract tenant data from rooms API response
      final ownerId = AuthService.getOwnerId();
      debugPrint('👥 [TenantsScreen] Using rooms API workaround due to tenants API schema issue');
      debugPrint('👥 [TenantsScreen] Backend error: "column t.room_number does not exist"');
      
      final roomsResponse = await ApiService.fetchRoomsByOwnerId(ownerId);
      final rooms = ApiService.parseRooms(roomsResponse);
      
      // Extract tenants from rooms that have tenant data
      var extractedTenants = <ApiTenant>[];
      for (final room in rooms) {
        if (room.hasTenant && room.tenant != null) {
          // Convert RoomTenant to ApiTenant using helper method
          final apiTenant = _convertRoomTenantToApiTenant(room, null);
          extractedTenants.add(apiTenant);
        }
      }
      
      debugPrint('👥 [TenantsScreen] Extracted ${extractedTenants.length} tenants from rooms');
      
      // Get building names for the tenants
      if (extractedTenants.isNotEmpty) {
        try {
          final buildingsResponse = await ApiService.fetchBuildingsByOwnerId(ownerId);
          final buildings = ApiService.parseBuildings(buildingsResponse);
          final buildingMap = {for (var b in buildings) b.id: b};
          
          // Update tenants with building information
          final roomsMap = {for (var r in rooms) r.id: r};
          extractedTenants = extractedTenants.map((tenant) {
            final building = buildingMap[tenant.buildingId];
            final room = roomsMap[tenant.roomId];
            if (building != null && room != null) {
              final tenantBuilding = TenantBuilding(
                id: building.id,
                name: building.name,
                address: building.address,
                city: building.city,
                state: building.state,
                pincode: building.pincode,
              );
              return _convertRoomTenantToApiTenant(room, tenantBuilding);
            }
            return tenant;
          }).toList();
        } catch (e) {
          debugPrint('⚠️ [TenantsScreen] Could not load building names: $e');
        }
      }
      
      // Filter by building if selected
      if (widget.selectedBuildingId != null && widget.selectedBuildingId!.isNotEmpty) {
        debugPrint('👥 [TenantsScreen] Filtering by buildingId: ${widget.selectedBuildingId}');
        final beforeFilter = extractedTenants.length;
        extractedTenants = extractedTenants.where((t) => t.buildingId == widget.selectedBuildingId).toList();
        debugPrint('👥 [TenantsScreen] Filtered from $beforeFilter to ${extractedTenants.length} tenants');
      }
      
      setState(() {
        tenants = extractedTenants;
        isLoading = false;
      });
      
      debugPrint('👥 [TenantsScreen] Successfully loaded ${extractedTenants.length} tenants from rooms API');
    } catch (e) {
      debugPrint('❌ [TenantsScreen] Error loading tenants: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Helper method to convert RoomTenant to ApiTenant
  ApiTenant _convertRoomTenantToApiTenant(Room room, TenantBuilding? building) {
    final roomTenant = room.tenant!;
    return ApiTenant(
      tenantId: roomTenant.id,
      buildingId: room.buildingId,
      roomId: room.id,
      name: roomTenant.name,
      email: roomTenant.email,
      phone: roomTenant.phone,
      roomNumber: room.number,
      monthlyRent: room.rent,
      type: room.type == 'pg' ? 'paying_guest' : 'tenant',
      moveInDate: roomTenant.moveInDate,
      leaseEndDate: roomTenant.leaseEndDate,
      isActive: roomTenant.isActive,
      building: building,
      // Additional fields that might be available
      occupation: null, // Not available in room data
      aadharNumber: null, // Not available in room data
      emergencyContact: null, // Not available in room data
      depositPaid: room.rent * 2, // Estimate: 2 months rent
      createdAt: null, // Not available in room data
      updatedAt: null, // Not available in room data
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        title: const Text(
          'Tenants',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary section
          if (!isLoading && tenants.isNotEmpty) _buildSummarySection(isMobile),
          
          // Main content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('Error: $error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: loadTenants,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : tenants.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No tenants found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Invite tenants to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadTenants,
                            child: ListView.builder(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              itemCount: tenants.length,
                              itemBuilder: (context, index) {
                                final tenant = tenants[index];
                                return _buildTenantCard(tenant, dateFormat, isMobile);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            CustomPageRoute(
              child: const InviteTenantScreen(),
              transition: CustomPageTransition.transform,
            ),
          );
          
          // Reload tenants if a new one was added
          if (result == true) {
            loadTenants();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Invite Tenant',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTenantCard(ApiTenant tenant, DateFormat dateFormat, bool isMobile) {
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to tenant detail screen
          Navigator.push(
            context,
            CustomPageRoute(
              child: TenantDetailScreen(tenant: tenant),
              transition: CustomPageTransition.containerTransform,
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and basic info
              Row(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 28 : 32,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : 'T',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 16 : 18,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tenant.typeDisplayName,
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tenant.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tenant.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: tenant.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isMobile ? 12 : 16),
              
              // Room and building info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.room,
                      'Room ${tenant.roomNumber}',
                      isMobile,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.business,
                      tenant.buildingName,
                      isMobile,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isMobile ? 8 : 12),
              
              // Contact and rent info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.phone,
                      tenant.phone,
                      isMobile,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.currency_rupee,
                      '₹${tenant.monthlyRent.toStringAsFixed(0)}/mo',
                      isMobile,
                    ),
                  ),
                ],
              ),
              
              if (tenant.moveInDate != null) ...[
                SizedBox(height: isMobile ? 8 : 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Moved in: ${dateFormat.format(tenant.moveInDate!)}',
                  isMobile,
                ),
              ],
              
              if (tenant.occupation != null && tenant.occupation!.isNotEmpty) ...[
                SizedBox(height: isMobile ? 8 : 12),
                _buildInfoRow(
                  Icons.work,
                  tenant.occupation!,
                  isMobile,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(bool isMobile) {
    final activeTenants = tenants.where((t) => t.isActive).length;
    final inactiveTenants = tenants.length - activeTenants;
    final buildings = tenants.map((t) => t.buildingId).toSet().length;
    
    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total',
              tenants.length.toString(),
              Icons.people,
              AppTheme.primaryColor,
              isMobile,
            ),
          ),
          Container(
            width: 1,
            height: isMobile ? 40 : 50,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildSummaryItem(
              'Active',
              activeTenants.toString(),
              Icons.check_circle,
              Colors.green,
              isMobile,
            ),
          ),
          if (inactiveTenants > 0) ...[
            Container(
              width: 1,
              height: isMobile ? 40 : 50,
              color: Colors.grey.shade300,
            ),
            Expanded(
              child: _buildSummaryItem(
                'Inactive',
                inactiveTenants.toString(),
                Icons.cancel,
                Colors.red,
                isMobile,
              ),
            ),
          ],
          Container(
            width: 1,
            height: isMobile ? 40 : 50,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildSummaryItem(
              'Buildings',
              buildings.toString(),
              Icons.business,
              Colors.blue,
              isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color, bool isMobile) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: isMobile ? 20 : 24,
        ),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isMobile) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}