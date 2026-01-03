import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import '../widgets/room_listing_card.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class RoomsScreen extends StatefulWidget {
  final String? heroTag;
  
  const RoomsScreen({super.key, this.heroTag});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<Room> rooms = [];
  bool isLoading = true;
  String? error;
  String statusFilter = 'all'; // all, occupied, vacant, maintenance

  @override
  void initState() {
    super.initState();
    loadRooms();
  }

  Future<void> loadRooms() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      final response = await ApiService.fetchRooms();
      final loadedRooms = ApiService.parseRooms(response);
      
      setState(() {
        rooms = loadedRooms;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<Room> get filteredRooms {
    // Filter by status only
    if (statusFilter == 'all') return rooms;
    return rooms.where((room) => room.status == statusFilter).toList();
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
                              onPressed: loadRooms,
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
                            onRefresh: loadRooms,
                            child: ListView.builder(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              itemCount: filteredRooms.length,
                              itemBuilder: (context, index) {
                                final room = filteredRooms[index];
                                return RoomListingCard(
                                  room: room,
                                  onTap: () {
                                    // Navigate to room detail
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
          // Add new room
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
}

