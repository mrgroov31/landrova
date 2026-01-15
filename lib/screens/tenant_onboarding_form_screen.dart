import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/tenant.dart';
import '../services/tenant_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'manage_room_occupants_screen.dart';

class TenantOnboardingFormScreen extends StatefulWidget {
  final String roomNumber;
  final String roomId;
  final String? buildingId;
  final double monthlyRent;
  final bool isPrimaryTenant;
  final RoomOccupant? existingOccupant; // For editing

  const TenantOnboardingFormScreen({
    super.key,
    required this.roomNumber,
    required this.roomId,
    this.buildingId,
    required this.monthlyRent,
    this.isPrimaryTenant = true,
    this.existingOccupant,
  });

  @override
  State<TenantOnboardingFormScreen> createState() => _TenantOnboardingFormScreenState();
}

class _TenantOnboardingFormScreenState extends State<TenantOnboardingFormScreen> {
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
  
  DateTime? _moveInDate;
  String _tenantType = 'tenant';
  bool _isActive = true;
  
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
    
    // Pre-fill data if editing existing occupant
    if (widget.existingOccupant != null) {
      _nameController.text = widget.existingOccupant!.name;
      _phoneController.text = widget.existingOccupant!.phone;
      _emailController.text = widget.existingOccupant!.email;
      _moveInDate = widget.existingOccupant!.moveInDate;
      _isActive = widget.existingOccupant!.isActive;
    } else {
      _moveInDate = DateTime.now();
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
      initialDate: _moveInDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    // Validate required documents for new occupants
    if (widget.existingOccupant == null) {
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
      debugPrint('🏠 [ROOM OCCUPANT] Creating/updating occupant for room ${widget.roomNumber}');
      
      // Show progress message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(widget.existingOccupant == null ? 'Adding occupant...' : 'Updating occupant...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // If this is a primary tenant, also create tenant record via API
      if (widget.isPrimaryTenant && widget.existingOccupant == null) {
        try {
          final ownerId = AuthService.getOwnerId();
          
          // Calculate lease end date (1 year from move-in date)
          final moveInDate = _moveInDate ?? DateTime.now();
          final leaseEndDate = DateTime(moveInDate.year + 1, moveInDate.month, moveInDate.day);
          
          // Format dates for API
          final moveInDateStr = DateFormat('yyyy-MM-dd').format(moveInDate);
          final leaseEndDateStr = DateFormat('yyyy-MM-dd').format(leaseEndDate);
          
          // Calculate deposit (typically 2 months rent)
          final depositPaid = widget.monthlyRent * 2;

          // Call API to create tenant
          final response = await ApiService.createTenant(
            roomId: widget.roomId,
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
            roomNumber: widget.roomNumber,
          );

          debugPrint('✅ [ROOM OCCUPANT] API call successful: $response');

          // Also save to local storage for offline access
          final tenantId = response['data']?['id']?.toString() ?? 
                          DateTime.now().millisecondsSinceEpoch.toString();
          
          final tenant = Tenant(
            id: tenantId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            roomNumber: widget.roomNumber,
            moveInDate: moveInDate,
            monthlyRent: widget.monthlyRent,
            type: _tenantType,
            isActive: _isActive,
            aadharNumber: _aadharController.text.trim(),
            emergencyContact: _emergencyContactController.text.trim(),
            occupation: _occupationController.text.trim(),
            profileImage: _profileImage?.path,
            aadharFrontImage: _aadharFrontImage?.path,
            aadharBackImage: _aadharBackImage?.path,
            panCardImage: _panCardImage?.path,
            addressProofImage: _addressProofImage?.path,
          );

          await TenantService.addTenant(tenant);
          debugPrint('✅ [ROOM OCCUPANT] Saved to local storage successfully');
        } catch (e) {
          debugPrint('⚠️ [ROOM OCCUPANT] API call failed, continuing with local data: $e');
        }
      }

      // Create RoomOccupant object
      final occupant = RoomOccupant(
        id: widget.existingOccupant?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        moveInDate: _moveInDate,
        isPrimaryTenant: widget.isPrimaryTenant,
        isActive: _isActive,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingOccupant == null 
                ? 'Occupant added successfully!' 
                : 'Occupant updated successfully!'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      
        // Return the occupant to the previous screen
        Navigator.of(context).pop(occupant);
      }
    } catch (e) {
      debugPrint('❌ [ROOM OCCUPANT] Failed: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage = widget.existingOccupant == null 
          ? 'Failed to add occupant. Please try again.'
          : 'Failed to update occupant. Please try again.';
        
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isEditing = widget.existingOccupant != null;
    
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
          isEditing ? 'Edit Occupant' : 'Add ${widget.isPrimaryTenant ? 'Primary ' : ''}Occupant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
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
          color: AppTheme.getSurfaceColor(context),
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
                        _currentStep < 2 ? 'Next' : (isEditing ? 'Update' : 'Add Occupant'),
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
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 1 of 3 • Room ${widget.roomNumber}',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: AppTheme.getTextSecondaryColor(context),
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
                    backgroundColor: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(
                            Icons.person,
                            size: isMobile ? 60 : 80,
                            color: AppTheme.getTextSecondaryColor(context),
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
              hintText: 'Enter full name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter name';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Room Number (read-only)
          TextFormField(
            initialValue: widget.roomNumber,
            decoration: InputDecoration(
              labelText: 'Room Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.room),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            readOnly: true,
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Tenant Type
          if (widget.isPrimaryTenant) ...[
            Text(
              'Tenant Type *',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextSecondaryColor(context),
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
          ],
          
          // Monthly Rent (read-only for primary tenant)
          if (widget.isPrimaryTenant) ...[
            TextFormField(
              initialValue: '₹${widget.monthlyRent.toStringAsFixed(0)}',
              decoration: InputDecoration(
                labelText: 'Monthly Rent',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.currency_rupee),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              readOnly: true,
            ),
            SizedBox(height: isMobile ? 16 : 20),
          ],
          
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
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Active Status
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active Status'),
            subtitle: const Text('Currently living in the room'),
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
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
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 2 of 3',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: AppTheme.getTextSecondaryColor(context),
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
          
          SizedBox(height: isMobile ? 24 : 32),
          
          // Emergency Contact Section
          Text(
            'Emergency Contact',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimaryColor(context),
            ),
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
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 3 of 3',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: AppTheme.getTextSecondaryColor(context),
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
                color: AppTheme.getTextSecondaryColor(context),
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
                          decoration: const BoxDecoration(
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