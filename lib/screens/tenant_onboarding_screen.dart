import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/tenant.dart';
import '../services/tenant_service.dart';
import '../services/invitation_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TenantOnboardingScreen extends StatefulWidget {
  final String? invitationToken;
  final String? roomNumber;
  final String? buildingId;
  final String? roomId;

  const TenantOnboardingScreen({
    super.key,
    this.invitationToken,
    this.roomNumber,
    this.buildingId,
    this.roomId,
  });

  @override
  State<TenantOnboardingScreen> createState() => _TenantOnboardingScreenState();
}

class _TenantOnboardingScreenState extends State<TenantOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadharController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactRelationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _rentController = TextEditingController();
  
  DateTime? _moveInDate;
  String _tenantType = 'tenant';
  
  // Document files
  File? _profileImage;
  File? _aadharFrontImage;
  File? _aadharBackImage;
  File? _panCardImage;
  File? _addressProofImage;
  
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    debugPrint('');
    debugPrint('🎯 ===== TENANT ONBOARDING SCREEN INIT =====');
    debugPrint('🎯 [INIT] Invitation Token: ${widget.invitationToken}');
    debugPrint('🎯 [INIT] Room Number: ${widget.roomNumber}');
    debugPrint('🎯 [INIT] Building ID: ${widget.buildingId}');
    debugPrint('🎯 [INIT] Room ID: ${widget.roomId}');
    debugPrint('🎯 ===== TENANT ONBOARDING SCREEN INIT END =====');
    debugPrint('');
    
    if (widget.roomNumber != null) {
      _roomNumberController.text = widget.roomNumber!;
    }
    
    // If room ID is provided, load room details to populate form
    if (widget.roomId != null && widget.roomId!.isNotEmpty) {
      _loadRoomDetails();
    }
  }
  
  Future<void> _loadRoomDetails() async {
    try {
      final ownerId = AuthService.getOwnerId();
      final room = await ApiService.getRoomById(
        ownerId: ownerId,
        roomId: widget.roomId!,
      );
      
      if (room != null && mounted) {
        setState(() {
          _roomNumberController.text = room.number;
          _rentController.text = room.rent.toStringAsFixed(0);
        });
        debugPrint('✅ [ONBOARDING] Pre-filled room details from room ID');
      }
    } catch (e) {
      debugPrint('❌ [ONBOARDING] Error loading room details: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aadharController.dispose();
    _emergencyContactController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactRelationController.dispose();
    _occupationController.dispose();
    _roomNumberController.dispose();
    _rentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, Function(File) onPicked) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        onPicked(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickDocument(String type) async {
    try {
      // Show dialog to choose source
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          final file = File(image.path);
          setState(() {
            switch (type) {
              case 'aadhar_front':
                _aadharFrontImage = file;
                break;
              case 'aadhar_back':
                _aadharBackImage = file;
                break;
              case 'pan':
                _panCardImage = file;
                break;
              case 'address_proof':
                _addressProofImage = file;
                break;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking document: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _moveInDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required documents
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a profile photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_aadharFrontImage == null || _aadharBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both sides of Aadhar card'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate emergency contact details
    if (_emergencyContactNameController.text.trim().isEmpty ||
        _emergencyContactController.text.trim().isEmpty ||
        _emergencyContactRelationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all emergency contact details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('');
      debugPrint('🎯 ===== TENANT ONBOARDING SUBMISSION START =====');
      debugPrint('🎯 [ONBOARDING] Starting tenant registration process...');
      debugPrint('🎯 [ONBOARDING] Tenant Name: ${_nameController.text.trim()}');
      debugPrint('🎯 [ONBOARDING] Room Number: ${_roomNumberController.text.trim()}');
      debugPrint('🎯 [ONBOARDING] Building ID: ${widget.buildingId ?? 'Not provided'}');
      debugPrint('🎯 [ONBOARDING] Invitation Token: ${widget.invitationToken ?? 'Not provided'}');
      debugPrint('');

      // Show progress message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Creating your account...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get owner ID
      final ownerId = AuthService.getOwnerId();
      debugPrint('🎯 [ONBOARDING] Owner ID: $ownerId');
      
      // Get room ID - use direct room ID if available, otherwise lookup
      String? roomId = widget.roomId;
      
      if (roomId != null && roomId.isNotEmpty) {
        debugPrint('✅ [ONBOARDING] Using room ID from invitation: $roomId');
      } else {
        debugPrint('🎯 [ONBOARDING] Room ID not provided, looking up room ID...');
        roomId = await ApiService.getRoomIdByNumber(
          ownerId: ownerId,
          roomNumber: _roomNumberController.text.trim(),
          buildingId: widget.buildingId,
        );

        if (roomId == null) {
          debugPrint('❌ [ONBOARDING] FAILED: Room ID not found!');
          throw Exception('Room not found. Please check the room number.');
        }
        
        debugPrint('✅ [ONBOARDING] Room ID found via lookup: $roomId');
      }

      // Calculate lease end date (1 year from move-in date)
      final moveInDate = _moveInDate ?? DateTime.now();
      final leaseEndDate = DateTime(moveInDate.year + 1, moveInDate.month, moveInDate.day);
      
      // Format dates for API
      final moveInDateStr = DateFormat('yyyy-MM-dd').format(moveInDate);
      final leaseEndDateStr = DateFormat('yyyy-MM-dd').format(leaseEndDate);
      
      // Calculate deposit (typically 2 months rent)
      final monthlyRent = double.tryParse(_rentController.text) ?? 0.0;
      final depositPaid = monthlyRent * 2;

      debugPrint('🎯 [ONBOARDING] Calculated values:');
      debugPrint('🎯 [ONBOARDING] - Move-in Date: $moveInDateStr');
      debugPrint('🎯 [ONBOARDING] - Lease End Date: $leaseEndDateStr');
      debugPrint('🎯 [ONBOARDING] - Monthly Rent: ₹$monthlyRent');
      debugPrint('🎯 [ONBOARDING] - Deposit: ₹$depositPaid');
      debugPrint('');

      debugPrint('🎯 [ONBOARDING] Calling API to create tenant...');
      // Call API to create tenant
      final response = await ApiService.createTenant(
        roomId: roomId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        emergencyContactName: _emergencyContactNameController.text.trim(),
        emergencyContactPhone: _emergencyContactController.text.trim(),
        emergencyContactRelation: _emergencyContactRelationController.text.trim(),
        idProofType: 'aadhar',
        idProofNumber: _aadharController.text.trim(),
        moveInDate: moveInDateStr,
        leaseEndDate: leaseEndDateStr,
        depositPaid: depositPaid,
        occupation: _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        invitationToken: widget.invitationToken,
      );

      debugPrint('✅ [ONBOARDING] API call successful!');
      debugPrint('✅ [ONBOARDING] API Response: $response');

      // Also save to local storage for offline access
      final tenantId = response['data']?['id']?.toString() ?? 
                      DateTime.now().millisecondsSinceEpoch.toString();
      
      debugPrint('🎯 [ONBOARDING] Saving to local storage...');
      debugPrint('🎯 [ONBOARDING] Local Tenant ID: $tenantId');
      
      final tenant = Tenant(
        id: tenantId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        roomNumber: _roomNumberController.text.trim(),
        moveInDate: moveInDate,
        monthlyRent: monthlyRent,
        type: _tenantType,
        isActive: true,
        aadharNumber: _aadharController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        occupation: _occupationController.text.trim(),
        profileImage: _profileImage?.path,
        aadharFrontImage: _aadharFrontImage?.path,
        aadharBackImage: _aadharBackImage?.path,
        panCardImage: _panCardImage?.path,
        addressProofImage: _addressProofImage?.path,
        invitationToken: widget.invitationToken,
      );

      await TenantService.addTenant(tenant);
      debugPrint('✅ [ONBOARDING] Saved to local storage successfully!');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        debugPrint('✅ [ONBOARDING] SUCCESS: Registration completed!');
        debugPrint('🎯 ===== TENANT ONBOARDING SUBMISSION END =====');
        debugPrint('');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome ${_nameController.text.trim()}! Registration completed successfully.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Navigate back or to success screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('❌ [ONBOARDING] FAILED: Registration failed!');
      debugPrint('❌ [ONBOARDING] Error: $e');
      debugPrint('❌ [ONBOARDING] Error Type: ${e.runtimeType}');
      debugPrint('🎯 ===== TENANT ONBOARDING SUBMISSION END =====');
      debugPrint('');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage = 'Registration failed. Please try again.';
        if (e.toString().contains('Room not found')) {
          errorMessage = 'Room not found. Please check the room number.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        
        debugPrint('❌ [ONBOARDING] Showed error message to user: $errorMessage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tenant Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 20 : 24,
            color: Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildPersonalDetailsStep(isMobile),
            _buildContactDetailsStep(isMobile),
            _buildDocumentsStep(isMobile),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() {
                      _currentStep--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Previous'),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _currentStep < 2
                    ? () {
                        if (_validateCurrentStep()) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.bounceInOut,
                          );
                          setState(() {
                            _currentStep++;
                          });
                        }
                      }
                    : _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                        _currentStep < 2 ? 'Next' : 'Submit',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty ||
            _roomNumberController.text.trim().isEmpty ||
            _rentController.text.trim().isEmpty ||
            _moveInDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all required fields'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      case 1:
        if (_phoneController.text.trim().isEmpty ||
            _emailController.text.trim().isEmpty ||
            _aadharController.text.trim().isEmpty ||
            _emergencyContactNameController.text.trim().isEmpty ||
            _emergencyContactController.text.trim().isEmpty ||
            _emergencyContactRelationController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all required fields'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Widget _buildPersonalDetailsStep(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 1 of 3',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          
          // Profile Photo
          Center(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose from Gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery, (file) {
                              setState(() {
                                _profileImage = file;
                              });
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take Photo'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera, (file) {
                              setState(() {
                                _profileImage = file;
                              });
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 60 : 80,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(
                            Icons.person,
                            size: isMobile ? 60 : 80,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'Enter your full name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Room Number
          TextFormField(
            controller: _roomNumberController,
            decoration: InputDecoration(
              labelText: 'Room Number *',
              hintText: 'e.g., 101, 201',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.room),
            ),
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter room number';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Tenant Type
          Text(
            'Tenant Type *',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Tenant'),
                  value: 'tenant',
                  groupValue: _tenantType,
                  onChanged: (value) {
                    setState(() {
                      _tenantType = value!;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Paying Guest'),
                  value: 'paying_guest',
                  groupValue: _tenantType,
                  onChanged: (value) {
                    setState(() {
                      _tenantType = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Monthly Rent
          TextFormField(
            controller: _rentController,
            decoration: InputDecoration(
              labelText: 'Monthly Rent (₹) *',
              hintText: 'e.g., 15000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.currency_rupee),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter monthly rent';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Move-in Date
          GestureDetector(
            onTap: _selectDate,
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Move-in Date *',
                  hintText: _moveInDate == null
                      ? 'Select move-in date'
                      : DateFormat('MMM dd, yyyy').format(_moveInDate!),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: _moveInDate == null
                      ? ''
                      : DateFormat('MMM dd, yyyy').format(_moveInDate!),
                ),
                validator: (value) {
                  if (_moveInDate == null) {
                    return 'Please select move-in date';
                  }
                  return null;
                },
              ),
            ),
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Occupation
          TextFormField(
            controller: _occupationController,
            decoration: InputDecoration(
              labelText: 'Occupation (Optional)',
              hintText: 'e.g., Software Engineer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.work),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetailsStep(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Details',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 2 of 3',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          
          // Phone
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              hintText: '+91 9876543210',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter phone number';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              hintText: 'your.email@example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter email address';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Aadhar Number
          TextFormField(
            controller: _aadharController,
            decoration: InputDecoration(
              labelText: 'Aadhar Number *',
              hintText: '1234 5678 9012',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.badge),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter Aadhar number';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Emergency Contact Name
          TextFormField(
            controller: _emergencyContactNameController,
            decoration: InputDecoration(
              labelText: 'Emergency Contact Name *',
              hintText: 'e.g., John Smith',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter emergency contact name';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Emergency Contact Phone
          TextFormField(
            controller: _emergencyContactController,
            decoration: InputDecoration(
              labelText: 'Emergency Contact Phone *',
              hintText: '+91 9876543210',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.emergency),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter emergency contact phone';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Emergency Contact Relation
          TextFormField(
            controller: _emergencyContactRelationController,
            decoration: InputDecoration(
              labelText: 'Relation *',
              hintText: 'e.g., Father, Mother, Spouse, Friend',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.family_restroom),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter relation';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Documents',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 3 of 3',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          
          _buildDocumentUpload(
            'Aadhar Card (Front) *',
            _aadharFrontImage,
            () => _pickDocument('aadhar_front'),
            isMobile,
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          _buildDocumentUpload(
            'Aadhar Card (Back) *',
            _aadharBackImage,
            () => _pickDocument('aadhar_back'),
            isMobile,
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          _buildDocumentUpload(
            'PAN Card (Optional)',
            _panCardImage,
            () => _pickDocument('pan'),
            isMobile,
            required: false,
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          _buildDocumentUpload(
            'Address Proof (Optional)',
            _addressProofImage,
            () => _pickDocument('address_proof'),
            isMobile,
            required: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload(
    String title,
    File? file,
    VoidCallback onTap,
    bool isMobile, {
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: isMobile ? 120 : 150,
            decoration: BoxDecoration(
              border: Border.all(
                color: file != null
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: file != null
                  ? AppTheme.primaryColor.withOpacity(0.05)
                  : Colors.grey.shade50,
            ),
            child: file != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          file,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (title.contains('Front')) {
                                  _aadharFrontImage = null;
                                } else if (title.contains('Back')) {
                                  _aadharBackImage = null;
                                } else if (title.contains('PAN')) {
                                  _panCardImage = null;
                                } else if (title.contains('Address')) {
                                  _addressProofImage = null;
                                }
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: isMobile ? 40 : 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

