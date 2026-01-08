import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/room.dart';
import '../models/building.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import 'rooms_screen.dart';
import 'buildings_screen.dart';

class AddRoomScreen extends StatefulWidget {
  final String? buildingId; // Optional: if provided, pre-select this building

  const AddRoomScreen({super.key, this.buildingId});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _rentController = TextEditingController();
  final _capacityController = TextEditingController();
  final _floorController = TextEditingController();
  final _areaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amenityController = TextEditingController();

  String? _selectedBuildingId;
  String _roomType = 'rented'; // pg, rented, leased
  String _status = 'vacant'; // vacant, occupied, maintenance
  bool _isLoading = false;
  final List<File> _roomImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _amenities = [];
  List<Building> _buildings = [];

  @override
  void initState() {
    super.initState();
    _selectedBuildingId = widget.buildingId;
    _loadBuildings();
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _rentController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _descriptionController.dispose();
    _amenityController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    try {
      final ownerId = AuthService.getOwnerId();
      final response = await ApiService.fetchBuildingsByOwnerId(ownerId);
      final buildings = ApiService.parseBuildings(response);
      
      setState(() {
        _buildings = buildings;
        // If buildingId was provided and not found in list, still keep it
        if (_selectedBuildingId != null && 
            !buildings.any((b) => b.id == _selectedBuildingId)) {
          // Building might not be in the list yet, that's okay
        }
      });
    } catch (e) {
      debugPrint('Error loading buildings: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _roomImages.addAll(images.map((xFile) => File(xFile.path)).toList());
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _roomImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _roomImages.removeAt(index);
    });
  }

  void _addAmenity() {
    final amenity = _amenityController.text.trim();
    if (amenity.isNotEmpty && !_amenities.contains(amenity)) {
      setState(() {
        _amenities.add(amenity);
        _amenityController.clear();
      });
    }
  }

  void _removeAmenity(String amenity) {
    setState(() {
      _amenities.remove(amenity);
    });
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBuildingId == null || _selectedBuildingId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a building'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare room data for API
      final roomNumber = _roomNumberController.text.trim();
      final rent = double.tryParse(_rentController.text) ?? 0.0;
      final capacity = int.tryParse(_capacityController.text) ?? 1;
      final floor = int.tryParse(_floorController.text);
      final area = _areaController.text.trim().isEmpty ? null : _areaController.text.trim();
      final description = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();

      // Generate image URLs from local files
      // For now, use placeholder URLs based on room number
      // In production, you would upload images first and get URLs
      final List<String> imageUrls = [];
      if (_roomImages.isNotEmpty) {
        // Generate placeholder URLs based on room number and index
        final roomHash = roomNumber.hashCode;
        for (int i = 0; i < _roomImages.length; i++) {
          final imageId = (roomHash.abs() % 1000) + i + 1;
          imageUrls.add('https://picsum.photos/seed/room$roomNumber-$imageId/800/600');
        }
      } else {
        // At least one placeholder image
        final roomHash = roomNumber.hashCode;
        final imageId = (roomHash.abs() % 1000) + 1;
        imageUrls.add('https://picsum.photos/seed/room$roomNumber-$imageId/800/600');
      }

      // Prepare room payload
      final roomPayload = {
        'number': roomNumber,
        'type': _roomType,
        'status': _status,
        'rent': rent,
        'capacity': capacity,
        if (floor != null) 'floor': floor,
        if (area != null) 'area': area,
        if (description != null) 'description': description,
        'amenities': _amenities,
        'images': imageUrls,
      };

      // Call API to create room
      final response = await ApiService.createRoomsBulk(
        buildingId: _selectedBuildingId!,
        rooms: [roomPayload],
      );

      setState(() {
        _isLoading = false;
      });

      // Check if API call was successful
      if (response['success'] == true || response['data'] != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Room $roomNumber created successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );

          // Navigate back to rooms screen
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('API returned unsuccessful response: ${response.toString()}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating room: ${e.toString()}'),
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

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.getSurfaceColor(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getTextPrimaryColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title:  Text(
          'Add Room',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Building Selection
              _buildSectionTitle('Building', isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedBuildingId,
                decoration: InputDecoration(
                  labelText: 'Select Building',
                  hintText: 'Choose a building',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
                items: _buildings.map((building) {
                  return DropdownMenuItem<String>(
                    value: building.id,
                    child: Text(building.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBuildingId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a building';
                  }
                  return null;
                },
              ),

              SizedBox(height: isMobile ? 24 : 32),

              // Room Number
              _buildSectionTitle('Room Details', isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              TextFormField(
                controller: _roomNumberController,
                decoration: InputDecoration(
                  labelText: 'Room Number',
                  hintText: 'e.g., 101, A-12',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter room number';
                  }
                  return null;
                },
              ),

              SizedBox(height: isMobile ? 16 : 20),

              // Room Type
              _buildSectionTitle('Room Type', isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              _buildRoomTypeSelector(isMobile),

              SizedBox(height: isMobile ? 24 : 32),

              // Rent
              TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Rent (₹)',
                  hintText: 'Enter monthly rent',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter rent amount';
                  }
                  final rent = double.tryParse(value);
                  if (rent == null || rent <= 0) {
                    return 'Please enter a valid rent amount';
                  }
                  return null;
                },
              ),

              SizedBox(height: isMobile ? 16 : 20),

              // Capacity
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Number of people',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.people),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter capacity';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Please enter a valid capacity';
                  }
                  return null;
                },
              ),

              SizedBox(height: isMobile ? 16 : 20),

              // Floor
              TextFormField(
                controller: _floorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Floor (Optional)',
                  hintText: 'Floor number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.layers),
                ),
              ),

