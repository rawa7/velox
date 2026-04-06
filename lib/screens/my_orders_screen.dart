import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/currency.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../generated/app_localizations.dart';
import 'order_detail_screen.dart';

/// Tab index for My Orders in [MainNavigation].
const int kMyOrdersTabIndex = 3;

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({
    super.key,
    this.selectedTabIndex = 0,
    this.myTabIndex = kMyOrdersTabIndex,
  });

  final int selectedTabIndex;
  final int myTabIndex;

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

  @override
  void didUpdateWidget(MyOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasVisible = oldWidget.selectedTabIndex == oldWidget.myTabIndex;
    final isVisible = widget.selectedTabIndex == widget.myTabIndex;
    if (!wasVisible && isVisible) {
      _loadData();
    }
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

  Color _getStatusColor(BuildContext context, String status) {
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
        return context.textSecondaryColor;
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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: Text(l10n.myOrders),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        backgroundColor: context.surfaceColor,
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
                        ? _buildEmptyState(context, l10n)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (ctx, index) {
                              return _buildOrderCard(ctx, _filteredOrders[index], l10n);
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
        backgroundColor: context.surfaceColor,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : context.textSecondaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.borderColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: context.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noOrdersFound,
            style: TextStyle(
              fontSize: 18,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, AppLocalizations l10n) {
    final statusColor = _getStatusColor(context, order.status);
    final statusIcon = _getStatusIcon(order.status);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order, currentUser: _user),
          ),
        );
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
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
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: order.imageUrl.isNotEmpty
                          ? Image.network(
                              order.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.shopping_bag_outlined,
                                color: context.textSecondaryColor,
                              ),
                            )
                          : Icon(
                              Icons.shopping_bag_outlined,
                              color: context.textSecondaryColor,
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (order.websiteName != null && !(_user?.isSilverAccount ?? false))
                          Text(
                            order.websiteName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          AppCurrency.format(order.displayTotal),
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
              color: context.borderColor,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
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
