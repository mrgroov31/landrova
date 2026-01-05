import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/building.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/room_listing_card.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'add_room_screen.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends StatefulWidget {
  final String? heroTag;
  final String? selectedBuildingId;
  
  const RoomsScreen({super.key, this.heroTag, this.selectedBuildingId});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<Room> rooms = [];
  Map<String, String> buildingNames = {}; // Map of buildingId to building name
  bool isLoading = true;
  String? error;
  String statusFilter = 'all'; // all, occupied, vacant, maintenance

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    
    try {
      // Load buildings first, then rooms to ensure building names are available
      await loadBuildings();
      await loadRooms();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> loadBuildings() async {
    try {
      final ownerId = AuthService.getOwnerId();
      debugPrint('🏢 [RoomsScreen] Loading buildings for ownerId: $ownerId');
      
      final response = await ApiService.fetchBuildingsByOwnerId(ownerId);
      final buildings = ApiService.parseBuildings(response);
      
      debugPrint('🏢 [RoomsScreen] Loaded ${buildings.length} buildings');
      for (var building in buildings) {
        debugPrint('🏢 [RoomsScreen] Building: ${building.id} -> ${building.name}');
      }
      
      setState(() {
        buildingNames = {
          for (var building in buildings) building.id: building.name
        };
      });
      
      debugPrint('🏢 [RoomsScreen] Building names map: $buildingNames');
    } catch (e) {
      debugPrint('❌ [RoomsScreen] Error loading buildings: $e');
      // Don't throw here, let rooms load even if buildings fail
    }
  }

  Future<void> loadRooms() async {
    try {
      // Fetch rooms from API using owner ID
      final ownerId = AuthService.getOwnerId();
      debugPrint('🏠 [RoomsScreen] Loading rooms for ownerId: $ownerId');
      
      final response = await ApiService.fetchRoomsByOwnerId(ownerId);
      debugPrint('🏠 [RoomsScreen] API response received');
      
      var loadedRooms = ApiService.parseRooms(response);
      debugPrint('🏠 [RoomsScreen] Parsed ${loadedRooms.length} rooms');
      
      // Filter by building if selected
      if (widget.selectedBuildingId != null && widget.selectedBuildingId!.isNotEmpty) {
        debugPrint('🏠 [RoomsScreen] Filtering by buildingId: ${widget.selectedBuildingId}');
        final beforeFilter = loadedRooms.length;
        loadedRooms = loadedRooms.where((r) => r.buildingId == widget.selectedBuildingId).toList();
        debugPrint('🏠 [RoomsScreen] Filtered from $beforeFilter to ${loadedRooms.length} rooms');
      }
      
      debugPrint('🏠 [RoomsScreen] Setting ${loadedRooms.length} rooms in state');
      setState(() {
        rooms = loadedRooms;
        isLoading = false;
      });
      
      if (loadedRooms.isEmpty) {
        debugPrint('⚠️ [RoomsScreen] No rooms found! Check API response structure.');
      }
    } catch (e) {
      debugPrint('❌ [RoomsScreen] Error loading rooms: $e');
      throw e; // Re-throw to be handled by loadData
    }
  }

  List<Room> get filteredRooms {
    // Filter by status only
    if (statusFilter == 'all') return rooms;
    return rooms.where((room) => room.status == statusFilter).toList();
  }

  List<Room> get occupiedRoomsWithTenants {
    return rooms.where((room) => room.hasTenant).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Rooms',
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Tenant Carousel Section
          // if (!isLoading) ...[
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         // Row(
          //         //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         //   children: [
          //         //     Text(
          //         //       'Current Tenants',
          //         //       style: TextStyle(
          //         //         fontSize: isMobile ? 18 : 20,
          //         //         fontWeight: FontWeight.bold,
          //         //         color: Colors.grey.shade800,
          //         //       ),
          //         //     ),
          //         //     Text(
          //         //       '${occupiedRoomsWithTenants.length} tenant${occupiedRoomsWithTenants.length != 1 ? 's' : ''}',
          //         //       style: TextStyle(
          //         //         fontSize: isMobile ? 14 : 16,
          //         //         color: Colors.grey.shade600,
          //         //       ),
          //         //     ),
          //         //   ],
          //         // ),
          //         // const SizedBox(height: 12),
                  
          //         // Tenant cards or empty state
          //         if (occupiedRoomsWithTenants.isNotEmpty)
          //           SizedBox(
          //             height: isMobile ? 140 : 160,
          //             child: ListView.builder(
          //               scrollDirection: Axis.horizontal,
          //               itemCount: occupiedRoomsWithTenants.length,
          //               itemBuilder: (context, index) {
          //                 final room = occupiedRoomsWithTenants[index];
          //                 final tenant = room.tenant!;
          //                 final buildingName = buildingNames[room.buildingId] ?? 'Building';
                          
          //                 return Container(
          //                   width: isMobile ? 280 : 320,
          //                   margin: EdgeInsets.only(
          //                     right: 12,
          //                     left: index == 0 ? 4 : 0,
          //                   ),
          //                   child: _buildTenantCard(room, tenant, buildingName, isMobile),
          //                 );
          //               },
          //             ),
          //           )
          //         else
          //           Container(
          //             height: isMobile ? 80 : 100,
          //             decoration: BoxDecoration(
          //               color: Colors.grey.shade50,
          //               borderRadius: BorderRadius.circular(12),
          //               border: Border.all(color: Colors.grey.shade200),
          //             ),
          //             child: Center(
          //               child: Column(
          //                 mainAxisAlignment: MainAxisAlignment.center,
          //                 children: [
          //                   Icon(
          //                     Icons.people_outline,
          //                     color: Colors.grey.shade400,
          //                     size: isMobile ? 24 : 28,
          //                   ),
          //                   const SizedBox(height: 8),
          //                   Text(
          //                     'No tenants currently',
          //                     style: TextStyle(
          //                       color: Colors.grey.shade600,
          //                       fontSize: isMobile ? 14 : 16,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ),
          //       ],
          //     ),
          //   ),
          //   const SizedBox(height: 16),
          // ],
          
          // Filter Chips - Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip('All', 'all', isMobile),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Occupied', 'occupied', isMobile),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Vacant', 'vacant', isMobile),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Maintenance', 'maintenance', isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rooms List
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
                              onPressed: loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredRooms.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No rooms found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadData,
                            child: ListView.builder(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              itemCount: filteredRooms.length,
                              itemBuilder: (context, index) {
                                final room = filteredRooms[index];
                                final buildingName = buildingNames[room.buildingId] ?? 'Building';
                                
                                // Debug logging for building name mapping
                                debugPrint('🏠 [UI] Room ${room.number} (buildingId: ${room.buildingId}) -> buildingName: $buildingName');
                                
                                return RoomListingCard(
                                  room: room,
                                  buildingName: buildingName,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      CustomPageRoute(
                                        child: RoomDetailScreen(
                                          room: room,
                                          buildingName: buildingName,
                                        ),
                                        transition: CustomPageTransition.containerTransform,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            CustomPageRoute(
              child: AddRoomScreen(buildingId: widget.selectedBuildingId),
              transition: CustomPageTransition.transform,
            ),
          ).then((result) {
            if (result != null) {
              loadData();
            }
          });
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Room',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value, bool isMobile) {
    final isSelected = statusFilter == value;
    return SizedBox(
      height: 40, // Fixed height for all chips
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            statusFilter = value;
          });
        },
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[700] ?? Colors.grey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }

  Widget _buildTenantCard(Room room, RoomTenant tenant, String buildingName, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to tenant details or room details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomDetailScreen(
                  room: room,
                  buildingName: buildingName,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with room info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Room ${room.number}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.person,
                      color: Colors.white.withOpacity(0.8),
                      size: isMobile ? 20 : 24,
                    ),
                  ],
                ),
                
                SizedBox(height: isMobile ? 8 : 12),
                
                // Tenant name
                Text(
                  tenant.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: isMobile ? 4 : 6),
                
                // Contact info
                if (tenant.phone.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color: Colors.white.withOpacity(0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tenant.phone,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isMobile ? 12 : 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                ],
                
                // Email info (if available and different from phone)
                if (tenant.email.isNotEmpty && tenant.email != tenant.phone) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: Colors.white.withOpacity(0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tenant.email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isMobile ? 11 : 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                ],
                
                // Building info
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: Colors.white.withOpacity(0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        buildingName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isMobile ? 12 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isMobile ? 8 : 12),
                
                // Bottom row with rent and move-in date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${room.rent.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'per month',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isMobile ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                    if (tenant.moveInDate != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Move-in',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: isMobile ? 10 : 11,
                            ),
                          ),
                          Text(
                            _formatDate(tenant.moveInDate!),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference < 30) {
      return '${difference}d ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference / 365).floor();
      return '${years}y ago';
    }
  }
}

