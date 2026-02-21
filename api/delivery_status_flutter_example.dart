// Flutter Delivery Status API Example
// This file demonstrates how to view and change delivery status

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// MODEL CLASSES
// ============================================================================

class DeliveryStatus {
  final int customerId;
  final String name;
  final String phone;
  final int deliveryStatus;
  final bool deliveryEnabled;
  final String deliveryText;
  final int? oldStatus;
  final int? newStatus;

  DeliveryStatus({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.deliveryStatus,
    required this.deliveryEnabled,
    required this.deliveryText,
    this.oldStatus,
    this.newStatus,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      customerId: json['customer_id'],
      name: json['name'],
      phone: json['phone'],
      deliveryStatus: json['delivery_status'] ?? json['new_status'],
      deliveryEnabled: json['delivery_enabled'],
      deliveryText: json['delivery_text'],
      oldStatus: json['old_status'],
      newStatus: json['new_status'],
    );
  }
}

class DeliveryStatusResponse {
  final bool success;
  final String message;
  final DeliveryStatus? data;

  DeliveryStatusResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory DeliveryStatusResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusResponse(
      success: json['success'],
      message: json['message'],
      data: json['success'] && json['data'] != null
          ? DeliveryStatus.fromJson(json['data'])
          : null,
    );
  }
}

// ============================================================================
// API SERVICE
// ============================================================================

class DeliveryStatusService {
  static const String baseUrl = 'https://ruyadream.com/velox/api';

  /// Get delivery status for a customer
  static Future<DeliveryStatusResponse> getDeliveryStatus(
      int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/delivery_status.php?customer_id=$customerId'),
      );

      final jsonData = json.decode(response.body);
      return DeliveryStatusResponse.fromJson(jsonData);
    } catch (e) {
      return DeliveryStatusResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Update delivery status for a customer
  /// deliveryStatus: 0 = No, 1 = Yes
  static Future<DeliveryStatusResponse> updateDeliveryStatus(
    int customerId,
    int deliveryStatus,
  ) async {
    if (deliveryStatus != 0 && deliveryStatus != 1) {
      return DeliveryStatusResponse(
        success: false,
        message: 'Invalid delivery status. Must be 0 or 1.',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delivery_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_id': customerId,
          'delivery_status': deliveryStatus,
        }),
      );

      final jsonData = json.decode(response.body);
      return DeliveryStatusResponse.fromJson(jsonData);
    } catch (e) {
      return DeliveryStatusResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Enable delivery for a customer (set to 1)
  static Future<DeliveryStatusResponse> enableDelivery(int customerId) {
    return updateDeliveryStatus(customerId, 1);
  }

  /// Disable delivery for a customer (set to 0)
  static Future<DeliveryStatusResponse> disableDelivery(int customerId) {
    return updateDeliveryStatus(customerId, 0);
  }

  /// Toggle delivery status
  static Future<DeliveryStatusResponse> toggleDelivery(
      int customerId, bool currentStatus) {
    return updateDeliveryStatus(customerId, currentStatus ? 0 : 1);
  }
}

// ============================================================================
// DELIVERY STATUS SCREEN
// ============================================================================

class DeliveryStatusScreen extends StatefulWidget {
  final int customerId;

  const DeliveryStatusScreen({Key? key, required this.customerId})
      : super(key: key);

  @override
  _DeliveryStatusScreenState createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends State<DeliveryStatusScreen> {
  DeliveryStatus? _deliveryStatus;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeliveryStatus();
  }

  Future<void> _loadDeliveryStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response =
        await DeliveryStatusService.getDeliveryStatus(widget.customerId);

