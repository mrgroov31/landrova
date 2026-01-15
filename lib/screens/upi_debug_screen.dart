import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

class UpiDebugScreen extends StatefulWidget {
  const UpiDebugScreen({super.key});

  @override
  State<UpiDebugScreen> createState() => _UpiDebugScreenState();
}

class _UpiDebugScreenState extends State<UpiDebugScreen> {
  bool _isLoading = false;
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _runDebugTests();
  }

  Future<void> _runDebugTests() async {
    setState(() {
      _isLoading = true;
      _debugLogs.clear();
    });

    try {
      _addLog('🧪 Starting UPI Debug Tests...');
      
      // Test 1: Initialize payment service
      _addLog('🔄 Test 1: Initializing payment service...');
      await PaymentService.initialize();
      _addLog('✅ Test 1: Payment service initialized');
      
      // Test 2: Check available UPI apps
      _addLog('🔄 Test 2: Checking available UPI apps...');
      final availableApps = PaymentService.getAvailableUpiApps();
      _addLog('📱 Found ${availableApps.length} UPI apps in database');
      for (final app in availableApps) {
        _addLog('   - ${app.name} (${app.packageName})');
      }
      
      // Test 3: Check installed UPI apps
      _addLog('🔄 Test 3: Checking installed UPI apps...');
      final installedApps = await PaymentService.getInstalledUpiApps();
      _addLog('📱 Found ${installedApps.length} installed UPI apps');
      
      if (installedApps.isEmpty) {
        _addLog('❌ CRITICAL: No UPI apps detected on device!');
        _addLog('💡 SOLUTION: Install UPI apps from Play Store:');
        _addLog('   • Google Pay (recommended)');
        _addLog('   • PhonePe');
        _addLog('   • Paytm');
        _addLog('   • BHIM UPI');
        _addLog('');
        _addLog('📲 After installing, restart this app and test again');
      } else {
        for (final app in installedApps) {
          _addLog('   ✅ ${app.name} is installed and working');
        }
      }
      
      // Test 4: Check UPI support
      _addLog('🔄 Test 4: Checking device UPI support...');
      final upiSupported = await PaymentService.isUpiSupported();
      if (upiSupported) {
        _addLog('✅ Device supports UPI payments');
      } else {
        _addLog('❌ Device does not support UPI payments');
        _addLog('💡 This usually means no UPI apps are installed');
      }
      
      // Test 4: Run device-specific debug
      _addLog('🔄 Test 5: Running device-specific UPI debug...');
      await PaymentService.debugUpiOnDevice();
      _addLog('✅ Test 5: Device debug completed');
      
      if (installedApps.isEmpty) {
        _addLog('');
        _addLog('🚨 IMPORTANT: UPI payments will NOT work!');
        _addLog('📲 Install a UPI app first, then test again');
      } else {
        _addLog('');
        _addLog('🎉 UPI setup looks good! Payments should work');
      }
      
      _addLog('🎉 All debug tests completed!');
      
    } catch (e) {
      _addLog('❌ Debug test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
  }

  Future<void> _testUpiPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('💳 Testing UPI payment (bypassing detection)...');
      _addLog('⚠️ This will try to open a UPI app directly');
      _addLog('⚠️ DO NOT complete the ₹1 test payment if it opens');
      
      final success = await PaymentService.forceTestUpiLaunch();
      
      if (success) {
        _addLog('✅ SUCCESS! UPI app opened successfully');
        _addLog('🎉 Your UPI integration is working correctly');
        _addLog('💡 You can now make real payments in the app');
      } else {
        _addLog('❌ FAILED! No UPI app responded');
        _addLog('💡 Try these solutions:');
        _addLog('   1. Restart your device');
        _addLog('   2. Open Google Pay/PhonePe manually first');
        _addLog('   3. Check UPI app permissions');
        _addLog('   4. Try a release build instead of debug');
      }
      
    } catch (e) {
      _addLog('❌ UPI payment test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Debug'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runDebugTests,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Run Debug Tests'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testUpiPayment,
                    icon: const Icon(Icons.payment),
                    label: const Text('Test UPI Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),
          
          // Debug logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _debugLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No debug logs yet. Tap "Run Debug Tests" to start.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _debugLogs.length,
                      itemBuilder: (context, index) {
                        final log = _debugLogs[index];
                        Color textColor = Colors.white;
                        
                        if (log.contains('✅')) {
                          textColor = Colors.green;
                        } else if (log.contains('❌')) {
                          textColor = Colors.red;
                        } else if (log.contains('⚠️')) {
                          textColor = Colors.orange;
                        } else if (log.contains('🧪') || log.contains('🔄')) {
                          textColor = Colors.blue;
                        } else if (log.contains('📱') || log.contains('💳')) {
                          textColor = Colors.cyan;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Debug Build Limitation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Android 11+ restricts app detection in debug builds. Even if UPI apps show as "not detected", they may still work when you try the actual payment.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Solutions if UPI still doesn\'t work:',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Restart your device after installing UPI apps', style: TextStyle(color: Colors.orange[700], fontSize: 13)),
                    Text('• Open Google Pay/PhonePe manually first', style: TextStyle(color: Colors.orange[700], fontSize: 13)),
                    Text('• Check UPI app permissions in Settings', style: TextStyle(color: Colors.orange[700], fontSize: 13)),
                    Text('• Try building a release APK instead', style: TextStyle(color: Colors.orange[700], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The "Test UPI Payment" button bypasses detection and tries direct launch - this is the most reliable test!',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug Instructions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Run Debug Tests to check UPI app availability\n'
                  '2. If no UPI apps found, install Google Pay or PhonePe\n'
                  '3. Test UPI Payment to verify the payment flow\n'
                  '4. Check the debug logs for detailed information',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInstallButton(String appName, String packageName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: () async {
          final playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageName';
          try {
            await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
          } catch (e) {
            _addLog('❌ Failed to open Play Store for $appName: $e');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                'Install $appName',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}