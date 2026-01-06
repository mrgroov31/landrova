import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../models/service_provider.dart';
import '../services/service_provider_service.dart';
import '../services/complaint_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../utils/custom_page_route.dart';
import '../theme/app_theme.dart';
import 'register_service_provider_screen.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint complaint;
  final GlobalKey? heroKey;

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
    this.heroKey,
  });

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  List<ServiceProvider> suggestedProviders = [];
  bool isLoadingProviders = true;
  late Complaint complaint; // Make it mutable so we can update it
  ServiceProvider? assignedProvider;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the complaint
    complaint = Complaint(
      id: widget.complaint.id,
      title: widget.complaint.title,
      description: widget.complaint.description,
      roomNumber: widget.complaint.roomNumber,
      tenantId: widget.complaint.tenantId,
      tenantName: widget.complaint.tenantName,
      status: widget.complaint.status,
      createdAt: widget.complaint.createdAt,
      updatedAt: widget.complaint.updatedAt,
      resolvedAt: widget.complaint.resolvedAt,
      priority: widget.complaint.priority,
      category: widget.complaint.category,
      assignedTo: widget.complaint.assignedTo,
      serviceProviderId: widget.complaint.serviceProviderId,
      images: widget.complaint.images,
    );
    _loadProviders();
    _loadAssignedProvider();
  }

  Future<void> _loadProviders() async {
    final providers = await ServiceProviderService.getSuggestedProviders(
      complaintTitle: complaint.title,
      complaintDescription: complaint.description,
    );
    if (mounted) {
      setState(() {
        suggestedProviders = providers;
        isLoadingProviders = false;
      });
    }
  }

  Future<void> _loadAssignedProvider() async {
    if (complaint.serviceProviderId != null) {
      final provider = await ServiceProviderService.getProviderById(complaint.serviceProviderId!);
      if (mounted) {
        setState(() {
          assignedProvider = provider;
        });
      }
    }
  }

  bool get isOwnerLoggedIn {
    final user = AuthService.currentUser;
    return user != null && user.isOwner;
  }

  bool get isTenantLoggedIn {
    final user = AuthService.currentUser;
    return user != null && user.isTenant;
  }

  bool get canTenantMarkAsFixed {
    return isTenantLoggedIn && 
           (complaint.status == 'assigned' || complaint.status == 'in_progress') && 
           complaint.serviceProviderId != null;
  }

  Color getStatusColor() {
    switch (complaint.status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.purple;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color getStatusBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (complaint.status) {
      case 'pending':
        return isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50;
      case 'assigned':
        return isDark ? Colors.purple.withOpacity(0.2) : Colors.purple.shade50;
      case 'in_progress':
        return isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50;
      case 'resolved':
        return isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50;
      default:
        return isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade50;
    }
  }

  Color getPriorityColor() {
    switch (complaint.priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: isMobile ? 120 : 140,
            floating: false,
            pinned: true,
            backgroundColor: getStatusBackgroundColor(context),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.getTextPrimaryColor(context)),
              onPressed: () => Navigator.pop(context, false),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Complaint Details',
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 20,
                ),
              ),
              background: Container(
                color: getStatusBackgroundColor(context),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: isMobile ? 16 : 24,
                  right: isMobile ? 16 : 24,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        complaint.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    complaint.title,
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 16 : 20),
                  
                  // Description
                  Text(
                    complaint.description,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      height: 1.5,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 24 : 32),
                  
                  // Info Cards
                  Wrap(
                    spacing: isMobile ? 12 : 16,
                    runSpacing: isMobile ? 12 : 16,
                    children: [
                      _buildInfoCard(
                        icon: Icons.room_outlined,
                        label: 'Room',
                        value: complaint.roomNumber,
                        isMobile: isMobile,
                      ),
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        label: 'Tenant',
                        value: complaint.tenantName,
                        isMobile: isMobile,
                      ),
                      _buildInfoCard(
                        icon: Icons.priority_high,
                        label: 'Priority',
                        value: complaint.priority.toUpperCase(),
                        isMobile: isMobile,
                        color: getPriorityColor(),
                      ),
                      _buildInfoCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created',
                        value: dateFormat.format(complaint.createdAt),
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                  
                  if (complaint.resolvedAt != null) ...[
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildInfoCard(
                      icon: Icons.check_circle_outline,
                      label: 'Resolved',
                      value: dateFormat.format(complaint.resolvedAt!),
                      isMobile: isMobile,
                      color: Colors.green,
                    ),
                  ],
                  
                  // Assigned Service Provider Section - Visible to both owners and tenants
                  if (assignedProvider != null) ...[
                    SizedBox(height: isMobile ? 32 : 40),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue.withOpacity(0.4)
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_ind, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Assigned Service Provider',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              if (complaint.status == 'assigned' || complaint.status == 'in_progress')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: complaint.status == 'assigned' 
                                        ? Colors.purple.shade700 
                                        : Colors.blue.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    complaint.status == 'assigned' ? 'ASSIGNED' : 'WORKING',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildServiceProviderCard(context, assignedProvider!, isMobile, isAssigned: true),
                        ],
                      ),
                    ),
                  ],
                  
                  // Service Providers Section - Only show if providers are found and not assigned
                  if (!isLoadingProviders && 
                      suggestedProviders.isNotEmpty && 
                      assignedProvider == null &&
                      isOwnerLoggedIn &&
                      (complaint.status == 'pending' || complaint.status == 'assigned')) ...[
                    SizedBox(height: isMobile ? 32 : 40),
                    Text(
                      'Suggested Service Providers',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    ...suggestedProviders.map((provider) => 
                      _buildServiceProviderCard(context, provider, isMobile)
                    ),
                  ],
                  
                  SizedBox(height: isMobile ? 32 : 40),
                  
                  // Action Buttons
                  if (isOwnerLoggedIn && (complaint.status == 'pending' || complaint.status == 'assigned') && assignedProvider == null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAssignProviderDialog(context),
                        icon: const Icon(Icons.assignment),
                        label: const Text(
                          'Assign Service Provider',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                  ],
                  
                  if (canTenantMarkAsFixed) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsFixed(context),
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Mark as Fixed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isMobile,
    Color? color,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color?.withOpacity(0.3) ?? AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 20 : 24,
            color: color ?? AppTheme.getTextSecondaryColor(context),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceProviderCard(BuildContext context, ServiceProvider provider, bool isMobile, {bool isAssigned = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Show provider details - both owners and tenants can view
            _showProviderDetails(context, provider);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: isMobile ? 56 : 64,
                  height: isMobile ? 56 : 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    provider.serviceTypeIcon,
                    size: isMobile ? 28 : 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        provider.serviceTypeDisplayName,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${provider.rating}',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '• ${provider.totalJobs} jobs',
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
                // Call Button (only show if not assigned or if owner)
                if (!isAssigned || isOwnerLoggedIn)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      // Call provider
                      _callProvider(context, provider);
                    },
                  ),
                // Assign Button (only for owners when not assigned)
                if (isOwnerLoggedIn && !isAssigned && (complaint.status == 'pending' || complaint.status == 'assigned'))
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => _assignServiceProvider(context, provider),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProviderDetails(BuildContext context, ServiceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    provider.serviceTypeIcon,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.serviceTypeDisplayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (provider.address != null) ...[
              _buildDetailRow(Icons.location_on, 'Address', provider.address!),
              const SizedBox(height: 16),
            ],
            _buildDetailRow(Icons.phone, 'Phone', provider.phone),
            if (provider.email != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(Icons.email, 'Email', provider.email!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${provider.rating}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '• ${provider.totalJobs} completed jobs',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
            if (provider.specialties.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Specialties',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.specialties.map((specialty) {
                  return Chip(
                    label: Text(specialty),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _callProvider(context, provider);
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Call Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.getTextSecondaryColor(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAssignProviderDialog(BuildContext context) async {
    if (suggestedProviders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No service providers available. Please register one first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedProvider = await showDialog<ServiceProvider>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Service Provider'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestedProviders.length,
            itemBuilder: (context, index) {
              final provider = suggestedProviders[index];
              return ListTile(
                leading: Icon(provider.serviceTypeIcon, color: AppTheme.primaryColor),
                title: Text(provider.name),
                subtitle: Text(provider.serviceTypeDisplayName),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pop(context, provider),
              );
            },
          ),
        ),
      ),
    );

    if (selectedProvider != null) {
      await _assignServiceProvider(context, selectedProvider);
    }
  }

  Future<void> _assignServiceProvider(BuildContext context, ServiceProvider provider) async {
    try {
      // Update complaint
      complaint.assignServiceProvider(provider.id, provider.name);
      
      // Save to service
      await ComplaintService.updateComplaint(complaint);
      
      if (mounted) {
        setState(() {
          assignedProvider = provider;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.name} assigned successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
        
        // Notify parent that complaint was updated
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning provider: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsFixed(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Fixed'),
        content: const Text('Are you sure the complaint has been fixed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Yes, Mark as Fixed'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Update complaint
        complaint.markAsFixed();
        
        // Save to service
        await ComplaintService.updateComplaint(complaint);
        
        if (mounted) {
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complaint marked as fixed!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigate back after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context, true); // Return true to indicate update
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error marking as fixed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _callProvider(BuildContext context, ServiceProvider provider) {
    // In production, use url_launcher to make phone calls
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${provider.name} at ${provider.phone}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

