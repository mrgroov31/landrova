import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/invitation_service.dart';
import '../services/api_service.dart';
import '../models/room.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class InviteTenantScreen extends StatefulWidget {
  const InviteTenantScreen({super.key});

  @override
  State<InviteTenantScreen> createState() => _InviteTenantScreenState();
}

class _InviteTenantScreenState extends State<InviteTenantScreen> {
  String? _selectedRoomNumber;
  String? _tenantName;
  String? _generatedLink;
  String? _invitationToken;
  List<Room> _rooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final response = await ApiService.fetchRooms();
      final rooms = ApiService.parseRooms(response);
      setState(() {
        _rooms = rooms.where((room) => room.status == 'vacant').toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  void _generateInvitationLink() {
    if (_selectedRoomNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a room'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = InvitationService.generateInvitationToken();
    final link = InvitationService.generateInvitationLink(
      token,
      roomNumber: _selectedRoomNumber,
    );

    setState(() {
      _invitationToken = token;
      _generatedLink = link;
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
            
            // Room Selection
            DropdownButtonFormField<String>(
              value: _selectedRoomNumber,
              decoration: InputDecoration(
                labelText: 'Select Room *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.room),
              ),
              items: _rooms.map((room) {
                return DropdownMenuItem<String>(
                  value: room.number,
                  child: Text('Room ${room.number} - ₹${room.rent.toStringAsFixed(0)}/month'),
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
            ),
            
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

