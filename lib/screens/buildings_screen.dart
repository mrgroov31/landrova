import 'package:flutter/material.dart';
import 'dart:io';
import '../models/building.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
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
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.getBackgroundColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BUILDINGS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '${buildings.length} registered properties',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondaryColor(context),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
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
                  : Column(
                      children: [
                        // Search and Filter Bar
                        Padding(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.getSurfaceColor(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
                                    ),
                                  ),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Lookup building...',
                                      hintStyle: TextStyle(
                                        color: AppTheme.getTextSecondaryColor(context).withOpacity(0.5),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: AppTheme.getTextSecondaryColor(context),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.getSurfaceColor(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.filter_list,
                                    color: AppTheme.getTextPrimaryColor(context),
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Buildings List
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: loadBuildings,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 24,
                              ),
                              itemCount: buildings.length,
                              itemBuilder: (context, index) {
                                final building = buildings[index];
                                return _buildBuildingCard(building, isMobile);
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

  Widget _buildBuildingCard(Building building, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            CustomPageRoute(
              child: BuildingDetailScreen(building: building),
              transition: CustomPageTransition.transform,
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Row(
            children: [
              // Building Image
              Container(
                width: isMobile ? 80 : 90,
                height: isMobile ? 80 : 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blueGrey.shade800
                      : Colors.blueGrey.shade100,
                ),
                child: building.image != null && File(building.image!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(building.image!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.apartment,
                        size: isMobile ? 36 : 40,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blueGrey.shade400
                            : Colors.blueGrey,
                      ),
              ),
              SizedBox(width: isMobile ? 14 : 16),
              // Building Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            building.name,
                            style: TextStyle(
                              fontSize: isMobile ? 17 : 19,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      building.address.toUpperCase(),
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: AppTheme.getTextSecondaryColor(context),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${building.totalRooms} rooms • ${building.totalFloors} floors',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            building.propertyTypeDisplayName,
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 11 : 12, color: AppTheme.getTextSecondaryColor(context)),
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