              SizedBox(height: isMobile ? 16 : 20),

              // Area
              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: 'Area (Optional)',
                  hintText: 'e.g., 200 sq ft',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.square_foot),
                ),
              ),

              SizedBox(height: isMobile ? 24 : 32),

              // Status
              _buildSectionTitle('Status', isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              _buildStatusSelector(isMobile),

              SizedBox(height: isMobile ? 24 : 32),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Any additional details about the room...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),

              SizedBox(height: isMobile ? 24 : 32),

              // Amenities
              _buildSectionTitle('Amenities', isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amenityController,
                      decoration: InputDecoration(
                        labelText: 'Add Amenity',
                        hintText: 'e.g., WiFi, AC, TV',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.add_circle_outline),
                      ),
                      onFieldSubmitted: (_) => _addAmenity(),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addAmenity,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
              if (_amenities.isNotEmpty) ...[
                SizedBox(height: isMobile ? 12 : 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenities.map((amenity) {
                    return Chip(
                      label: Text(amenity),
                      onDeleted: () => _removeAmenity(amenity),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
              ],

              SizedBox(height: isMobile ? 24 : 32),

              // Room Images
              _buildSectionTitle('Room Images', isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              _buildImageSection(isMobile),

              SizedBox(height: isMobile ? 32 : 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRoom,
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
                          'Create Room',
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
        color: AppTheme.getTextPrimaryColor(context),
      ),
    );
  }

  Widget _buildRoomTypeSelector(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildRoomTypeOption('Paying Guest (PG)', 'pg', Icons.hotel, Colors.blue, isMobile),
          Divider(height: 1, color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2)),
          _buildRoomTypeOption('Rented', 'rented', Icons.home, Colors.green, isMobile),
          Divider(height: 1, color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2)),
          _buildRoomTypeOption('Leased', 'leased', Icons.business, Colors.purple, isMobile),
        ],
      ),
    );
  }

  Widget _buildRoomTypeOption(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    final isSelected = _roomType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _roomType = value;
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppTheme.getTextPrimaryColor(context),
                ),
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

  Widget _buildStatusSelector(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusChip('Vacant', 'vacant', Colors.green, isMobile),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: _buildStatusChip('Occupied', 'occupied', Colors.orange, isMobile),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: _buildStatusChip('Maintenance', 'maintenance', Colors.red, isMobile),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String value, Color color, bool isMobile) {
    final isSelected = _status == value;
    return InkWell(
      onTap: () {
        setState(() {
          _status = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 12 : 16,
          horizontal: isMobile ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.getTextSecondaryColor(context).withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.getTextSecondaryColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('From Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12 : 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12 : 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_roomImages.isNotEmpty) ...[
          SizedBox(height: isMobile ? 16 : 20),
          SizedBox(
            height: isMobile ? 120 : 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _roomImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: isMobile ? 8 : 12),
                  width: isMobile ? 120 : 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.getTextSecondaryColor(context).withOpacity(0.3)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _roomImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => _removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

