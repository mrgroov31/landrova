import 'package:flutter/material.dart';
import '../models/service_provider.dart';
import '../services/service_provider_service.dart';
import '../services/optimized_api_service.dart';
import '../services/hive_api_service.dart';
import '../widgets/performance_indicator.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/enhanced_skeleton_loader.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'register_service_provider_screen.dart';
import 'edit_service_provider_screen.dart';
import 'service_provider_detail_screen.dart';

class ServiceProvidersListScreen extends StatefulWidget {
  const ServiceProvidersListScreen({super.key});

  @override
  State<ServiceProvidersListScreen> createState() => _ServiceProvidersListScreenState();
}

class _ServiceProvidersListScreenState extends State<ServiceProvidersListScreen> {
  List<ServiceProvider> providers = [];
  bool isLoading = true;
  String? error;
  String filter = 'all'; // all, electrician, plumber, etc.

  @override
  void initState() {
    super.initState();
    loadProviders();
  }

  Future<void> loadProviders({bool forceRefresh = false}) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Use Hive API service for ultra-fast loading with persistent caching
      // Force refresh will bypass cache and fetch from API
      final allProviders = await HiveApiService.getServiceProviders(forceRefresh: forceRefresh);
      
      setState(() {
        providers = allProviders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<ServiceProvider> get filteredProviders {
    if (filter == 'all') return providers;
    return providers.where((p) => p.serviceType == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.getSurfaceColor(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getTextPrimaryColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Service Providers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.getTextPrimaryColor(context)),
            onPressed: () => loadProviders(forceRefresh: true),
            tooltip: 'Refresh from API',
          ),
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.getTextPrimaryColor(context)),
            onPressed: () {},
            tooltip: 'Search',
          ),
        ],
      ),
      body: EnhancedSkeletonLoader(
        isLoading: isLoading,
        loadingMessage: 'Finding service providers...',
        showHiveHint: true,
        child: Column(
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
                    _buildFilterChip('Electrician', 'electrician', isMobile),
                    const SizedBox(width: 8),
                    _buildFilterChip('Plumber', 'plumber', isMobile),
                    const SizedBox(width: 8),
                    _buildFilterChip('Carpenter', 'carpenter', isMobile),
                    const SizedBox(width: 8),
                    _buildFilterChip('Painter', 'painter', isMobile),
                    const SizedBox(width: 8),
                    _buildFilterChip('AC Repair', 'ac_repair', isMobile),
                    const SizedBox(width: 8),
                    _buildFilterChip('Appliance', 'appliance_repair', isMobile),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cleaning', 'cleaning', isMobile),
                    const SizedBox(width: 8),
                    _buildFilterChip('Handyman', 'handyman', isMobile),
                  ],
                ),
              ),
            ),
            // Providers List
            Expanded(
              child: error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('Error: $error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: loadProviders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredProviders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: AppTheme.getTextSecondaryColor(context).withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  'No service providers found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppTheme.getTextSecondaryColor(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Register a service provider to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextSecondaryColor(context),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CustomPageRoute(
                                        child: const RegisterServiceProviderScreen(),
                                        transition: CustomPageTransition.transform,
                                      ),
                                    ).then((_) => loadProviders(forceRefresh: true));
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Register Provider'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => loadProviders(forceRefresh: true),
                            child: ListView.builder(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              itemCount: filteredProviders.length,
                              itemBuilder: (context, index) {
                                return _buildProviderCard(filteredProviders[index], isMobile);
                              },
                            ),
                          ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            CustomPageRoute(
              child: const RegisterServiceProviderScreen(),
              transition: CustomPageTransition.transform,
            ),
          ).then((_) => loadProviders());
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Register Provider',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isMobile) {
    final isSelected = filter == value;
    return SizedBox(
      height: 40,
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            filter = value;
          });
        },
        backgroundColor: AppTheme.getSurfaceColor(context),
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.getTextSecondaryColor(context),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }

  Widget _buildProviderCard(ServiceProvider provider, bool isMobile) {
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
            _showProviderDetails(provider);
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
                          if (provider.isAvailable) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.green.withOpacity(0.4)
                                      : Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Available',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (provider.address != null) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppTheme.getTextSecondaryColor(context),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                provider.address!,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 13,
                                  color: AppTheme.getTextSecondaryColor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Action Buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        _callProvider(provider);
                      },
                      tooltip: 'Call',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                      onPressed: () {
                        _showProviderOptions(provider);
                      },
                      tooltip: 'More options',
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

  void _showProviderDetails(ServiceProvider provider) {
    Navigator.push(
      context,
      CustomPageRoute(
        child: ServiceProviderDetailScreen(provider: provider),
        transition: CustomPageTransition.transform,
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

  void _callProvider(ServiceProvider provider) {
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

  void _showProviderOptions(ServiceProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.primaryColor),
              title: const Text('Call'),
              onTap: () {
                Navigator.pop(context);
                _callProvider(provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CustomPageRoute(
                    child: EditServiceProviderScreen(provider: provider),
                    transition: CustomPageTransition.transform,
                  ),
                ).then((_) => loadProviders());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteProvider(provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProvider(ServiceProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Are you sure you want to delete ${provider.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implement delete API call
      // await ServiceProviderService.deleteProvider(provider.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete functionality will be implemented with API'),
            backgroundColor: Colors.orange,
          ),
        );
        // loadProviders();
      }
    }
  }
}

