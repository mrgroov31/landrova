import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/owner_upi_details.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class OwnerUpiSetupScreen extends StatefulWidget {
  final OwnerUpiDetails? existingDetails;
  
  const OwnerUpiSetupScreen({super.key, this.existingDetails});

  @override
  State<OwnerUpiSetupScreen> createState() => _OwnerUpiSetupScreenState();
}

class _OwnerUpiSetupScreenState extends State<OwnerUpiSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    if (widget.existingDetails != null) {
      _populateExistingDetails();
    } else {
      _populateOwnerName();
    }
  }

  void _populateExistingDetails() {
    final details = widget.existingDetails!;
    _upiIdController.text = details.upiId;
    _ownerNameController.text = details.ownerName;
    _bankNameController.text = details.bankName;
    _accountNumberController.text = details.accountNumber;
  }

  void _populateOwnerName() {
    final user = AuthService.currentUser;
    if (user != null) {
      _ownerNameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _ownerNameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(widget.existingDetails != null ? 'Update UPI Details' : 'Setup UPI Payment'),
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4285F4), Color(0xFF34A853)],
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UPI Payment Setup',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Configure where tenant payments will be received',
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
              
              // UPI ID Field
              _buildFormField(
                controller: _upiIdController,
                label: 'UPI ID',
                hint: 'yourname@paytm, yourname@phonepe, etc.',
                icon: Icons.alternate_email,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your UPI ID';
                  }
                  if (!OwnerUpiDetails.isValidUpiId(value)) {
                    return 'Please enter a valid UPI ID (e.g., name@paytm)';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _verificationError = null;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Owner Name Field
              _buildFormField(
                controller: _ownerNameController,
                label: 'Account Holder Name',
                hint: 'Name as per bank account',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account holder name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Bank Name Field
              _buildFormField(
                controller: _bankNameController,
                label: 'Bank Name',
                hint: 'State Bank of India, HDFC Bank, etc.',
                icon: Icons.account_balance,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bank name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Account Number Field (Last 4 digits for verification)
              _buildFormField(
                controller: _accountNumberController,
                label: 'Account Number (Last 4 digits)',
                hint: 'Last 4 digits of your account number',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter last 4 digits of account number';
                  }
                  if (value.length != 4) {
                    return 'Please enter exactly 4 digits';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Verification Error
              if (_verificationError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _verificationError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
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
                          'Important Information',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• All tenant payments will be sent directly to this UPI ID\n'
                      '• Make sure your UPI ID is active and verified\n'
                      '• You can update these details anytime from settings\n'
                      '• We only store the last 4 digits of your account number',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  if (widget.existingDetails != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _verifyUpiId,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verify UPI'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveUpiDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.existingDetails != null ? 'Update Details' : 'Save & Continue',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: AppTheme.getCardColor(context),
            counterText: '', // Hide character counter
          ),
        ),
      ],
    );
  }

  Future<void> _verifyUpiId() async {
    if (_upiIdController.text.isEmpty) {
      setState(() {
        _verificationError = 'Please enter UPI ID first';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    try {
      // Simulate UPI verification (in real app, call verification API)
      await Future.delayed(const Duration(seconds: 2));
      
      // For demo, we'll just validate the format
      if (OwnerUpiDetails.isValidUpiId(_upiIdController.text)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('UPI ID format is valid!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _verificationError = 'Invalid UPI ID format';
        });
      }
    } catch (e) {
      setState(() {
        _verificationError = 'Verification failed: $e';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _saveUpiDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final upiDetails = OwnerUpiDetails(
        id: widget.existingDetails?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ownerId: user.id,
        upiId: _upiIdController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        isVerified: false, // Will be verified by backend
        isActive: true,
        createdAt: widget.existingDetails?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to backend
      final response = await ApiService.saveOwnerUpiDetails(upiDetails);
      
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingDetails != null 
                  ? 'UPI details updated successfully!' 
                  : 'UPI details saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, upiDetails);
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to save UPI details');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}