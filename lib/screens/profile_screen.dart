import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import '../models/building.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'unified_login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isLoadingData = true;
  List<Building> _buildings = [];
  Building? _currentBuilding;
  String? _ownerImagePath; // Store the path to owner image from building

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      // Load buildings to get owner information
      // Similar to how buildings_screen loads buildings
      final mockBuildings = [
        Building(
          id: '1',
          name: 'Sunshine Apartments',
          address: '123 Main Street',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560001',
          totalFloors: 3,
          totalRooms: 6,
          buildingType: 'standalone',
          propertyType: 'rented',
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
        ),
        Building(
          id: '2',
          name: 'Green Valley PG',
          address: '456 Park Avenue',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560002',
          totalFloors: 2,
          totalRooms: 8,
          buildingType: 'standalone',
          propertyType: 'pg',
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
        ),
      ];

      // In production, this would come from API or shared state
      // For now, combine mock buildings with any custom buildings
      // (In a real app, you'd fetch from a service or state management)
      _buildings = mockBuildings;

      // Find the first building with owner information
      Building? buildingWithOwner;
      for (var building in _buildings) {
        if (building.owner != null) {
          buildingWithOwner = building;
          break;
        }
      }

      // Load owner data from building
      if (buildingWithOwner != null) {
        _loadOwnerFromBuilding(buildingWithOwner);
      } else {
        // No owner data found, set default values
        _nameController.text = 'Owner';
        _emailController.text = 'owner@example.com';
        _phoneController.text = '+91 9876543210';
      }

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        // Set defaults on error
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Owner';
        }
        if (_emailController.text.isEmpty) {
          _emailController.text = 'owner@example.com';
        }
        if (_phoneController.text.isEmpty) {
          _phoneController.text = '+91 9876543210';
        }
      });
    }
  }

  void _loadOwnerFromBuilding(Building building) {
    if (building.owner != null) {
      setState(() {
        _nameController.text = building.owner!.name;
        _emailController.text = building.owner!.email;
        _phoneController.text = building.owner!.phone;
        _ownerImagePath = building.owner!.image;
        if (_ownerImagePath != null && _ownerImagePath!.isNotEmpty) {
          try {
            final imageFile = File(_ownerImagePath!);
            if (imageFile.existsSync()) {
              _profileImage = imageFile;
            } else {
              _profileImage = null;
            }
          } catch (e) {
            _profileImage = null;
          }
        } else {
          _profileImage = null;
        }
        _currentBuilding = building;
      });
    }
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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Update owner image path if a new image was selected
    if (_profileImage != null) {
      _ownerImagePath = _profileImage!.path;
    }

    // Create or update owner information
    final updatedOwner = BuildingOwner(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      image: _ownerImagePath,
    );

    // Update the current building's owner if it exists
    if (_currentBuilding != null) {
      // In production, you would update the building via API
      // For now, we'll just update the local reference
      _currentBuilding = Building(
        id: _currentBuilding!.id,
        name: _currentBuilding!.name,
        address: _currentBuilding!.address,
        city: _currentBuilding!.city,
        state: _currentBuilding!.state,
        pincode: _currentBuilding!.pincode,
        totalFloors: _currentBuilding!.totalFloors,
        totalRooms: _currentBuilding!.totalRooms,
        buildingType: _currentBuilding!.buildingType,
        propertyType: _currentBuilding!.propertyType,
        image: _currentBuilding!.image,
        description: _currentBuilding!.description,
        createdAt: _currentBuilding!.createdAt,
        isActive: _currentBuilding!.isActive,
        owner: updatedOwner,
        facilities: _currentBuilding!.facilities,
      );
    }

    // Simulate API call - in production, update owner in building via API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _isEditing = false; // Exit edit mode after saving
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  // Reset to saved values when canceling edit
                  if (_currentBuilding?.owner != null) {
                    _nameController.text = _currentBuilding!.owner!.name;
                    _emailController.text = _currentBuilding!.owner!.email;
                    _phoneController.text = _currentBuilding!.owner!.phone;
                    _ownerImagePath = _currentBuilding!.owner!.image;
                    if (_ownerImagePath != null && File(_ownerImagePath!).existsSync()) {
                      _profileImage = File(_ownerImagePath!);
                    } else {
                      _profileImage = null;
                    }
                  } else {
                    // Reset to defaults if no building owner
                    _nameController.text = 'Owner';
                    _emailController.text = 'owner@example.com';
                    _phoneController.text = '+91 9876543210';
                    _profileImage = null;
                  }
                }
              });
            },
            tooltip: _isEditing ? 'Cancel' : 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                children: [
                  // Profile Image Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: isMobile ? 120 : 140,
                          height: isMobile ? 120 : 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _profileImage == null
                                ? Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.person,
                                      size: isMobile ? 60 : 70,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : Image.file(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: isMobile ? 36 : 40,
                        height: isMobile ? 36 : 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: _showImageSourceDialog,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: isMobile ? 32 : 40),
            
            // Profile Information
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
                filled: !_isEditing,
                fillColor: !_isEditing ? Colors.grey.shade100 : null,
              ),
            ),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            TextFormField(
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email),
                filled: !_isEditing,
                fillColor: !_isEditing ? Colors.grey.shade100 : null,
              ),
            ),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            TextFormField(
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
                filled: !_isEditing,
                fillColor: !_isEditing ? Colors.grey.shade100 : null,
              ),
            ),
            
            if (_isEditing) ...[
              SizedBox(height: isMobile ? 32 : 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
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
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
            
            // Logout Button
            SizedBox(height: isMobile ? 32 : 40),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
          ],
        ),
      ),
    );
  }
}

