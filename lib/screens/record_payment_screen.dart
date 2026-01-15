import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'package:intl/intl.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({super.key});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _lateFeeController = TextEditingController();
  final _notesController = TextEditingController();
  final _transactionIdController = TextEditingController();

  List<Tenant> _tenants = [];
  List<Room> _rooms = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  Tenant? _selectedTenant;
  Room? _selectedRoom;
  String _paymentType = 'rent';
  String _paymentMethod = 'cash';
  DateTime _dueDate = DateTime.now();
  DateTime? _paidDate;
  String _month = DateFormat('MMMM').format(DateTime.now());
  int _year = DateTime.now().year;

  final List<String> _paymentTypes = [
    'rent',
    'deposit',
    'maintenance',
    'electricity',
    'water',
    'other',
  ];

  final List<String> _paymentMethods = [
    'cash',
    'online',
    'upi',
    'bank_transfer',
    'cheque',
    'card',
  ];

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _lateFeeController.dispose();
    _notesController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final tenantsResponse = await ApiService.fetchTenants();
      final roomsResponse = await ApiService.fetchRooms();

      setState(() {
        _tenants = ApiService.parseTenants(tenantsResponse);
        _rooms = ApiService.parseRooms(roomsResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
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
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        title: const Text(
          'Record Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPayment,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSubmitting ? Colors.grey : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tenant Selection
                    _buildSection(
                      'Tenant Information',
                      [
                        _buildTenantDropdown(isMobile),
                        const SizedBox(height: 16),
                        _buildRoomDropdown(isMobile),
                      ],
                      isMobile,
                    ),

                    const SizedBox(height: 24),

                    // Payment Details
                    _buildSection(
                      'Payment Details',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildPaymentTypeDropdown(isMobile),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPaymentMethodDropdown(isMobile),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildAmountField(isMobile),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildLateFeeField(isMobile),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMonthDropdown(isMobile),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildYearField(isMobile),
                            ),
                          ],
                        ),
                      ],
                      isMobile,
                    ),

                    const SizedBox(height: 24),

                    // Date Information
                    _buildSection(
                      'Date Information',
                      [
                        _buildDueDatePicker(isMobile),
                        const SizedBox(height: 16),
                        _buildPaidDatePicker(isMobile),
                      ],
                      isMobile,
                    ),

                    const SizedBox(height: 24),

                    // Transaction Details
                    _buildSection(
                      'Transaction Details',
                      [
                        _buildTransactionIdField(isMobile),
                        const SizedBox(height: 16),
                        _buildNotesField(isMobile),
                      ],
                      isMobile,
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSubmitting ? 'Recording Payment...' : 'Record Payment',
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
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTenantDropdown(bool isMobile) {
    return DropdownButtonFormField<Tenant>(
      value: _selectedTenant,
      decoration: InputDecoration(
        labelText: 'Select Tenant',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.person),
      ),
      items: _tenants.map((tenant) {
        return DropdownMenuItem<Tenant>(
          value: tenant,
          child: Text('${tenant.name} (${tenant.email})'),
        );
      }).toList(),
      onChanged: (tenant) {
        setState(() {
          _selectedTenant = tenant;
          _selectedRoom = null; // Reset room selection
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a tenant';
        }
        return null;
      },
    );
  }

  Widget _buildRoomDropdown(bool isMobile) {
    final availableRooms = _selectedTenant != null
        ? _rooms.where((room) => room.tenantId == _selectedTenant!.id).toList()
        : <Room>[];

    return DropdownButtonFormField<Room>(
      value: _selectedRoom,
      decoration: InputDecoration(
        labelText: 'Select Room',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.home),
      ),
      items: availableRooms.map((room) {
        return DropdownMenuItem<Room>(
          value: room,
          child: Text('Room ${room.number} (${room.type})'),
        );
      }).toList(),
      onChanged: (room) {
        setState(() {
          _selectedRoom = room;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a room';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentTypeDropdown(bool isMobile) {
    return DropdownButtonFormField<String>(
      value: _paymentType,
      decoration: InputDecoration(
        labelText: 'Payment Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.category),
      ),
      items: _paymentTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type.toUpperCase()),
        );
      }).toList(),
      onChanged: (type) {
        setState(() {
          _paymentType = type!;
        });
      },
    );
  }

  Widget _buildPaymentMethodDropdown(bool isMobile) {
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      decoration: InputDecoration(
        labelText: 'Payment Method',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.payment),
      ),
      items: _paymentMethods.map((method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(method.replaceAll('_', ' ').toUpperCase()),
        );
      }).toList(),
      onChanged: (method) {
        setState(() {
          _paymentMethod = method!;
        });
      },
    );
  }

  Widget _buildAmountField(bool isMobile) {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.currency_rupee),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildLateFeeField(bool isMobile) {
    return TextFormField(
      controller: _lateFeeController,
      decoration: InputDecoration(
        labelText: 'Late Fee',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.warning),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildMonthDropdown(bool isMobile) {
    return DropdownButtonFormField<String>(
      value: _month,
      decoration: InputDecoration(
        labelText: 'Month',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.calendar_month),
      ),
      items: _months.map((month) {
        return DropdownMenuItem<String>(
          value: month,
          child: Text(month),
        );
      }).toList(),
      onChanged: (month) {
        setState(() {
          _month = month!;
        });
      },
    );
  }

  Widget _buildYearField(bool isMobile) {
    return TextFormField(
      initialValue: _year.toString(),
      decoration: InputDecoration(
        labelText: 'Year',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.calendar_today),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isNotEmpty) {
          _year = int.tryParse(value) ?? DateTime.now().year;
        }
      },
    );
  }

  Widget _buildDueDatePicker(bool isMobile) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule),
      title: const Text('Due Date'),
      subtitle: Text(DateFormat('MMM dd, yyyy').format(_dueDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dueDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          setState(() {
            _dueDate = date;
          });
        }
      },
    );
  }

  Widget _buildPaidDatePicker(bool isMobile) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle),
      title: const Text('Paid Date (Optional)'),
      subtitle: Text(_paidDate != null 
          ? DateFormat('MMM dd, yyyy').format(_paidDate!)
          : 'Not paid yet'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_paidDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _paidDate = null;
                });
              },
            ),
          const Icon(Icons.calendar_today),
        ],
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _paidDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _paidDate = date;
          });
        }
      },
    );
  }

  Widget _buildTransactionIdField(bool isMobile) {
    return TextFormField(
      controller: _transactionIdController,
      decoration: InputDecoration(
        labelText: 'Transaction ID (Optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.receipt),
      ),
    );
  }

  Widget _buildNotesField(bool isMobile) {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Notes (Optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final lateFee = _lateFeeController.text.isNotEmpty 
          ? double.parse(_lateFeeController.text) 
          : 0.0;

      // Determine payment status
      String status = 'pending';
      if (_paidDate != null) {
        status = 'paid';
      } else if (_dueDate.isBefore(DateTime.now())) {
        status = 'overdue';
      }

      final paymentData = {
        'tenantId': _selectedTenant!.id,
        'tenantName': _selectedTenant!.name,
        'roomNumber': _selectedRoom!.number,
        'amount': amount,
        'lateFee': lateFee,
        'dueDate': _dueDate.toIso8601String(),
        'paidDate': _paidDate?.toIso8601String(),
        'status': status,
        'type': _paymentType,
        'paymentMethod': _paymentMethod,
        'transactionId': _transactionIdController.text.isNotEmpty 
            ? _transactionIdController.text 
            : null,
        'month': _month,
        'year': _year,
        'notes': _notesController.text.isNotEmpty 
            ? _notesController.text 
            : null,
      };

      // Record payment via API
      final response = await ApiService.recordPayment(paymentData);

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to record payment: ${response['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}