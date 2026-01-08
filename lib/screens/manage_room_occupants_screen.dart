import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class ManageRoomOccupantsScreen extends StatefulWidget {
  final Room room;
  final Function(Room)? onRoomUpdated;

  const ManageRoomOccupantsScreen({
    super.key,
    required this.room,
    this.onRoomUpdated,
  });

  @override
  State<ManageRoomOccupantsScreen> createState() => _ManageRoomOccupantsScreenState();
}

class _ManageRoomOccupantsScreenState extends State<ManageRoomOccupantsScreen> {
  List<RoomOccupant> occupants = [];
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOccupants();
  }

  Future<void> _loadOccupants() async {
    setState(() {
      isLoading = true;
    });

    try {
      // If room has a tenant, add them as the first occupant
      if (widget.room.tenant != null) {
        occupants.add(RoomOccupant(
          id: widget.room.tenant!.id,
          name: widget.room.tenant!.name,
          email: widget.room.tenant!.email,
          phone: widget.room.tenant!.phone,
          moveInDate: widget.room.tenant!.moveInDate,
          isPrimaryTenant: true,
          isActive: widget.room.tenant!.isActive,
        ));
      }

      // Load additional occupants from API if available
      // TODO: Implement API call to get room occupants
      // For now, we'll work with the current tenant data

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading occupants: $e')),
        );
      }
    }
  }

  Future<void> _addOccupant() async {
    final result = await showDialog<RoomOccupant>(
      context: context,
      builder: (context) => AddOccupantDialog(
        roomCapacity: widget.room.capacity,
        currentOccupancy: occupants.length,
      ),
    );

    if (result != null) {
      setState(() {
        occupants.add(result);
      });
      await _saveOccupants();
    }
  }

  Future<void> _editOccupant(int index) async {
    final result = await showDialog<RoomOccupant>(
      context: context,
      builder: (context) => AddOccupantDialog(
        occupant: occupants[index],
        roomCapacity: widget.room.capacity,
        currentOccupancy: occupants.length,
      ),
    );

    if (result != null) {
      setState(() {
        occupants[index] = result;
      });
      await _saveOccupants();
    }
  }

  Future<void> _removeOccupant(int index) async {
    final occupant = occupants[index];
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Occupant'),
        content: Text(
          occupant.isPrimaryTenant
              ? 'Are you sure you want to remove ${occupant.name}? This will mark the room as vacant.'
              : 'Are you sure you want to remove ${occupant.name} from this room?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        occupants.removeAt(index);
      });
      await _saveOccupants();
    }
  }

  Future<void> _saveOccupants() async {
    setState(() {
      isSaving = true;
    });

    try {
      // TODO: Implement API call to save occupants
      // For now, we'll simulate the save operation
      await Future.delayed(const Duration(milliseconds: 500));

      // Update the room object with new occupancy data
      final updatedRoom = Room(
        id: widget.room.id,
        buildingId: widget.room.buildingId,
        number: widget.room.number,
        type: widget.room.type,
        status: occupants.isEmpty ? 'vacant' : 'occupied',
        tenantId: occupants.isNotEmpty ? occupants.first.id : null,
        rent: widget.room.rent,
        capacity: widget.room.capacity,
        currentOccupancy: occupants.length,
        amenities: widget.room.amenities,
        images: widget.room.images,
        description: widget.room.description,
        floor: widget.room.floor,
        area: widget.room.area,
        isOccupied: occupants.isNotEmpty,
        tenant: occupants.isNotEmpty ? occupants.first.toRoomTenant() : null,
      );

      widget.onRoomUpdated?.call(updatedRoom);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Occupants updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving occupants: $e')),
        );
      }
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final availableSpots = widget.room.capacity - occupants.length;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Manage Occupants - Room ${widget.room.number}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Capacity Info Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCapacityInfo(
                            'Total Capacity',
                            widget.room.capacity.toString(),
                            Icons.people,
                            Colors.white,
                            isMobile,
                          ),
                          _buildCapacityInfo(
                            'Current Occupancy',
                            occupants.length.toString(),
                            Icons.person,
                            Colors.white,
                            isMobile,
                          ),
                          _buildCapacityInfo(
                            'Available Spots',
                            availableSpots.toString(),
                            Icons.person_add,
                            availableSpots > 0 ? Colors.green.shade300 : Colors.red.shade300,
                            isMobile,
                          ),
                        ],
                      ),
                      if (availableSpots > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            '$availableSpots spot${availableSpots > 1 ? 's' : ''} available',
                            style: TextStyle(
                              color: Colors.green.shade100,
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Occupants List
                Expanded(
                  child: occupants.isEmpty
                      ? _buildEmptyState(isMobile)
                      : ListView.builder(
                          padding: EdgeInsets.all(isMobile ? 16 : 20),
                          itemCount: occupants.length,
                          itemBuilder: (context, index) {
                            return _buildOccupantCard(occupants[index], index, isMobile);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: availableSpots > 0
          ? FloatingActionButton.extended(
              onPressed: isSaving ? null : _addOccupant,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: Text(isMobile ? 'Add' : 'Add Occupant'),
            )
          : null,
    );
  }

  Widget _buildCapacityInfo(String label, String value, IconData icon, Color color, bool isMobile) {
    return Column(
      children: [
        Icon(icon, color: color, size: isMobile ? 24 : 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: isMobile ? 12 : 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: isMobile ? 64 : 80,
            color: AppTheme.getTextSecondaryColor(context),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Text(
            'No Occupants',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            'This room is currently vacant.\nAdd occupants to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          ElevatedButton.icon(
            onPressed: _addOccupant,
            icon: const Icon(Icons.person_add),
            label: const Text('Add First Occupant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupantCard(RoomOccupant occupant, int index, bool isMobile) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      color: AppTheme.getCardColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: isMobile ? 24 : 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    occupant.name.isNotEmpty ? occupant.name[0].toUpperCase() : 'T',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                
                // Name and badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              occupant.name,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimaryColor(context),
                              ),
                            ),
                          ),
                          if (occupant.isPrimaryTenant)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            occupant.isActive ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: occupant.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            occupant.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: occupant.isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editOccupant(index);
                        break;
                      case 'remove':
                        _removeOccupant(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Contact info
            if (occupant.email.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.email,
                    size: 16,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      occupant.email,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            if (occupant.phone.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    occupant.phone,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            if (occupant.moveInDate != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Moved in: ${dateFormat.format(occupant.moveInDate!)}',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RoomOccupant {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime? moveInDate;
  final bool isPrimaryTenant;
  final bool isActive;

  RoomOccupant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.moveInDate,
    this.isPrimaryTenant = false,
    this.isActive = true,
  });

  RoomTenant toRoomTenant() {
    return RoomTenant(
      id: id,
      name: name,
      email: email,
      phone: phone,
      moveInDate: moveInDate,
      isActive: isActive,
    );
  }
}

class AddOccupantDialog extends StatefulWidget {
  final RoomOccupant? occupant;
  final int roomCapacity;
  final int currentOccupancy;

  const AddOccupantDialog({
    super.key,
    this.occupant,
    required this.roomCapacity,
    required this.currentOccupancy,
  });

  @override
  State<AddOccupantDialog> createState() => _AddOccupantDialogState();
}

class _AddOccupantDialogState extends State<AddOccupantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _moveInDate;
  bool _isPrimaryTenant = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.occupant != null) {
      _nameController.text = widget.occupant!.name;
      _emailController.text = widget.occupant!.email;
      _phoneController.text = widget.occupant!.phone;
      _moveInDate = widget.occupant!.moveInDate;
      _isPrimaryTenant = widget.occupant!.isPrimaryTenant;
      _isActive = widget.occupant!.isActive;
    } else {
      _moveInDate = DateTime.now();
      _isPrimaryTenant = widget.currentOccupancy == 0; // First occupant is primary
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.occupant != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Occupant' : 'Add Occupant'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Move-in Date'),
                subtitle: Text(
                  _moveInDate != null
                      ? DateFormat('MMM dd, yyyy').format(_moveInDate!)
                      : 'Select date',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _moveInDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _moveInDate = date;
                    });
                  }
                },
              ),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Primary Tenant'),
                subtitle: const Text('Main contact for this room'),
                value: _isPrimaryTenant,
                onChanged: (value) {
                  setState(() {
                    _isPrimaryTenant = value;
                  });
                },
              ),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final occupant = RoomOccupant(
                id: widget.occupant?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                phone: _phoneController.text.trim(),
                moveInDate: _moveInDate,
                isPrimaryTenant: _isPrimaryTenant,
                isActive: _isActive,
              );
              Navigator.of(context).pop(occupant);
            }
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}