import 'package:flutter/material.dart';
import '../models/owner_upi_details.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'owner_upi_setup_screen.dart';

class OwnerUpiManagementScreen extends StatefulWidget {
  const OwnerUpiManagementScreen({super.key});

  @override
  State<OwnerUpiManagementScreen> createState() => _OwnerUpiManagementScreenState();
}

class _OwnerUpiManagementScreenState extends State<OwnerUpiManagementScreen> {
  OwnerUpiDetails? _upiDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpiDetails();
  }

  Future<void> _loadUpiDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.getOwnerUpiDetails(user.id);
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _upiDetails = OwnerUpiDetails.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _upiDetails = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('UPI Payment Settings'),
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        elevation: 0,
        actions: [
          if (_upiDetails != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editUpiDetails,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _upiDetails == null
                  ? _buildNoUpiState(isMobile)
                  : _buildUpiDetailsState(isMobile),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error loading UPI details',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUpiDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUpiState(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Setup UPI Payment',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Configure your UPI details to receive payments directly from tenants',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: AppTheme.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Benefits
          _buildBenefitItem(
            icon: Icons.flash_on,
            title: 'Instant Payments',
            subtitle: 'Receive payments directly in your bank account',
            isMobile: isMobile,
          ),
          
          const SizedBox(height: 16),
          
          _buildBenefitItem(
            icon: Icons.security,
            title: 'Secure & Safe',
            subtitle: 'UPI payments are protected by bank-level security',
            isMobile: isMobile,
          ),
          
          const SizedBox(height: 16),
          
          _buildBenefitItem(
            icon: Icons.phone_android,
            title: 'Easy for Tenants',
            subtitle: 'Tenants can pay using any UPI app like Google Pay, PhonePe',
            isMobile: isMobile,
          ),
          
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _setupUpiDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                'Setup UPI Payment',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiDetailsState(bool isMobile) {
    final details = _upiDetails!;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: details.isVerified 
                    ? [Colors.green, Colors.green.shade600]
                    : [Colors.orange, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        details.isVerified ? Icons.verified : Icons.pending,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details.isVerified ? 'UPI Verified' : 'Verification Pending',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            details.isVerified 
                                ? 'Ready to receive payments'
                                : 'We\'re verifying your UPI details',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // UPI Details Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPI Details',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                _buildDetailRow(
                  icon: Icons.alternate_email,
                  label: 'UPI ID',
                  value: details.upiId,
                  isMobile: isMobile,
                ),
                
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  icon: Icons.person,
                  label: 'Account Holder',
                  value: details.ownerName,
                  isMobile: isMobile,
                ),
                
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  icon: Icons.account_balance,
                  label: 'Bank',
                  value: details.bankName,
                  isMobile: isMobile,
                ),
                
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  icon: Icons.credit_card,
                  label: 'Account',
                  value: details.displayAccountNumber,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testUpiPayment,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Payment'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _editUpiDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Details'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'How it works',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Tenants see your UPI ID when making payments\n'
                  '• Money goes directly to your bank account\n'
                  '• You get instant notifications for all payments\n'
                  '• All transactions are tracked in the app',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _setupUpiDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OwnerUpiSetupScreen(),
      ),
    );

    if (result != null) {
      _loadUpiDetails();
    }
  }

  Future<void> _editUpiDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerUpiSetupScreen(existingDetails: _upiDetails),
      ),
    );

    if (result != null) {
      _loadUpiDetails();
    }
  }

  void _testUpiPayment() {
    if (_upiDetails == null) return;
    
    final testUrl = _upiDetails!.generateUpiUrl(
      amount: 1.0,
      transactionId: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
      description: 'Test payment - ₹1',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test UPI Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will open your UPI app with a ₹1 test payment.'),
            const SizedBox(height: 16),
            const Text('UPI URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                testUrl,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, you would launch the UPI URL here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test payment URL generated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Test'),
          ),
        ],
      ),
    );
  }
}