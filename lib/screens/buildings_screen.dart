import 'package:flutter/material.dart';
import 'dart:io';
import '../models/building.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'dashboard_screen.dart';
import 'add_building_screen.dart';
import 'building_detail_screen.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  List<Building> buildings = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadBuildings();
  }

  Future<void> loadBuildings() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      // Get owner ID from centralized location
      final currentUser = AuthService.currentUser;
      if (currentUser == null || !currentUser.isOwner) {
        throw Exception('User not logged in as owner');
      }

      final ownerId = AuthService.getOwnerId();
      
      // Fetch buildings from API
      final response = await ApiService.fetchBuildingsByOwnerId(ownerId);
      final apiBuildings = ApiService.parseBuildings(response);
      
      setState(() {
        buildings = apiBuildings;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void addBuilding(Building building) {
    // Reload buildings from API to get the latest data including the newly added building
    loadBuildings();
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
          'My Buildings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
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
                        onPressed: loadBuildings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : buildings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No buildings found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                CustomPageRoute(
                                  child: const AddBuildingScreen(),
                                  transition: CustomPageTransition.transform,
                                ),
                              );
                              if (result != null && result is Building) {
                                addBuilding(result);
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Building'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadBuildings,
                      child: ListView.builder(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        itemCount: buildings.length,
                        itemBuilder: (context, index) {
                          final building = buildings[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                // Navigate to building detail screen
                                Navigator.push(
                                  context,
                                  CustomPageRoute(
                                    child: BuildingDetailScreen(building: building),
                                    transition: CustomPageTransition.transform,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 16 : 20),
                                child: Row(
                                  children: [
                                    // Building Image or Icon
                                    Container(
                                      width: isMobile ? 60 : 70,
                                      height: isMobile ? 60 : 70,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: building.image != null && File(building.image!).existsSync()
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(
                                                File(building.image!),
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(
                                              Icons.business,
                                              size: isMobile ? 32 : 36,
                                              color: AppTheme.primaryColor,
                                            ),
                                    ),
                                    SizedBox(width: isMobile ? 16 : 20),
                                    // Building Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            building.name,
                                            style: TextStyle(
                                              fontSize: isMobile ? 18 : 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  building.address,
                                                  style: TextStyle(
                                                    fontSize: isMobile ? 13 : 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: [
                                                _buildInfoChip(
                                                  Icons.layers,
                                                  '${building.totalFloors} Floors',
                                                  isMobile,
                                                ),
                                                const SizedBox(width: 8),
                                                _buildInfoChip(
                                                  Icons.door_front_door,
                                                  '${building.totalRooms} Rooms',
                                                  isMobile,
                                                ),
                                                const SizedBox(width: 8),
                                                _buildInfoChip(
                                                  building.propertyType == 'pg' 
                                                      ? Icons.hotel 
                                                      : building.propertyType == 'rented'
                                                          ? Icons.home
                                                          : Icons.business,
                                                  building.propertyTypeDisplayName,
                                                  isMobile,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            CustomPageRoute(
              child: const AddBuildingScreen(),
              transition: CustomPageTransition.transform,
            ),
          );
          if (result != null && result is Building) {
            addBuilding(result);
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Building',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 11 : 12, color: Colors.grey[700]),
          SizedBox(width: isMobile ? 3 : 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

