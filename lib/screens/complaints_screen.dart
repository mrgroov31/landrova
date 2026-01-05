import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/api_service.dart';
import '../services/complaint_service.dart';
import '../services/auth_service.dart';
import '../widgets/complaint_card.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'add_complaint_screen.dart';
import 'complaint_detail_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  final String? heroTag;
  final String? selectedBuildingId;
  
  const ComplaintsScreen({super.key, this.heroTag, this.selectedBuildingId});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<Complaint> complaints = [];
  bool isLoading = true;
  String? error;
  String filter = 'all'; // all, pending, in_progress, resolved

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  Future<void> loadComplaints() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      // Load from ComplaintService (which merges API and Hive data)
      var loadedComplaints = await ComplaintService.getAllComplaints();
      
      // Filter by building if selected
      if (widget.selectedBuildingId != null && widget.selectedBuildingId!.isNotEmpty) {
        // Get rooms for this building
        final roomsResponse = await ApiService.fetchRooms();
        final allRooms = ApiService.parseRooms(roomsResponse);
        final buildingRooms = allRooms.where((r) => r.buildingId == widget.selectedBuildingId).toList();
        final roomNumbers = buildingRooms.map((r) => r.number).toSet();
        
        // Filter complaints by room numbers
        loadedComplaints = loadedComplaints.where((c) => roomNumbers.contains(c.roomNumber)).toList();
      }
      
      setState(() {
        complaints = loadedComplaints;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<Complaint> get filteredComplaints {
    // Get current user
    final user = AuthService.currentUser;
    
    // If tenant is logged in, filter by tenant ID
    List<Complaint> tenantComplaints = complaints;
    if (user != null && user.isTenant) {
      final tenantId = user.additionalData?['tenantId'] as String?;
      if (tenantId != null) {
        tenantComplaints = complaints.where((c) => c.tenantId == tenantId).toList();
      }
    }
    
    // Apply status filter
    if (filter == 'all') return tenantComplaints;
    return tenantComplaints.where((c) => c.status == filter).toList();
  }
  
  bool get isTenantLoggedIn {
    final user = AuthService.currentUser;
    return user != null && user.isTenant;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          isTenantLoggedIn ? 'My Complaints' : 'Complaints',
          style: const TextStyle(
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
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending', isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('In Progress', 'in_progress', isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('Resolved', 'resolved', isMobile),
                ],
              ),
            ),
          ),
          // Complaints List
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
                              onPressed: loadComplaints,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredComplaints.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.report_problem_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No complaints found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadComplaints,
                            child: ListView.builder(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              itemCount: filteredComplaints.length,
                              itemBuilder: (context, index) {
                                return ComplaintCard(
                                  complaint: filteredComplaints[index],
                                  onTap: () async {
                                    // Navigate to detail screen
                                    final result = await Navigator.push(
                                      context,
                                      CustomPageRoute(
                                        child: ComplaintDetailScreen(
                                          complaint: filteredComplaints[index],
                                        ),
                                        transition: CustomPageTransition.containerTransform,
                                      ),
                                    );
                                    
                                    // Reload complaints if updated
                                    if (result == true) {
                                      loadComplaints();
                                    }
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: isTenantLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  CustomPageRoute(
                    child: const AddComplaintScreen(),
                    transition: CustomPageTransition.transform,
                  ),
                );
                
                // Reload complaints if a new one was added
                if (result == true) {
                  loadComplaints();
                }
              },
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Complaint',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String value, bool isMobile) {
    final isSelected = filter == value;
    return SizedBox(
      height: 40, // Fixed height for all chips
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            filter = value;
          });
        },
        // ignore: deprecated_member_use
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

