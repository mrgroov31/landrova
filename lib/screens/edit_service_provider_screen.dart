import 'package:flutter/material.dart';
import '../models/service_provider.dart';
import '../services/service_provider_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';

class EditServiceProviderScreen extends StatefulWidget {
  final ServiceProvider provider;

  const EditServiceProviderScreen({
    super.key,
    required this.provider,
  });

  @override
  State<EditServiceProviderScreen> createState() => _EditServiceProviderScreenState();
}

class _EditServiceProviderScreenState extends State<EditServiceProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  final TextEditingController _specialtyController = TextEditingController();
  
  late String _serviceType;
  bool _isLoading = false;
  late List<String> _specialties;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider.name);
    _phoneController = TextEditingController(text: widget.provider.phone);
    _emailController = TextEditingController(text: widget.provider.email ?? '');
    _addressController = TextEditingController(text: widget.provider.address ?? '');
    _serviceType = widget.provider.serviceType;
    _specialties = List<String>.from(widget.provider.specialties);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _updateProvider() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Update provider
    widget.provider.name = _nameController.text.trim();
    widget.provider.serviceType = _serviceType;
    widget.provider.phone = _phoneController.text.trim();
    widget.provider.email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    widget.provider.address = _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
    widget.provider.specialties = _specialties;

    // Save to Hive
    await ServiceProviderService.updateProvider(widget.provider);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.provider.name} updated successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, widget.provider);
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
          'Edit Service Provider',
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
              // Service Type Selection
              _buildSectionTitle('Service Type *', isMobile),
              const SizedBox(height: 12),
              _buildServiceTypeSelector(isMobile),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              // Provider Details
              _buildSectionTitle('Provider Details', isMobile),
              const SizedBox(height: 12),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Provider Name *',
                  hintText: 'e.g., Rajesh Electricals',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter provider name';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'e.g., +91 9876543210',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
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
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'e.g., provider@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              // Address
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address (Optional)',
                  hintText: 'e.g., Near Main Street, Bangalore',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              // Specialties Section
              _buildSectionTitle('Specialties (Optional)', isMobile),
              const SizedBox(height: 12),
              _buildSpecialtiesSection(isMobile),
              
              SizedBox(height: isMobile ? 32 : 40),
              
              // Update Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProvider,
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
                          'Update Provider',
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

  Widget _buildServiceTypeSelector(bool isMobile) {
    final serviceTypes = [
      {'value': 'electrician', 'label': 'Electrician', 'icon': Icons.electrical_services, 'color': Colors.amber},
      {'value': 'plumber', 'label': 'Plumber', 'icon': Icons.plumbing, 'color': Colors.blue},
      {'value': 'carpenter', 'label': 'Carpenter', 'icon': Icons.hardware, 'color': Colors.brown},
      {'value': 'painter', 'label': 'Painter', 'icon': Icons.format_paint, 'color': Colors.purple},
      {'value': 'ac_repair', 'label': 'AC Repair', 'icon': Icons.ac_unit, 'color': Colors.cyan},
      {'value': 'appliance_repair', 'label': 'Appliance Repair', 'icon': Icons.build, 'color': Colors.orange},
      {'value': 'cleaning', 'label': 'Cleaning Service', 'icon': Icons.cleaning_services, 'color': Colors.teal},
      {'value': 'handyman', 'label': 'Handyman', 'icon': Icons.handyman, 'color': Colors.grey},
    ];

    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      children: serviceTypes.map((type) {
        final isSelected = _serviceType == type['value'];
        final color = type['color'] as Color;
        return InkWell(
          onTap: () {
            setState(() {
              _serviceType = type['value'] as String;
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
                  type['icon'] as IconData,
                  size: isMobile ? 20 : 24,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  type['label'] as String,
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

  Widget _buildSpecialtiesSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Specialty Input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _specialtyController,
                decoration: InputDecoration(
                  labelText: 'Add Specialty',
                  hintText: 'e.g., Wiring, Leak Repair',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.add_circle_outline),
                ),
                onFieldSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      _specialties.add(value.trim());
                      _specialtyController.clear();
                    });
                  }
                },
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            ElevatedButton(
              onPressed: () {
                if (_specialtyController.text.trim().isNotEmpty) {
                  setState(() {
                    _specialties.add(_specialtyController.text.trim());
                    _specialtyController.clear();
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
        
        // Specialties List
        if (_specialties.isNotEmpty) ...[
          SizedBox(height: isMobile ? 16 : 20),
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            children: _specialties.map((specialty) {
              return Chip(
                label: Text(specialty),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                deleteIcon: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                onDeleted: () {
                  setState(() {
                    _specialties.remove(specialty);
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

