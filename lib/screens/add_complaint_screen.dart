import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/complaint.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../services/complaint_service.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';

class AddComplaintScreen extends StatefulWidget {
  const AddComplaintScreen({super.key});

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  
  String? _selectedRoomNumber;
  String? _selectedTenantId;
  String? _selectedTenantName;
  String _priority = 'medium';
  String? _category;
  
  bool _isLoading = false;
  List<Room> _rooms = [];
  List<Tenant> _tenants = [];
  bool _loadingRooms = true;

  @override
  void initState() {
    super.initState();
    _loadRoomsAndTenants();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomsAndTenants() async {
    try {
      final roomsResponse = await ApiService.fetchRooms();
      final tenantsResponse = await ApiService.fetchTenants();
      
      final rooms = ApiService.parseRooms(roomsResponse);
      final tenants = ApiService.parseTenants(tenantsResponse);
      
      setState(() {
        _rooms = rooms;
        _tenants = tenants;
        _loadingRooms = false;
      });
    } catch (e) {
      setState(() {
        _loadingRooms = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((xFile) => File(xFile.path)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoomNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a room'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTenantId == null || _selectedTenantName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active tenant found for the selected room'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final complaintId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // For now, we'll store image paths as empty (can be enhanced later)
      final complaint = Complaint(
        id: complaintId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        roomNumber: _selectedRoomNumber!,
        tenantId: _selectedTenantId!,
        tenantName: _selectedTenantName ?? 'Unknown',
        status: 'pending',
        createdAt: now,
        updatedAt: now,
        priority: _priority,
        category: _category,
        images: [], // Can be enhanced to store image paths
      );

      await ComplaintService.addComplaint(complaint);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting complaint: $e'),
            backgroundColor: Colors.red,
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
          'New Complaint',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
      ),
      body: _loadingRooms
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Selection
                    _buildSectionTitle('Room *', isMobile),
                    const SizedBox(height: 12),
                    _buildRoomSelector(isMobile),
                    
                    SizedBox(height: isMobile ? 24 : 28),
                    
                    // Tenant Selection (auto-filled based on room)
                    if (_selectedRoomNumber != null) ...[
                      _buildSectionTitle('Tenant', isMobile),
                      const SizedBox(height: 12),
                      _buildTenantDisplay(isMobile),
                      SizedBox(height: isMobile ? 24 : 28),
                    ],
                    
                    // Complaint Details
                    _buildSectionTitle('Complaint Details', isMobile),
                    const SizedBox(height: 12),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g., Water Leakage, AC Not Working',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a complaint title';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: isMobile ? 16 : 20),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe the issue in detail...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: isMobile ? 24 : 28),
                    
                    // Priority Selection
                    _buildSectionTitle('Priority *', isMobile),
                    const SizedBox(height: 12),
                    _buildPrioritySelector(isMobile),
                    
                    SizedBox(height: isMobile ? 24 : 28),
                    
                    // Category Selection (Optional)
                    _buildSectionTitle('Category (Optional)', isMobile),
                    const SizedBox(height: 12),
                    _buildCategorySelector(isMobile),
                    
                    SizedBox(height: isMobile ? 24 : 28),
                    
                    // Images Section
                    _buildSectionTitle('Attach Images (Optional)', isMobile),
                    const SizedBox(height: 12),
                    _buildImageSection(isMobile),
                    
                    SizedBox(height: isMobile ? 32 : 40),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitComplaint,
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
                                'Submit Complaint',
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

  Widget _buildRoomSelector(bool isMobile) {
    // Get occupied rooms
    final occupiedRooms = _rooms.where((room) => room.status == 'occupied').toList();
    
    if (occupiedRooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No occupied rooms available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedRoomNumber,
      decoration: InputDecoration(
        labelText: 'Select Room *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.room),
      ),
      items: occupiedRooms.map((room) {
        return DropdownMenuItem<String>(
          value: room.number,
          child: Text('Room ${room.number}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRoomNumber = value;
          // Auto-select tenant for this room
          try {
            final tenant = _tenants.firstWhere(
              (t) => t.roomNumber == value && t.isActive,
              orElse: () => _tenants.firstWhere(
                (t) => t.roomNumber == value,
              ),
            );
            _selectedTenantId = tenant.id;
            _selectedTenantName = tenant.name;
          } catch (e) {
            // No tenant found for this room
            _selectedTenantId = null;
            _selectedTenantName = null;
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a room';
        }
        return null;
      },
    );
  }

  Widget _buildTenantDisplay(bool isMobile) {
    if (_selectedTenantName == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tenant: $_selectedTenantName',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector(bool isMobile) {
    final priorities = [
      {'value': 'low', 'label': 'Low', 'color': Colors.green, 'icon': Icons.arrow_downward},
      {'value': 'medium', 'label': 'Medium', 'color': Colors.orange, 'icon': Icons.remove},
      {'value': 'high', 'label': 'High', 'color': Colors.red, 'icon': Icons.arrow_upward},
      {'value': 'urgent', 'label': 'Urgent', 'color': Colors.purple, 'icon': Icons.priority_high},
    ];

    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      children: priorities.map((priority) {
        final isSelected = _priority == priority['value'];
        final color = priority['color'] as Color;
        return InkWell(
          onTap: () {
            setState(() {
              _priority = priority['value'] as String;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? color.withOpacity(0.2) 
                  : Colors.grey.shade100,
              border: Border.all(
                color: isSelected 
                    ? color 
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  priority['icon'] as IconData,
                  size: isMobile ? 20 : 24,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  priority['label'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? color : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector(bool isMobile) {
    final categories = [
      {'value': 'plumbing', 'label': 'Plumbing', 'icon': Icons.plumbing},
      {'value': 'electrical', 'label': 'Electrical', 'icon': Icons.electrical_services},
      {'value': 'maintenance', 'label': 'Maintenance', 'icon': Icons.build},
      {'value': 'cleaning', 'label': 'Cleaning', 'icon': Icons.cleaning_services},
      {'value': 'security', 'label': 'Security', 'icon': Icons.security},
      {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
    ];

    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      children: [
        // None option
        InkWell(
          onTap: () {
            setState(() {
              _category = null;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: _category == null 
                  ? Colors.grey.shade200 
                  : Colors.grey.shade100,
              border: Border.all(
                color: _category == null 
                    ? Colors.grey.shade600 
                    : Colors.grey.shade300,
                width: _category == null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'None',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: _category == null ? FontWeight.w600 : FontWeight.normal,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
        ...categories.map((category) {
          final isSelected = _category == category['value'];
          return InkWell(
            onTap: () {
              setState(() {
                _category = category['value'] as String;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor.withOpacity(0.2) 
                    : Colors.grey.shade100,
                border: Border.all(
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: isMobile ? 20 : 24,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Text(
                    category['label'] as String,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
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
                label: const Text('Choose from Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onPressed: () => _removeImage(index),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

