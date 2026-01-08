import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/complaint_service.dart';
import '../services/tenant_service.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../models/complaint.dart';
import '../models/tenant.dart';
import '../models/room.dart';
import '../models/payment.dart';
import '../models/user.dart';
import 'unified_login_screen.dart';
import 'complaints_screen.dart';
import 'add_complaint_screen.dart';
import 'vacating_request_form_screen.dart';
import 'complaint_detail_screen.dart';
import 'public_rooms_listing_screen.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  List<Complaint> _complaints = [];
  Tenant? _tenant;
  Room? _room;
  List<Payment> _payments = [];
  bool _isLoading = true;
  Timer? _countdownTimer;
  int _daysUntilNextPayment = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    // Update countdown every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _daysUntilNextPayment = _getDaysUntilNextPayment();
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user != null && user.isTenant) {
        // Load tenant details
        final tenantId = user.additionalData?['tenantId'] as String? ?? user.id;
        final tenant = await TenantService.getTenantById(tenantId);
        
        // Load room details
        final roomNumber = user.additionalData?['roomNumber'] as String?;
        if (roomNumber != null) {
          final room = await TenantService.getTenantByRoomNumber(roomNumber);
          if (room != null) {
            // Get room from API
            try {
              final response = await ApiService.fetchRooms();
              final allRooms = ApiService.parseRooms(response);
              final userRoom = allRooms.firstWhere(
                (r) => r.number == roomNumber,
                orElse: () => allRooms.first,
              );
              setState(() {
                _room = userRoom;
              });
            } catch (e) {
              // Room not found, continue
            }
          }
        }
        
        // Load complaints
        final allComplaints = await ComplaintService.getAllComplaints();
        final userComplaints = allComplaints.where((c) => c.tenantId == tenantId).toList();
        
        // Load payments
        try {
          final paymentResponse = await ApiService.fetchPayments();
          final allPayments = ApiService.parsePayments(paymentResponse);
          final userPayments = allPayments.where((p) => p.tenantId == tenantId).toList();
          setState(() {
            _payments = userPayments;
          });
        } catch (e) {
          // Payments not available
        }
        
        setState(() {
          _tenant = tenant;
          _complaints = userComplaints;
          _daysUntilNextPayment = _getDaysUntilNextPayment();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final user = AuthService.currentUser;
    final roomNumber = user?.additionalData?['roomNumber'] as String?;
    final hasRoom = roomNumber != null && roomNumber != 'N/A' && roomNumber.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddComplaintScreen(),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Complaint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: () async {
                        await AuthService.logout();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),

                // Main Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Room Card or Find Rooms Card
                        if (hasRoom)
                          _buildRoomCard(context, isMobile, user, roomNumber)
                        else
                          _buildFindRoomsCard(context, isMobile, user),

                        if (hasRoom) ...[
                          const SizedBox(height: 16),

                          // Info Cards (Rent Due & Roommates if PG)
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  context: context,
                                  title: 'Rent Due',
                                  icon: Icons.calendar_today,
                                  value: '', // Value is handled in _buildRentDueCard
                                  isMobile: isMobile,
                                ),
                              ),
                              if (_isPGProperty()) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInfoCard(
                                    context: context,
                                    title: 'Roommates',
                                    icon: Icons.people,
                                    value: _getRoommatesCount(),
                                    isMobile: isMobile,
                                    isPeople: true,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Quick Actions Section
                        _buildQuickActions(context, isMobile),

                        const SizedBox(height: 24),

                        // Complaints List
                        _buildComplaintsList(context, isMobile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFindRoomsCard(BuildContext context, bool isMobile, AppUser? user) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            'Find Your Room',
            style: TextStyle(
              fontSize: isMobile ? 28 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            'Search for available rooms in your area',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 24),

          // Find Rooms Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showLocationDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Find Rooms',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationDialog(BuildContext context) async {
    final locationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Enter Your Location',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your city or area to find nearby available rooms',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'City / Area',
                  hintText: 'e.g., Mumbai, Bangalore',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your location';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, locationController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      // Navigate to public rooms listing screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PublicRoomsListingScreen(),
        ),
      );
    }
  }

  Widget _buildRoomCard(BuildContext context, bool isMobile, AppUser? user, String roomNumber) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Room Title
          Text(
            'Room $roomNumber',
            style: TextStyle(
              fontSize: isMobile ? 28 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          // Tenant Info
          Row(
            children: [
              Text(
                'Tenant: ',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'T',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                user?.name ?? 'Tenant',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String value,
    required bool isMobile,
    bool isPeople = false,
  }) {
    if (title == 'Rent Due') {
      return _buildRentDueCard(context, isMobile);
    }
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentDueCard(BuildContext context, bool isMobile) {
    final isPaidThisMonth = _isPaidThisMonth();
    final nextPaymentDate = _getNextPaymentDate();
    final daysUntilNext = _daysUntilNextPayment;
    final isDueSoon = daysUntilNext <= 5 && daysUntilNext >= 0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: isPaidThisMonth
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
              )
            : isDueSoon
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade50,
                      Colors.orange.shade100,
                    ],
                  )
                : null,
        color: isPaidThisMonth || isDueSoon ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaidThisMonth
              ? Colors.green.shade200
              : isDueSoon
                  ? Colors.orange.shade200
                  : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPaidThisMonth ? Colors.green : isDueSoon ? Colors.orange : Colors.grey)
                .shade200
                .withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rent Status',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isPaidThisMonth)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Paid',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isDueSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Due Soon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isPaidThisMonth) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid This Month',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Next payment: ${_formatDate(nextPaymentDate)}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Next payment in ',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$daysUntilNext ${daysUntilNext == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryColor,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(nextPaymentDate),
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        daysUntilNext > 0
                            ? '$daysUntilNext ${daysUntilNext == 1 ? 'day' : 'days'} remaining'
                            : 'Payment due today',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: isDueSoon ? Colors.orange.shade700 : Colors.grey.shade600,
                          fontWeight: isDueSoon ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isDueSoon) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment feature coming soon'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Pay Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionCard(
              context: context,
              title: 'Room Details',
              icon: Icons.room,
              color: Colors.blue,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Room details coming soon')),
                );
              },
              isMobile: isMobile,
            ),
            _buildQuickActionCard(
              context: context,
              title: 'Vacate Room',
              icon: Icons.exit_to_app,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VacatingRequestFormScreen(),
                  ),
                );
              },
              isMobile: isMobile,
            ),
            _buildQuickActionCard(
              context: context,
              title: 'All Complaints',
              icon: Icons.list_alt,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComplaintsScreen(),
                  ),
                );
              },
              isMobile: isMobile,
            ),
            _buildQuickActionCard(
              context: context,
              title: 'Payments',
              icon: Icons.payment,
              color: Colors.purple,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment history coming soon'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              isMobile: isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: isMobile ? 28 : 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
                fontSize: isMobile ? 13 : 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildComplaintsList(BuildContext context, bool isMobile) {
    if (_complaints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No complaints yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddComplaintScreen(),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Complaint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Complaints',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComplaintsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._complaints.take(5).map((complaint) => _buildComplaintCard(context, complaint, isMobile)),
      ],
    );
  }

  Widget _buildComplaintCard(BuildContext context, Complaint complaint, bool isMobile) {
    final isResolved = complaint.status == 'resolved';
    final priorityColors = {
      'low': Colors.green,
      'medium': Colors.orange,
      'high': Colors.red,
      'urgent': Colors.purple,
    };
    final priorityColor = priorityColors[complaint.priority.toLowerCase()] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailScreen(complaint: complaint),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Status Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isResolved
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isResolved ? Icons.check_circle : Icons.pending,
                color: isResolved ? Colors.green : Colors.orange,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Complaint Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.title,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Room ${complaint.roomNumber}',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag,
                    size: 12,
                    color: priorityColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    complaint.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // More Options
            Icon(
              Icons.more_vert,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }


  bool _isPaidThisMonth() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Check if there's a paid payment for current month
    return _payments.any((payment) =>
        payment.status == 'paid' &&
        payment.year == currentYear &&
        payment.month.toLowerCase() == _getMonthName(currentMonth).toLowerCase());
  }

  DateTime _getNextPaymentDate() {
    final now = DateTime.now();
    
    // If paid this month, next payment is next month
    if (_isPaidThisMonth()) {
      return DateTime(now.year, now.month + 1, 1);
    }
    
    // Otherwise, current month's due date
    return DateTime(now.year, now.month, 1);
  }

  int _getDaysUntilNextPayment() {
    final nextDate = _getNextPaymentDate();
    final now = DateTime.now();
    final difference = nextDate.difference(now).inDays;
    return difference >= 0 ? difference : 0;
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    final month = _getMonthName(date.month);
    return '$day $month';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  bool _isPGProperty() {
    // Check if room type is PG
    return _room?.type.toLowerCase() == 'pg';
  }

  String _getRoommatesCount() {
    if (_room != null) {
      return '${_room!.currentOccupancy}/${_room!.capacity}';
    }
    return 'N/A';
  }
}
