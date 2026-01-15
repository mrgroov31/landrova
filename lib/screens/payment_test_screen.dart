import 'package:flutter/material.dart';
import '../utils/payment_integration_test.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class PaymentTestScreen extends StatefulWidget {
  const PaymentTestScreen({super.key});

  @override
  State<PaymentTestScreen> createState() => _PaymentTestScreenState();
}

class _PaymentTestScreenState extends State<PaymentTestScreen> {
  bool _isRunningTest = false;
  String _testResults = '';
  Map<String, dynamic>? _testReport;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Payment Integration Test'),
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Status Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.science,
                          color: Colors.blue,
                          size: isMobile ? 24 : 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Integration Test',
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Test UPI payment system, revenue calculations, and cache performance',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: AppTheme.getTextSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Test Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isRunningTest ? null : _runQuickTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isRunningTest
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            _isRunningTest ? 'Running...' : 'Quick Test',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isRunningTest ? null : _runCompleteTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.science),
                          label: Text(
                            'Full Test',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Generate Report Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRunningTest ? null : _generateReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.assessment),
                      label: Text(
                        'Generate Report',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Report Card
            if (_testReport != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _testReport!['testStatus'] == 'PASSED'
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (_testReport!['testStatus'] == 'PASSED'
                                ? Colors.green
                                : Colors.red).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _testReport!['testStatus'] == 'PASSED'
                                ? Icons.check_circle
                                : Icons.error,
                            color: _testReport!['testStatus'] == 'PASSED'
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Test Report - ${_testReport!['testStatus']}',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Report Details
                    _buildReportSection('Payment Service', _testReport!['paymentService']),
                    _buildReportSection('Payment Data', _testReport!['paymentData']),
                    _buildReportSection('Revenue Calculations', _testReport!['revenueCalculations']),
                    _buildReportSection('Cache Performance', _testReport!['cachePerformance']),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Generated: ${DateTime.parse(_testReport!['timestamp']).toLocal().toString().split('.')[0]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Test Results Card
            if (_testResults.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _testResults,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade800,
                        ),
                      ),
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

  Widget _buildReportSection(String title, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          ...data.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _runQuickTest() async {
    setState(() {
      _isRunningTest = true;
      _testResults = 'Running quick test...\n';
    });

    try {
      await PaymentIntegrationTest.runQuickTest();
      setState(() {
        _testResults += '\n✅ Quick test completed successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Quick test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _runCompleteTest() async {
    setState(() {
      _isRunningTest = true;
      _testResults = 'Running complete test suite...\n';
    });

    try {
      await PaymentIntegrationTest.runCompleteTest();
      setState(() {
        _testResults += '\n✅ Complete test suite passed!';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Complete test suite failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isRunningTest = true;
    });

    try {
      final report = await PaymentIntegrationTest.generateTestReport();
      setState(() {
        _testReport = report;
        _testResults = 'Test report generated successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Failed to generate report: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }
}