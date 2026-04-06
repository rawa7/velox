// Flutter Customer Statement Example
// This file demonstrates how to fetch and display customer statement data

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// MODEL CLASSES
// ============================================================================

class CustomerStatement {
  final Customer customer;
  final FinancialSummary financialSummary;
  final ItemsSummary itemsSummary;
  final List<OrderItem> pendingItems;
  final List<OrderItem> completedItems;
  final List<OrderItem> refundedItems;
  final List<Payment> payments;
  final DateFilters? filters;

  CustomerStatement({
    required this.customer,
    required this.financialSummary,
    required this.itemsSummary,
    required this.pendingItems,
    required this.completedItems,
    required this.refundedItems,
    required this.payments,
    this.filters,
  });

  factory CustomerStatement.fromJson(Map<String, dynamic> json) {
    var data = json['data'];
    return CustomerStatement(
      customer: Customer.fromJson(data['customer']),
      financialSummary: FinancialSummary.fromJson(data['financial_summary']),
      itemsSummary: ItemsSummary.fromJson(data['items_summary']),
      pendingItems: (data['pending_items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      completedItems: (data['completed_items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      refundedItems: (data['refunded_items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      payments: (data['payments'] as List)
          .map((payment) => Payment.fromJson(payment))
          .toList(),
      filters: data['filters'] != null
          ? DateFilters.fromJson(data['filters'])
          : null,
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String usertype;
  final double debtLimit;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    required this.usertype,
    required this.debtLimit,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      usertype: json['usertype'],
      debtLimit: (json['debt_limit'] as num).toDouble(),
    );
  }
}

class FinancialSummary {
  final double completedPurchasesValue;
  final double totalPayments;
  final double currentBalance;
  final String balanceStatus;
  final double pendingItemsValue;
  final double refundedItemsValue;
  final double ordersAwaitingPayment;
  final double availableCapacity;

  FinancialSummary({
    required this.completedPurchasesValue,
    required this.totalPayments,
    required this.currentBalance,
    required this.balanceStatus,
    required this.pendingItemsValue,
    required this.refundedItemsValue,
    required this.ordersAwaitingPayment,
    required this.availableCapacity,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      completedPurchasesValue:
          (json['completed_purchases_value'] as num).toDouble(),
      totalPayments: (json['total_payments'] as num).toDouble(),
      currentBalance: (json['current_balance'] as num).toDouble(),
      balanceStatus: json['balance_status'],
      pendingItemsValue: (json['pending_items_value'] as num).toDouble(),
      refundedItemsValue: (json['refunded_items_value'] as num).toDouble(),
      ordersAwaitingPayment:
          (json['orders_awaiting_payment'] as num).toDouble(),
      availableCapacity: (json['available_capacity'] as num).toDouble(),
    );
  }

  Color getBalanceColor() {
    switch (balanceStatus) {
      case 'due':
        return Colors.red;
      case 'overpaid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String getBalanceLabel() {
    switch (balanceStatus) {
      case 'due':
        return 'Due';
      case 'overpaid':
        return 'Overpaid';
      default:
        return 'Settled';
    }
  }
}

class ItemsSummary {
  final int totalItems;
  final int pendingCount;
  final int completedCount;
  final int refundedCount;
  final List<StatusBreakdown> statusBreakdown;

  ItemsSummary({
    required this.totalItems,
    required this.pendingCount,
    required this.completedCount,
    required this.refundedCount,
    required this.statusBreakdown,
  });

  factory ItemsSummary.fromJson(Map<String, dynamic> json) {
    return ItemsSummary(
      totalItems: json['total_items'],
      pendingCount: json['pending_count'],
      completedCount: json['completed_count'],
      refundedCount: json['refunded_count'],
      statusBreakdown: (json['status_breakdown'] as List)
          .map((status) => StatusBreakdown.fromJson(status))
          .toList(),
    );
  }
}

class StatusBreakdown {
  final int id;
  final String name;
  final int count;
  final double total;

  StatusBreakdown({
    required this.id,
    required this.name,
    required this.count,
    required this.total,
  });

  factory StatusBreakdown.fromJson(Map<String, dynamic> json) {
    return StatusBreakdown(
      id: json['id'],
      name: json['name'],
      count: json['count'],
      total: (json['total'] as num).toDouble(),
    );
  }
}

class OrderItem {
  final int id;
  final String? serial;
  final int status;
  final String statusName;
  final double itemPrice;
  final double totalPrice;
  final double shippingPrice;
  final double cargo;
  final double tax;
  final double commission;
  final int qty;
  final String? size;
  final int paymentStatus;
  final String? websiteName;
  final String? imageUrl;
  final String createdAt;

  OrderItem({
    required this.id,
    this.serial,
    required this.status,
    required this.statusName,
    required this.itemPrice,
    required this.totalPrice,
    required this.shippingPrice,
    required this.cargo,
    required this.tax,
    required this.commission,
    required this.qty,
    this.size,
    required this.paymentStatus,
    this.websiteName,
    this.imageUrl,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      serial: json['serial'],
      status: json['status'],
      statusName: json['status_name'] ?? 'Unknown',
      itemPrice: (json['itemprice'] as num).toDouble(),
      totalPrice: (json['totalprice'] as num).toDouble(),
      shippingPrice: (json['shippingprice'] as num).toDouble(),
      cargo: (json['cargo'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      qty: json['qty'],
      size: json['size'],
      paymentStatus: json['paymentstatus'],
      websiteName: json['website_name'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'],
    );
  }
}

class Payment {
  final int id;
  final int buyerId;
  final String buyerName;
  final double amount;
  final double dinarConvert;
  final String date;
  final String? note;

  Payment({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.amount,
    required this.dinarConvert,
    required this.date,
    this.note,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      buyerId: json['buyerid'],
      buyerName: json['buyer_name'],
      amount: (json['amount'] as num).toDouble(),
      dinarConvert: (json['dinarconvert'] as num).toDouble(),
      date: json['date'],
      note: json['note'],
    );
  }
}

class DateFilters {
  final String? dateFrom;
  final String? dateTo;

  DateFilters({this.dateFrom, this.dateTo});

  factory DateFilters.fromJson(Map<String, dynamic> json) {
    return DateFilters(
      dateFrom: json['date_from'],
      dateTo: json['date_to'],
    );
  }
}

// ============================================================================
// API SERVICE
// ============================================================================

class CustomerStatementService {
  static const String baseUrl = 'https://veloxshoppingiq.com/api';

  static Future<CustomerStatement> getStatement(
    int customerId, {
    String? dateFrom,
    String? dateTo,
  }) async {
    var uri = Uri.parse('$baseUrl/customer_statement.php').replace(
      queryParameters: {
        'customer_id': customerId.toString(),
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success']) {
        return CustomerStatement.fromJson(jsonData);
      } else {
        throw Exception(jsonData['message']);
      }
    } else {
      throw Exception('Failed to load customer statement');
    }
  }
}

// ============================================================================
// UI SCREEN
// ============================================================================

class CustomerStatementScreen extends StatefulWidget {
  final int customerId;

  const CustomerStatementScreen({Key? key, required this.customerId})
      : super(key: key);

  @override
  _CustomerStatementScreenState createState() =>
      _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  CustomerStatement? _statement;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final statement =
          await CustomerStatementService.getStatement(widget.customerId);
      setState(() {
        _statement = statement;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Statement'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStatement,
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
              onPressed: _loadStatement,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_statement == null) {
      return Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadStatement,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerHeader(),
            _buildFinancialSummary(),
            _buildItemsSummary(),
            _buildTabSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader() {
    final customer = _statement!.customer;
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (customer.email != null)
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(customer.email!),
                ],
              ),
            if (customer.phone != null)
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(customer.phone!),
                ],
              ),
            SizedBox(height: 8),
            Chip(
              label: Text(customer.usertype),
              backgroundColor: Colors.blue.shade100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final summary = _statement!.financialSummary;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildSummaryRow(
              'Completed Purchases',
              '\$${summary.completedPurchasesValue.toStringAsFixed(2)}',
              Colors.blue,
            ),
            _buildSummaryRow(
              'Total Payments',
              '\$${summary.totalPayments.toStringAsFixed(2)}',
              Colors.green,
            ),
            Divider(),
            _buildSummaryRow(
              'Current Balance (${summary.getBalanceLabel()})',
              '\$${summary.currentBalance.abs().toStringAsFixed(2)}',
              summary.getBalanceColor(),
              isBold: true,
            ),
            SizedBox(height: 8),
            _buildSummaryRow(
              'Pending Orders Value',
              '\$${summary.pendingItemsValue.toStringAsFixed(2)}',
              Colors.orange,
            ),
            _buildSummaryRow(
              'Available Capacity',
              '\$${summary.availableCapacity.toStringAsFixed(2)}',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSummary() {
    final summary = _statement!.itemsSummary;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orders Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountChip('Total', summary.totalItems, Colors.blue),
                _buildCountChip('Pending', summary.pendingCount, Colors.orange),
                _buildCountChip(
                    'Completed', summary.completedCount, Colors.green),
                _buildCountChip('Refunded', summary.refundedCount, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTabSection() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending (${_statement!.pendingItems.length})'),
              Tab(text: 'Completed (${_statement!.completedItems.length})'),
              Tab(text: 'Refunded (${_statement!.refundedItems.length})'),
              Tab(text: 'Payments (${_statement!.payments.length})'),
            ],
          ),
          Container(
            height: 400,
            child: TabBarView(
              children: [
                _buildItemsList(_statement!.pendingItems, Colors.orange),
                _buildItemsList(_statement!.completedItems, Colors.green),
                _buildItemsList(_statement!.refundedItems, Colors.red),
                _buildPaymentsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<OrderItem> items, Color accentColor) {
    if (items.isEmpty) {
      return Center(child: Text('No items found'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: item.imageUrl != null
                ? Image.network(item.imageUrl!, width: 50, height: 50,
                    fit: BoxFit.cover, errorBuilder: (context, error, stack) {
                    return Icon(Icons.image_not_supported);
                  })
                : Icon(Icons.shopping_bag, color: accentColor),
            title: Text('Order #${item.id}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.websiteName ?? "Unknown"} • ${item.statusName}'),
                Text('\$${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Chip(
              label: Text(item.statusName, style: TextStyle(fontSize: 10)),
              backgroundColor: accentColor.withOpacity(0.2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsList() {
    final payments = _statement!.payments;
    if (payments.isEmpty) {
      return Center(child: Text('No payments found'));
    }

    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(Icons.payment, color: Colors.green),
            title: Text('\$${payment.amount.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.date),
                if (payment.note != null) Text(payment.note!),
              ],
            ),
            trailing: Text(
              '${payment.dinarConvert.toStringAsFixed(0)} IQD',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

