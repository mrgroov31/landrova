import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/invitation_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/room.dart';
import '../models/building.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class InviteTenantScreen extends StatefulWidget {
  final String? selectedBuildingId;
  
  const InviteTenantScreen({super.key, this.selectedBuildingId});

  @override
  State<InviteTenantScreen> createState() => _InviteTenantScreenState();
}

class _InviteTenantScreenState extends State<InviteTenantScreen> {
  String? _selectedBuildingId;
  String? _selectedRoomNumber;
  String? _tenantName;
  String? _generatedLink;
  String? _invitationToken;
  List<Room> _rooms = [];
  List<Building> _buildings = [];
  bool _isLoading = false;
  bool _isLoadingBuildings = false;
  bool _isLoadingRooms = false;

  @override
  void initState() {
    super.initState();
    _selectedBuildingId = widget.selectedBuildingId;
    _loadBuildings();
    if (_selectedBuildingId != null) {
      _loadRooms();
    }
  }

  Future<void> _loadBuildings() async {
    setState(() {
      _isLoadingBuildings = true;
    });
    
    try {
      final ownerId = AuthService.getOwnerId();
      final response = await ApiService.fetchBuildingsByOwnerId(ownerId);
      final buildings = ApiService.parseBuildings(response);
      
      setState(() {
        _buildings = buildings;
        _isLoadingBuildings = false;
        
        // If buildingId was pre-selected and exists in list, keep it
        if (_selectedBuildingId != null && 
            buildings.any((b) => b.id == _selectedBuildingId)) {
          _loadRooms();
        } else if (buildings.length == 1) {
          // Auto-select if only one building
          _selectedBuildingId = buildings.first.id;
          _loadRooms();
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingBuildings = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading buildings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRooms() async {
    if (_selectedBuildingId == null) {
      setState(() {
        _rooms = [];
        _selectedRoomNumber = null;
        _generatedLink = null;
      });
      return;
    }

    setState(() {
      _isLoadingRooms = true;
    });

    try {
      // Use owner-specific room fetching
      final ownerId = AuthService.getOwnerId();
      final response = await ApiService.fetchRoomsByOwnerId(ownerId);
      var rooms = ApiService.parseRooms(response);
      
      // Filter by selected building and only show vacant rooms
      rooms = rooms.where((room) => 
        room.buildingId == _selectedBuildingId && 
        room.status == 'vacant'
      ).toList();
      
      // Sort rooms by room number for better UX
      rooms.sort((a, b) => a.number.compareTo(b.number));
      
      setState(() {
        _rooms = rooms;
        _selectedRoomNumber = null; // Reset room selection when building changes
        _generatedLink = null; // Reset link when building changes
        _isLoadingRooms = false;
      });
    } catch (e) {
      setState(() {
        _rooms = [];
        _selectedRoomNumber = null;
        _generatedLink = null;
        _isLoadingRooms = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rooms: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateInvitationLink() {
    if (_selectedBuildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a building'),
          backgroundColor: Colors.red,
        ),
      );
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

    // Find the selected room to get its ID
    final selectedRoom = _rooms.firstWhere(
      (room) => room.number == _selectedRoomNumber,
      orElse: () => throw Exception('Selected room not found'),
    );

    final token = InvitationService.generateInvitationToken();
    final link = InvitationService.generateInvitationLink(
      token,
      roomId: selectedRoom.id, // Pass room ID directly
      roomNumber: _selectedRoomNumber, // Keep for backward compatibility
      buildingId: _selectedBuildingId, // Keep for backward compatibility
    );

    setState(() {
      _invitationToken = token;
      _generatedLink = link;
      debugPrint('🔗 [INVITE] Generated link with room ID: ${selectedRoom.id}');
      debugPrint('🔗 [INVITE] Room number: $_selectedRoomNumber');
      debugPrint('🔗 [INVITE] Building ID: $_selectedBuildingId');
    });
  }

  Future<void> _shareLink() async {
    if (_generatedLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a link first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await InvitationService.shareInvitationLink(
      _generatedLink!,
      _tenantName ?? 'Tenant',
    );
  }

  void _copyLink() {
    if (_generatedLink == null) return;
    
    Clipboard.setData(ClipboardData(text: _generatedLink!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
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
          'Invite Tenant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Generate an invitation link and share it with the tenant. They can use it to register in the app.',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isMobile ? 24 : 32),
            
            // Tenant Name (Optional)
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Tenant Name (Optional)',
                hintText: 'Enter tenant name for reference',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              onChanged: (value) {
                setState(() {
                  _tenantName = value;
                });
              },
            ),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            // Building Selection
            _isLoadingBuildings
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedBuildingId,
                    decoration: InputDecoration(
                      labelText: 'Select Building *',
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
                        _selectedRoomNumber = null; // Reset room selection
                        _generatedLink = null; // Reset link
                      });
                      _loadRooms();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a building';
                      }
                      return null;
                    },
                  ),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            // Room Selection (only shown if building is selected)
            if (_selectedBuildingId != null) ...[
              _isLoadingRooms
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading available rooms...'),
                        ],
                      ),
                    )
                  : _rooms.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No vacant rooms available in this building.',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: isMobile ? 13 : 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedRoomNumber,
                              decoration: InputDecoration(
                                labelText: 'Select Room *',
                                hintText: 'Choose an available room',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.room),
                              ),
                              items: _rooms.map((room) {
                                return DropdownMenuItem<String>(
                                  value: room.number,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                       
                                        Row(
                                          children: [
                                             Text(
                                          'Room ${room.number}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2,width: 10,),
                                            Icon(
                                              Icons.currency_rupee,
                                              size: 14,
                                              color: Colors.green.shade600,
                                            ),
                                            Text(
                                              '${room.rent.toStringAsFixed(0)}/month',
                                              style: TextStyle(
                                                color: Colors.green.shade600,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                           const SizedBox(width: 40,),
                                            if (room.type.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  room.type.toUpperCase(),
                                                  style: TextStyle(
                                                    color: AppTheme.primaryColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRoomNumber = value;
                                  _generatedLink = null; // Reset link when room changes
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a room';
                                }
                                return null;
                              },
                              isExpanded: true,
                              menuMaxHeight: 300,
                            ),
                            
                            // Show selected room details
                            if (_selectedRoomNumber != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: () {
                                  final selectedRoom = _rooms.firstWhere(
                                    (room) => room.number == _selectedRoomNumber,
                                  );
                                  return Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue.shade700,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Selected: Room ${selectedRoom.number} - ₹${selectedRoom.rent.toStringAsFixed(0)}/month',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }(),
                              ),
                            ],
                          ],
                        ),
              SizedBox(height: isMobile ? 16 : 20),
            ],
            
            SizedBox(height: isMobile ? 32 : 40),
            
            // Generate Link Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _generateInvitationLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Generate Invitation Link',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Generated Link Section
            if (_generatedLink != null) ...[
              SizedBox(height: isMobile ? 32 : 40),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Link Generated Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        _generatedLink!,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyLink,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Link'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareLink,
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

