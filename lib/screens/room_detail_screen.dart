import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/room.dart';
import '../models/building.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'invite_tenant_screen.dart';
import 'manage_room_occupants_screen.dart';
import 'package:intl/intl.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  final String? buildingName;

  const RoomDetailScreen({
    super.key,
    required this.room,
    this.buildingName,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  Building? building;
  bool isLoading = true;
  PageController? _imagePageController;
  int _currentImageIndex = 0;
  late Room currentRoom; // Track current room state

  @override
  void initState() {
    super.initState();
    currentRoom = widget.room; // Initialize with the passed room
    _imagePageController = PageController();
    _loadRoomData();
  }

  @override
  void dispose() {
    _imagePageController?.dispose();
    super.dispose();
  }

  Future<void> _loadRoomData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load building information
      if (currentRoom.buildingId.isNotEmpty) {
        try {
          final ownerId = AuthService.getOwnerId();
          final buildingsResponse = await ApiService.fetchBuildingsByOwnerId(ownerId);
          final buildings = ApiService.parseBuildings(buildingsResponse);
          debugPrint("$buildingsResponse buildingsbuildingsbuildingsbuildings");

          final foundBuilding = buildings.firstWhere(
            (b) => b.id == currentRoom.buildingId,
            orElse: () => Building(
              id: currentRoom.buildingId,
              name: widget.buildingName ?? 'Building',
              address: '',
              totalFloors: 1,
              totalRooms: 1,
              buildingType: 'standalone',
              propertyType: 'rented',
              createdAt: DateTime.now(),
            ),
          );
          setState(() {
            building = foundBuilding;
          });
        } catch (e) {
          debugPrint('Error loading building: $e');
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getStatusColor() {
    if (currentRoom.hasTenant || currentRoom.isOccupied) {
      return Colors.green;
    }
    switch (currentRoom.status) {
      case 'occupied':
        return Colors.green;
      case 'vacant':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String getStatusText() {
    if (currentRoom.hasTenant || currentRoom.isOccupied) {
      return 'Occupied';
    }
    switch (currentRoom.status) {
      case 'occupied':
        return 'Occupied';
      case 'vacant':
        return 'Available';
      case 'maintenance':
        return 'Under Maintenance';
      default:
        return currentRoom.status;
    }
  }

  String _getRoomImageUrl(int index) {
    if (currentRoom.images.isNotEmpty && index < currentRoom.images.length) {
      return currentRoom.images[index];
    }
    final roomHash = currentRoom.number.hashCode;
    final imageId = (roomHash.abs() % 1000) + index + 1;
    return 'https://picsum.photos/seed/room$imageId/800/600';
  }

  void _onRoomUpdated(Room updatedRoom) {
    setState(() {
      currentRoom = updatedRoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final images = currentRoom.images.isNotEmpty 
        ? currentRoom.images 
        : [_getRoomImageUrl(0)]; // At least one image

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // App Bar with Room Image
          SliverAppBar(
            expandedHeight: isMobile ? 200 : 350,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'House ${currentRoom.number}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: EdgeInsets.only(
                left: isMobile ? 50 : 72, // Account for back button
                bottom: isMobile ? 16 : 20,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Carousel
                  PageView.builder(
                    controller: _imagePageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: getStatusColor().withOpacity(0.3),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: getStatusColor(),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                getStatusColor().withOpacity(0.3),
                                getStatusColor().withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.home,
                              size: 80,
                              color: getStatusColor().withOpacity(0.5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Dark overlay
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
                  // Page indicator
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              // IconButton(
              //   icon: const Icon(Icons.edit, color: Colors.white),
              //   onPressed: () {
              //     // TODO: Navigate to edit room screen
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Edit room feature coming soon')),
              //     );
              //   },
              // ),
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
                      // Status Badge and Quick Info
                      Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                getStatusText(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Rent
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${currentRoom.rent.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 24 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.getTextPrimaryColor(context),
                                  ),
                                ),
                                Text(
                                  'per month',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    color: AppTheme.getTextSecondaryColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Room Details Card
                      _buildRoomDetailsCard(isMobile),

                      // Building Info Card
                      if (building != null) _buildBuildingInfoCard(isMobile),

                      // Occupancy Management Card
                      _buildOccupancyManagementCard(isMobile),

                      // Tenant Info Card (if occupied)
                      if (currentRoom.hasTenant) 
                        _buildTenantInfoCard(isMobile)
                      else if (!currentRoom.hasTenant && currentRoom.status == 'vacant')
                        _buildVacantRoomActions(isMobile),

                      // Amenities Card
                      if (currentRoom.amenities.isNotEmpty)
                        _buildAmenitiesCard(isMobile),

                      SizedBox(height: isMobile ? 16 : 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetailsCard(bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
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
                'Room Details',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildDetailRow('Room Type', currentRoom.typeDisplayName, isMobile),
          _buildDetailRow('Status', currentRoom.occupancyStatus, isMobile),
          _buildDetailRow('Capacity', '${currentRoom.currentOccupancy}/${currentRoom.capacity} people', isMobile),
          if (currentRoom.floor != null)
            _buildDetailRow('Floor', currentRoom.floor.toString(), isMobile),
          if (currentRoom.area != null)
            _buildDetailRow('Area', currentRoom.area!, isMobile),
          if (currentRoom.description != null && currentRoom.description!.isNotEmpty) ...[
            SizedBox(height: isMobile ? 12 : 16),
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
              currentRoom.description!,
              style: TextStyle(
                fontSize: isMobile ? 13 : 15,
                color: AppTheme.getTextSecondaryColor(context),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBuildingInfoCard(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
      ),
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
              Icon(Icons.business, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Building Information',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),

          _buildDetailRow('Building Name', building!.name, isMobile),
          _buildDetailRow('Address', building!.address, isMobile),
          if (building!.city != null || building!.state != null)
            _buildDetailRow(
              'Location',
              '${building!.city ?? ''}${building!.city != null && building!.state != null ? ', ' : ''}${building!.state ?? ''}',
              isMobile,
            ),
        ],
      ),
    );
  }

  Widget _buildOccupancyManagementCard(bool isMobile) {
    final availableSpots = currentRoom.capacity - currentRoom.currentOccupancy;
    
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
      ),
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
              Icon(Icons.people, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Occupancy Management',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          
          // Occupancy Stats
          Row(
            children: [
              Expanded(
                child: _buildOccupancyStat(
                  'Total Capacity',
                  currentRoom.capacity.toString(),
                  Icons.people_outline,
                  Colors.blue,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildOccupancyStat(
                  'Current Occupancy',
                  currentRoom.currentOccupancy.toString(),
                  Icons.person,
                  currentRoom.currentOccupancy > 0 ? Colors.green : Colors.grey,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildOccupancyStat(
                  'Available',
                  availableSpots.toString(),
                  Icons.person_add_outlined,
                  availableSpots > 0 ? Colors.orange : Colors.red,
                  isMobile,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Occupancy Rate',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                  Text(
                    '${((currentRoom.currentOccupancy / currentRoom.capacity) * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: currentRoom.currentOccupancy / currentRoom.capacity,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  currentRoom.currentOccupancy == currentRoom.capacity
                      ? Colors.red
                      : currentRoom.currentOccupancy > (currentRoom.capacity * 0.8)
                          ? Colors.orange
                          : AppTheme.primaryColor,
                ),
                minHeight: 8,
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: ManageRoomOccupantsScreen(
                      room: currentRoom,
                      onRoomUpdated: _onRoomUpdated,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manage Occupants'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyStat(String label, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: AppTheme.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTenantInfoCard(bool isMobile) {
    final tenant = currentRoom.tenant!;
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
        bottom: isMobile ? 56 : 24,
      ),
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
              Icon(Icons.person, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Current Tenant',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
              const Spacer(),
              // Active status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tenant.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tenant.isActive ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: tenant.isActive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tenant.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tenant.isActive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          
          // Tenant Profile Section
          Row(
            children: [
              // Tenant Avatar
              CircleAvatar(
                radius: isMobile ? 30 : 35,
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
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    if (tenant.phone.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: AppTheme.getTextSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tenant.phone,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: AppTheme.getTextSecondaryColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (tenant.email.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 16,
                            color: AppTheme.getTextSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tenant.email,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: AppTheme.getTextSecondaryColor(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 12 : 16),
          Divider(),
          SizedBox(height: isMobile ? 12 : 16),
          
          // Tenant Details
          if (tenant.moveInDate != null)
            _buildDetailRow(
              'Move-in Date', 
              dateFormat.format(tenant.moveInDate!), 
              isMobile,
            ),
          if (tenant.leaseEndDate != null)
            _buildDetailRow(
              'Lease End Date', 
              dateFormat.format(tenant.leaseEndDate!), 
              isMobile,
            ),
          
          // Calculate and show tenure
          if (tenant.moveInDate != null) ...[
            SizedBox(height: isMobile ? 8 : 12),
            _buildTenureInfo(tenant.moveInDate!, isMobile),
          ],
          
          // Action buttons
          SizedBox(height: isMobile ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Call tenant
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${tenant.name}...')),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Send message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Messaging ${tenant.name}...')),
                    );
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenureInfo(DateTime moveInDate, bool isMobile) {
    final now = DateTime.now();
    final difference = now.difference(moveInDate);
    final days = difference.inDays;
    final months = (days / 30).floor();
    final years = (days / 365).floor();
    
    String tenureText;
    if (years > 0) {
      final remainingMonths = months - (years * 12);
      tenureText = '$years year${years > 1 ? 's' : ''}';
      if (remainingMonths > 0) {
        tenureText += ', $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
      }
    } else if (months > 0) {
      tenureText = '$months month${months > 1 ? 's' : ''}';
    } else {
      tenureText = '$days day${days > 1 ? 's' : ''}';
    }
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: AppTheme.primaryColor,
            size: isMobile ? 18 : 20,
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tenure',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
              Text(
                tenureText,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVacantRoomActions(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
      ),
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
              Icon(Icons.person_add, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Room Available',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: isMobile ? 18 : 20,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'This room is currently vacant and ready for a new tenant.',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: InviteTenantScreen(
                          selectedBuildingId: currentRoom.buildingId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Invite Tenant'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to room listing/marketing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room marketing feature coming soon')),
                    );
                  },
                  icon: const Icon(Icons.campaign),
                  label: const Text('Promote'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesCard(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
      ),
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
              Icon(Icons.star, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Amenities',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.room.amenities.map((amenity) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      amenity,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: AppTheme.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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
}

