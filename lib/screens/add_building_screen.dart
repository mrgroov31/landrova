import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/building.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'buildings_screen.dart';

class AddBuildingScreen extends StatefulWidget {
  const AddBuildingScreen({super.key});

  @override
  State<AddBuildingScreen> createState() => _AddBuildingScreenState();
}

class _AddBuildingScreenState extends State<AddBuildingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _totalRoomsController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _buildingType = 'standalone'; // standalone, apartment, complex
  String _propertyType = 'rented'; // pg, rented, leased
  bool _isLoading = false;
  File? _buildingImage;
  File? _ownerImage;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Owner details controllers
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  
  // Facilities
  final List<BuildingFacility> _facilities = [];
  final TextEditingController _facilityNameController = TextEditingController();
  bool _facilityIsPaid = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _totalFloorsController.dispose();
    _totalRoomsController.dispose();
    _descriptionController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _facilityNameController.dispose();
    super.dispose();
  }

  Future<void> _saveBuilding() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current owner ID from centralized location
      final currentUser = AuthService.currentUser;
      if (currentUser == null || !currentUser.isOwner) {
        throw Exception('User not logged in as owner');
      }

      final ownerId = AuthService.getOwnerId();

      // Prepare amenities list from facilities
      final amenities = _facilities.map((facility) => facility.name).toList();

      // Prepare facilities list for API
      final facilities = _facilities.map((facility) => {
        'name': facility.name,
        'isPaid': facility.isPaid,
      }).toList();

      // Prepare building data for API
      final buildingData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'pincode': _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        'totalFloors': int.tryParse(_totalFloorsController.text) ?? 1,
        'totalRooms': int.tryParse(_totalRoomsController.text) ?? 1,
        'buildingType': _buildingType,
        'propertyType': _propertyType,
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'amenities': amenities,
        'facilities': facilities,
      };

      // Remove null values from building data
      buildingData.removeWhere((key, value) => value == null);

      // Call API to create building
      final response = await ApiService.createBuildingsBulk(
        ownerId: ownerId,
        buildings: [buildingData],
      );

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text.trim()} created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Create building object for local use (if needed)
        BuildingOwner? owner;
        if (_ownerNameController.text.trim().isNotEmpty ||
            _ownerEmailController.text.trim().isNotEmpty ||
            _ownerPhoneController.text.trim().isNotEmpty) {
          owner = BuildingOwner(
            name: _ownerNameController.text.trim(),
            email: _ownerEmailController.text.trim(),
            phone: _ownerPhoneController.text.trim(),
            image: _ownerImage?.path,
          );
        }

        final newBuilding = Building(
          id: response['data']?['buildings']?[0]?['id']?.toString() ?? 
               DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
          totalFloors: int.tryParse(_totalFloorsController.text) ?? 1,
          totalRooms: int.tryParse(_totalRoomsController.text) ?? 1,
          buildingType: _buildingType,
          propertyType: _propertyType,
          image: _buildingImage?.path,
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          createdAt: DateTime.now(),
          isActive: true,
          owner: owner,
          facilities: _facilities,
        );

        // Navigate back to buildings screen
        Navigator.pop(context, newBuilding);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating building: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
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
        title: const Text(
          'Add Building',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Building Image Upload
              _buildSectionTitle('Building Image (Optional)', isMobile),
              const SizedBox(height: 12),
              _buildImagePicker(isMobile),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              // Property Type Selection - Most Important
              _buildSectionTitle('Property Type *', isMobile),
              const SizedBox(height: 12),
              _buildPropertyTypeSelector(isMobile),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              // Building Details
              _buildSectionTitle('Building Details', isMobile),
              const SizedBox(height: 12),
              
              // Building Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Building Name *',
                  hintText: 'e.g., Sunshine Apartments',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter building name';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              // Building Type
              _buildSectionTitle('Building Type', isMobile),
              const SizedBox(height: 12),
              _buildBuildingTypeSelector(isMobile),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              // Address Section
              _buildSectionTitle('Address', isMobile),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Street Address *',
                  hintText: 'e.g., 123 Main Street',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        hintText: 'e.g., Bangalore',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        hintText: 'e.g., Karnataka',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.map),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              TextFormField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  hintText: 'e.g., 560001',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.pin),
                ),
              ),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              // Building Specifications
              _buildSectionTitle('Building Specifications', isMobile),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalFloorsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Floors *',
                        hintText: 'e.g., 3',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.layers),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final floors = int.tryParse(value);
                        if (floors == null || floors < 1) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: TextFormField(
                      controller: _totalRoomsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Rooms *',
                        hintText: 'e.g., 6',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.door_front_door),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final rooms = int.tryParse(value);
                        if (rooms == null || rooms < 1) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              // Owner Details Section
              _buildSectionTitle('Owner Details (Optional)', isMobile),
              const SizedBox(height: 12),
              
              // Owner Image
              _buildOwnerImagePicker(isMobile),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              TextFormField(
                controller: _ownerNameController,
                decoration: InputDecoration(
                  labelText: 'Owner Name',
                  hintText: 'e.g., John Doe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              TextFormField(
                controller: _ownerEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Owner Email',
                  hintText: 'e.g., owner@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              TextFormField(
                controller: _ownerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Owner Phone',
                  hintText: 'e.g., +91 9876543210',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              // Facilities Section
              _buildSectionTitle('Facilities (Optional)', isMobile),
              const SizedBox(height: 12),
              _buildFacilitiesSection(isMobile),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              // Description (Optional)
              _buildSectionTitle('Additional Information (Optional)', isMobile),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Any additional details about the building...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              
              SizedBox(height: isMobile ? 32 : 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBuilding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Building',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isMobile) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isMobile ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildPropertyTypeSelector(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPropertyTypeOption(
            'Paying Guest (PG)',
            'pg',
            Icons.hotel,
            Colors.blue,
            isMobile,
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          _buildPropertyTypeOption(
            'Rented',
            'rented',
            Icons.home,
            Colors.green,
            isMobile,
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          _buildPropertyTypeOption(
            'Leased',
            'leased',
            Icons.business,
            Colors.purple,
            isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeOption(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    final isSelected = _propertyType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _propertyType = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: isMobile ? 24 : 28,
              ),
            ),
            SizedBox(width: isMobile ? 16 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? color : Colors.grey.shade800,
                    ),
                  ),
                  if (value == 'pg')
                    Text(
                      'Multiple tenants per room',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.grey.shade600,
                      ),
                    )
                  else if (value == 'rented')
                    Text(
                      'Single tenant per room',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    Text(
                      'Long-term lease agreement',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingTypeSelector(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildBuildingTypeChip(
            'Standalone',
            'standalone',
            Icons.home,
            isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: _buildBuildingTypeChip(
            'Apartment',
            'apartment',
            Icons.apartment,
            isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: _buildBuildingTypeChip(
            'Complex',
            'complex',
            Icons.business,
            isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildBuildingTypeChip(
    String label,
    String value,
    IconData icon,
    bool isMobile,
  ) {
    final isSelected = _buildingType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _buildingType = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1) 
              : Colors.grey.shade100,
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor 
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppTheme.primaryColor 
                  : Colors.grey.shade600,
              size: isMobile ? 28 : 32,
            ),
            SizedBox(height: isMobile ? 8 : 10),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isMobile) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(),
      child: Container(
        height: isMobile ? 180 : 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _buildingImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: isMobile ? 48 : 56,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    'Tap to add building image',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gallery or Camera',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _buildingImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _buildingImage = null;
                          });
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w500,
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

  Future<void> _showImageSourceDialog() async {
    final result = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _pickImage(result);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _buildingImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error picking image';
        if (e.toString().contains('channel')) {
          errorMessage = 'Image picker not initialized. Please rebuild the app completely (flutter clean && flutter run)';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please grant camera/gallery access in app settings.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildOwnerImagePicker(bool isMobile) {
    return GestureDetector(
      onTap: () => _showOwnerImageSourceDialog(),
      child: Container(
        height: isMobile ? 100 : 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _ownerImage == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    size: isMobile ? 32 : 40,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Text(
                    'Tap to add owner photo',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _ownerImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _ownerImage = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showOwnerImageSourceDialog() async {
    final result = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _pickOwnerImage(result);
    }
  }

  Future<void> _pickOwnerImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _ownerImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error picking image';
        if (e.toString().contains('channel')) {
          errorMessage = 'Image picker not initialized. Please rebuild the app completely (flutter clean && flutter run)';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please grant camera/gallery access in app settings.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildFacilitiesSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Facility Input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _facilityNameController,
                decoration: InputDecoration(
                  labelText: 'Facility Name',
                  hintText: 'e.g., WiFi, Parking, Gym',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.room_service),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            // Paid/Free Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _facilityIsPaid ? Icons.attach_money : Icons.check_circle,
                    size: 18,
                    color: _facilityIsPaid ? Colors.orange : Colors.green,
                  ),
                  SizedBox(width: isMobile ? 4 : 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _facilityIsPaid = !_facilityIsPaid;
                      });
                    },
                    child: Text(
                      _facilityIsPaid ? 'Paid' : 'Free',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: _facilityIsPaid ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            // Add Button
            ElevatedButton(
              onPressed: () {
                if (_facilityNameController.text.trim().isNotEmpty) {
                  setState(() {
                    _facilities.add(BuildingFacility(
                      name: _facilityNameController.text.trim(),
                      isPaid: _facilityIsPaid,
                    ));
                    _facilityNameController.clear();
                    _facilityIsPaid = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
        
        // Facilities List
        if (_facilities.isNotEmpty) ...[
          SizedBox(height: isMobile ? 16 : 20),
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            children: _facilities.map((facility) {
              return Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      facility.isPaid ? Icons.attach_money : Icons.check_circle,
                      size: 16,
                      color: facility.isPaid ? Colors.orange : Colors.green,
                    ),
                    SizedBox(width: 4),
                    Text(facility.name),
                  ],
                ),
                backgroundColor: facility.isPaid 
                    ? Colors.orange.shade50 
                    : Colors.green.shade50,
                deleteIcon: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                onDeleted: () {
                  setState(() {
                    _facilities.remove(facility);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