    setState(() {
      _isLoading = false;
      if (response.success) {
        _deliveryStatus = response.data;
      } else {
        _error = response.message;
      }
    });
  }

  Future<void> _toggleDeliveryStatus() async {
    if (_deliveryStatus == null || _isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    final response = await DeliveryStatusService.toggleDelivery(
      widget.customerId,
      _deliveryStatus!.deliveryEnabled,
    );

    setState(() {
      _isUpdating = false;
    });

    if (response.success) {
      setState(() {
        _deliveryStatus = response.data;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Status'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDeliveryStatus,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDeliveryStatus,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_deliveryStatus == null) {
      return Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveryStatus,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow('Name', _deliveryStatus!.name),
                    SizedBox(height: 8),
                    _buildInfoRow('Phone', _deliveryStatus!.phone),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      'Customer ID',
                      _deliveryStatus!.customerId.toString(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Delivery Status Card
            Card(
              color: _deliveryStatus!.deliveryEnabled
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      _deliveryStatus!.deliveryEnabled
                          ? Icons.local_shipping
                          : Icons.block,
                      size: 64,
                      color: _deliveryStatus!.deliveryEnabled
                          ? Colors.green
                          : Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Delivery Status',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _deliveryStatus!.deliveryText,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _deliveryStatus!.deliveryEnabled
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isUpdating ? null : _toggleDeliveryStatus,
                      icon: _isUpdating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _deliveryStatus!.deliveryEnabled
                                  ? Icons.toggle_on
                                  : Icons.toggle_off,
                            ),
                      label: Text(
                        _deliveryStatus!.deliveryEnabled
                            ? 'DISABLE DELIVERY'
                            : 'ENABLE DELIVERY',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: _deliveryStatus!.deliveryEnabled
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Status Explanation Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What does this mean?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildStatusInfo(
                      Icons.check_circle,
                      'Delivery Yes',
                      'This customer can receive deliveries. Orders can be delivered to their address.',
                      Colors.green,
                    ),
                    SizedBox(height: 12),
                    _buildStatusInfo(
                      Icons.cancel,
                      'Delivery No',
                      'This customer cannot receive deliveries. They must pick up orders themselves.',
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo(
      IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SIMPLE USAGE EXAMPLE
// ============================================================================

void simpleDeliveryStatusExample() async {
  int customerId = 853;

  // 1. Get current delivery status
  final status = await DeliveryStatusService.getDeliveryStatus(customerId);
  if (status.success) {
    print('Current delivery status: ${status.data!.deliveryText}');
    print('Delivery enabled: ${status.data!.deliveryEnabled}');
  }

  // 2. Enable delivery
  final enableResponse = await DeliveryStatusService.enableDelivery(customerId);
  if (enableResponse.success) {
    print('Delivery enabled successfully!');
  }

  // 3. Disable delivery
  final disableResponse =
      await DeliveryStatusService.disableDelivery(customerId);
  if (disableResponse.success) {
    print('Delivery disabled successfully!');
  }

  // 4. Toggle delivery
  final currentStatus = true; // Current status
  final toggleResponse =
      await DeliveryStatusService.toggleDelivery(customerId, currentStatus);
  if (toggleResponse.success) {
    print('Delivery status toggled!');
  }
}

// ============================================================================
// DELIVERY TOGGLE WIDGET
// ============================================================================

class DeliveryToggleWidget extends StatefulWidget {
  final int customerId;
  final bool initialStatus;
  final Function(bool)? onStatusChanged;

  const DeliveryToggleWidget({
    Key? key,
    required this.customerId,
    required this.initialStatus,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  _DeliveryToggleWidgetState createState() => _DeliveryToggleWidgetState();
}

class _DeliveryToggleWidgetState extends State<DeliveryToggleWidget> {
  late bool _deliveryEnabled;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _deliveryEnabled = widget.initialStatus;
  }

  Future<void> _toggleDelivery(bool value) async {
    setState(() {
      _isUpdating = true;
    });

    final response = await DeliveryStatusService.updateDeliveryStatus(
      widget.customerId,
      value ? 1 : 0,
    );

    setState(() {
      _isUpdating = false;
    });

    if (response.success) {
      setState(() {
        _deliveryEnabled = value;
      });
      widget.onStatusChanged?.call(value);
    } else {
      // Show error and revert
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _deliveryEnabled ? Icons.local_shipping : Icons.block,
        color: _deliveryEnabled ? Colors.green : Colors.red,
      ),
      title: Text('Delivery Service'),
      subtitle: Text(_deliveryEnabled ? 'Enabled' : 'Disabled'),
      trailing: _isUpdating
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _deliveryEnabled,
              onChanged: _toggleDelivery,
            ),
    );
  }
}

