import 'package:flutter/material.dart';
import '../models/service_provider.dart';
import '../services/service_provider_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class RegisterServiceProviderScreen extends StatefulWidget {
  const RegisterServiceProviderScreen({super.key});

  @override
  State<RegisterServiceProviderScreen> createState() => _RegisterServiceProviderScreenState();
}

class _RegisterServiceProviderScreenState extends State<RegisterServiceProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _specialtyController = TextEditingController();
  
  String _serviceType = 'electrician';
  bool _isLoading = false;
  final List<String> _specialties = [];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _saveProvider() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Create new service provider
    final newProvider = ServiceProvider(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      serviceType: _serviceType,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      specialties: _specialties,
      rating: 0.0,
      totalJobs: 0,
      isAvailable: true,
    );

    // Save to service
    ServiceProviderService.addProvider(newProvider);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newProvider.name} registered successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      Navigator.pop(context, newProvider);
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
        title: Text(
          'Register Service Provider',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppTheme.getTextPrimaryColor(context),
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
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProvider,
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
                          'Register Provider',
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
                  : AppTheme.getSurfaceColor(context),
              border: Border.all(
                color: isSelected 
                    ? color 
                    : AppTheme.getTextSecondaryColor(context).withOpacity(0.3),
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
                  color: isSelected ? color : AppTheme.getTextSecondaryColor(context),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  type['label'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? color : AppTheme.getTextPrimaryColor(context),
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

