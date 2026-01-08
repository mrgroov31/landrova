import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/api_tenant.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TenantDetailScreen extends StatefulWidget {
  final ApiTenant tenant;

  const TenantDetailScreen({
    super.key,
    required this.tenant,
  });

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // App Bar with Tenant Info
          SliverAppBar(
            expandedHeight: isMobile ? 200 : 250,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.tenant.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 40 : 50,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          widget.tenant.name.isNotEmpty 
                              ? widget.tenant.name[0].toUpperCase() 
                              : 'T',
                          style: TextStyle(
                            fontSize: isMobile ? 32 : 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.tenant.isActive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.tenant.isActive
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          widget.tenant.isActive ? 'Active Tenant' : 'Inactive Tenant',
                          style: TextStyle(
                            color: widget.tenant.isActive
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  _showOptionsMenu(context);
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                _buildQuickActions(isMobile),

                // Personal Information
                _buildPersonalInfoCard(isMobile),

                // Property Information
                _buildPropertyInfoCard(isMobile),

                // Financial Information
                _buildFinancialInfoCard(isMobile),

                // Timeline Information
                if (widget.tenant.moveInDate != null || widget.tenant.leaseEndDate != null)
                  _buildTimelineCard(dateFormat, isMobile),

                // Contact Information
                _buildContactInfoCard(isMobile),

                SizedBox(height: isMobile ? 16 : 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone,
              label: 'Call',
              color: Colors.green,
              onTap: () => _makePhoneCall(widget.tenant.phone),
              isMobile: isMobile,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.message,
              label: 'Message',
              color: Colors.blue,
              onTap: () => _sendSMS(widget.tenant.phone),
              isMobile: isMobile,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.email,
              label: 'Email',
              color: Colors.orange,
              onTap: () => _sendEmail(widget.tenant.email),
              isMobile: isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 16 : 20,
              horizontal: 8,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: isMobile ? 24 : 28,
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
                'Personal Information',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildDetailRow('Full Name', widget.tenant.name, isMobile),
          _buildDetailRow('Tenant Type', widget.tenant.typeDisplayName, isMobile),
          if (widget.tenant.occupation != null && widget.tenant.occupation!.isNotEmpty)
            _buildDetailRow('Occupation', widget.tenant.occupation!, isMobile),
          if (widget.tenant.aadharNumber != null && widget.tenant.aadharNumber!.isNotEmpty)
            _buildDetailRow('Aadhar Number', widget.tenant.aadharNumber!, isMobile),
        ],
      ),
    );
  }

  Widget _buildPropertyInfoCard(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
              Icon(Icons.home, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Property Information',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildDetailRow('Room Number', widget.tenant.roomNumber, isMobile),
          _buildDetailRow('Building', widget.tenant.buildingName, isMobile),
          if (widget.tenant.building?.address != null)
            _buildDetailRow('Address', widget.tenant.fullAddress, isMobile),
        ],
      ),
    );
  }

  Widget _buildFinancialInfoCard(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
              Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Financial Information',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildDetailRow('Monthly Rent', '₹${widget.tenant.monthlyRent.toStringAsFixed(0)}', isMobile),
          if (widget.tenant.depositPaid != null)
            _buildDetailRow('Deposit Paid', '₹${widget.tenant.depositPaid!.toStringAsFixed(0)}', isMobile),
          
          // Calculate yearly rent inline
          _buildDetailRow('Yearly Rent', '₹${(widget.tenant.monthlyRent * 12).toStringAsFixed(0)}', isMobile),
      
        ],
      ),
    );
  }

  Widget _buildTimelineCard(DateFormat dateFormat, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
              Icon(Icons.schedule, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Timeline',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          if (widget.tenant.moveInDate != null)
            _buildDetailRow('Move-in Date', dateFormat.format(widget.tenant.moveInDate!), isMobile),
          if (widget.tenant.leaseEndDate != null)
            _buildDetailRow('Lease End Date', dateFormat.format(widget.tenant.leaseEndDate!), isMobile),
          
          // Calculate and show tenure
          if (widget.tenant.moveInDate != null) ...[
            SizedBox(height: isMobile ? 12 : 16),
            _buildTenureInfo(widget.tenant.moveInDate!, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
              Icon(Icons.contact_phone, color: AppTheme.primaryColor, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildContactRow('Phone', widget.tenant.phone, Icons.phone, () => _makePhoneCall(widget.tenant.phone), isMobile),
          _buildContactRow('Email', widget.tenant.email, Icons.email, () => _sendEmail(widget.tenant.email), isMobile),
          if (widget.tenant.emergencyContact != null && widget.tenant.emergencyContact!.isNotEmpty)
            _buildContactRow('Emergency Contact', widget.tenant.emergencyContact!, Icons.emergency, () => _makePhoneCall(widget.tenant.emergencyContact!), isMobile),
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
            Icons.access_time,
            color: AppTheme.primaryColor,
            size: isMobile ? 18 : 20,
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Tenure',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.grey.shade600,
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
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 13 : 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value, IconData icon, VoidCallback onTap, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Row(
        children: [
          SizedBox(
            width: isMobile ? 100 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 13 : 15,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Tenant'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit tenant feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('View Payments'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment history feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text('View Complaints'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complaints feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Colors.red.shade600),
              title: Text('Deactivate Tenant', style: TextStyle(color: Colors.red.shade600)),
              onTap: () {
                Navigator.pop(context);
                _showDeactivateDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Tenant'),
        content: Text('Are you sure you want to deactivate ${widget.tenant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deactivate tenant feature coming soon')),
              );
            },
            child: Text('Deactivate', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone call to $phoneNumber')),
        );
      }
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch SMS to $phoneNumber')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch email to $email')),
        );
      }
    }
  }
}