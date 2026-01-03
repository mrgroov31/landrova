import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../services/api_service.dart';
import '../services/tenant_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'invite_tenant_screen.dart';
import 'package:intl/intl.dart';

class TenantsScreen extends StatefulWidget {
  final String? heroTag;
  
  const TenantsScreen({super.key, this.heroTag});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  List<Tenant> tenants = [];
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
      
      // Load from TenantService (which merges API and Hive data)
      final loadedTenants = await TenantService.getAllTenants();
      
      setState(() {
        tenants = loadedTenants;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
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
                          return Card(
                            margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(isMobile ? 16 : 20),
                              leading: CircleAvatar(
                                radius: isMobile ? 28 : 32,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  tenant.name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                tenant.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.room, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text('Room ${tenant.roomNumber}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(tenant.phone),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Moved in: ${dateFormat.format(tenant.moveInDate)}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: tenant.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tenant.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: tenant.isActive ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              onTap: () {
                                // Navigate to tenant detail
                              },
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
}

