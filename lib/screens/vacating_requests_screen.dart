import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vacating_request.dart';
import '../services/vacating_request_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/room.dart';

class VacatingRequestsScreen extends StatefulWidget {
  const VacatingRequestsScreen({super.key});

  @override
  State<VacatingRequestsScreen> createState() => _VacatingRequestsScreenState();
}

class _VacatingRequestsScreenState extends State<VacatingRequestsScreen> {
  List<VacatingRequest> requests = [];
  bool isLoading = true;
  String filter = 'all'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      setState(() {
        isLoading = true;
      });

      final allRequests = await VacatingRequestService.getAllRequests();
      
      // Process completed requests (mark rooms as available)
      await _processCompletedRequests(allRequests);

      setState(() {
        requests = allRequests;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processCompletedRequests(List<VacatingRequest> allRequests) async {
    // Find requests that are approved and past their vacating date
    final completedRequests = allRequests.where((r) => r.isCompleted).toList();
    
    for (var request in completedRequests) {
      // Mark room as available
      try {
        // In a real app, you would update the room status via API
        // For now, we'll mark the request as completed
        // The room availability should be updated in the rooms management system
        if (request.status != 'completed') {
          request.status = 'completed';
          await VacatingRequestService.updateRequest(request);
          
          // Note: In production, you would also:
          // 1. Update the room status to 'available' via API
          // 2. Remove tenant from the room
          // 3. Update tenant status
          // 4. Send notifications
          
          debugPrint('Room ${request.roomNumber} should be marked as available after ${request.vacatingDate}');
        }
      } catch (e) {
        debugPrint('Error processing completed request: $e');
      }
    }
  }

  List<VacatingRequest> get filteredRequests {
    if (filter == 'all') return requests;
    return requests.where((r) => r.status == filter).toList();
  }

  Future<void> _approveRequest(VacatingRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text('Approve vacating request for ${request.tenantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final owner = AuthService.currentUser;
      request.approve(owner?.id ?? 'owner_001');
      await VacatingRequestService.updateRequest(request);
      
      if (mounted) {
        loadRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(VacatingRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text('Reject vacating request for ${request.tenantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      request.reject();
      await VacatingRequestService.updateRequest(request);
      
      if (mounted) {
        loadRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vacating Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
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
                  _buildFilterChip('Approved', 'approved', isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected', 'rejected', isMobile),
                ],
              ),
            ),
          ),
          // Requests List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No vacating requests',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadRequests,
                        child: ListView.builder(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          itemCount: filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = filteredRequests[index];
                            return _buildRequestCard(request, dateFormat, isMobile);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isMobile) {
    final isSelected = filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          filter = value;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: isMobile ? 13 : 14,
      ),
    );
  }

  Widget _buildRequestCard(VacatingRequest request, DateFormat dateFormat, bool isMobile) {
    final statusColor = getStatusColor(request.status);
    
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.tenantName,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.room, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Room ${request.roomNumber}',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Vacating Date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Vacating Date: ${dateFormat.format(request.vacatingDate)}',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Reason
            Text(
              'Reason:',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.reason,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
            
            // Action Buttons (only for pending requests)
            if (request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _rejectRequest(request),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _approveRequest(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

