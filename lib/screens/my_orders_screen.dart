import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../generated/app_localizations.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  User? _user;
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  List<OrderStatus> _statuses = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _user = await StorageService.getUser();

      if (_user != null) {
        final result = await ApiService.getOrders(_user!.id);
        if (result['success'] == true) {
          _orders = result['orders'] as List<Order>;
          _statuses = result['statuses'] as List<OrderStatus>;
          _filteredOrders = List.from(_orders);
        }
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _filterOrders(String status) {
    setState(() {
      _selectedStatus = status;
      if (status == 'all') {
        _filteredOrders = List.from(_orders);
      } else {
        _filteredOrders = _orders
            .where((order) => order.status.toLowerCase() == status.toLowerCase())
            .toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case '1': // Pending
        return AppColors.warning;
      case '2': // Processing
        return AppColors.info;
      case '3': // Completed
        return AppColors.success;
      case '4': // Cancelled
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case '1': // Pending
        return Icons.hourglass_empty;
      case '2': // Processing
        return Icons.sync;
      case '3': // Completed
        return Icons.check_circle;
      case '4': // Cancelled
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(l10n.myOrders),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                children: [
                  // Status Filter Chips
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip(l10n.allOrders, 'all'),
                        ..._statuses.map((status) => _buildFilterChip(
                              status.name,
                              status.id,
                            )),
                      ],
                    ),
                  ),
                  // Orders List
                  Expanded(
                    child: _filteredOrders.isEmpty
                        ? _buildEmptyState(l10n)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderCard(_filteredOrders[index], l10n);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _filterOrders(status),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noOrdersFound,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, AppLocalizations l10n) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: order.imageUrl.isNotEmpty
                          ? Image.network(
                              order.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.textSecondary,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Order Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.order} #${order.serial}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (order.websiteName != null)
                          Text(
                            order.websiteName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${order.totalPrice}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              height: 1,
              color: AppColors.border,
            ),
            // Order Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.statusName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  // Date
                  Text(
                    order.date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
