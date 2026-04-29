import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/currency.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../generated/app_localizations.dart';
import '../utils/order_status_ui.dart';
import 'order_detail_screen.dart';

/// Tab index for My Orders in [MainNavigation].
const int kMyOrdersTabIndex = 3;

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({
    super.key,
    this.selectedTabIndex = 0,
    this.myTabIndex = kMyOrdersTabIndex,
    this.silverGuestExperience = false,
  });

  final int selectedTabIndex;
  final int myTabIndex;

  /// Guest browsing with silver-style nav: hide website labels like silver users.
  final bool silverGuestExperience;

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
  /// While accept/reject runs for a row, that order id is busy (spinner).
  String? _busyOrderId;

  bool get _isSilverLike =>
      _user?.isSilverAccount ?? widget.silverGuestExperience;

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

  /// Same rule as [OrderDetailScreen]: accept/reject while processing.
  bool _showAcceptRejectActions(Order order) =>
      order.status == '2' || order.status == '13';

  Future<void> _acceptOrderInList(Order order) async {
    final l10n = AppLocalizations.of(context)!;
    final user = _user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        title: Text(l10n.confirmAccept, style: TextStyle(color: ctx.textPrimaryColor)),
        content: Text(l10n.areYouSureAccept, style: TextStyle(color: ctx.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _busyOrderId = order.id);
    final result = await ApiService.acceptOrder(
      customerId: user.id,
      orderId: int.parse(order.id),
    );
    if (!mounted) return;
    setState(() => _busyOrderId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              (result['success'] == true ? l10n.orderAccepted : l10n.errorProcessingOrder),
        ),
        backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
      ),
    );
    if (result['success'] == true) {
      await _loadData();
    }
  }

  Future<void> _rejectOrderInList(Order order) async {
    final l10n = AppLocalizations.of(context)!;
    final user = _user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        title: Text(l10n.confirmReject, style: TextStyle(color: ctx.textPrimaryColor)),
        content: Text(l10n.areYouSureReject, style: TextStyle(color: ctx.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _busyOrderId = order.id);
    final result = await ApiService.rejectOrder(
      customerId: user.id,
      orderId: int.parse(order.id),
    );
    if (!mounted) return;
    setState(() => _busyOrderId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              (result['success'] == true ? l10n.orderRejected : l10n.errorProcessingOrder),
        ),
        backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
      ),
    );
    if (result['success'] == true) {
      await _loadData();
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
                        ..._statuses
                            .where((status) => status.count > 0)
                            .map((status) => _buildFilterChip(
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

  Widget _buildOrderThumbnail(BuildContext context, Order order) {
    final imageUrl = order.hasSubItems && order.subItems.isNotEmpty
        ? order.subItems.first.image
        : order.imageUrl;
    final isNetwork = imageUrl.startsWith('http');
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isNetwork && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, color: context.textSecondaryColor),
              )
            : Icon(Icons.shopping_bag_outlined, color: context.textSecondaryColor),
      ),
    );
  }

  Widget _buildThumbnailStrip(BuildContext context, Order order) {
    final items = order.subItems.take(5).toList();
    final extra = order.subItems.length - 5;
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          ...items.map((item) {
            final isNetwork = item.image.startsWith('http');
            return Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: isNetwork
                    ? Image.network(item.image, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image, size: 16, color: context.textSecondaryColor))
                    : Icon(Icons.image, size: 16, color: context.textSecondaryColor),
              ),
            );
          }),
          if (extra > 0)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '+$extra',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ),
        ],
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
    final statusVisual = OrderStatusUi.resolve(order, context);
    final statusColor = statusVisual.color;
    final statusIcon = statusVisual.icon;
    final showActions = _showAcceptRejectActions(order);
    final busy = _busyOrderId == order.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable header → order detail
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(
                    order: order,
                    currentUser: _user,
                    silverGuestExperience: widget.silverGuestExperience,
                  ),
                ),
              );
              _loadData();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderThumbnail(context, order),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n.orderId} #${order.id}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${order.totalQty} items',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (order.websiteName != null && order.websiteName!.isNotEmpty && !_isSilverLike)
                          Text(
                            order.websiteName!,
                            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                          ),
                        const SizedBox(height: 6),
                        if (order.hasSubItems && order.subItems.length > 1)
                          _buildThumbnailStrip(context, order),
                        const SizedBox(height: 6),
                        order.status == '1'
                            ? Text(
                                l10n.pendingPrice,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                AppCurrency.format(order.displayTotal, context),
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
          ),
          Container(height: 1, color: context.borderColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.statusName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showActions) ...[
                      if (busy)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () => _rejectOrderInList(order),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(l10n.reject, style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _acceptOrderInList(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: context.textPrimaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(l10n.accept, style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
                            ),
                          ],
                        ),
                    ] else
                      Text(
                        order.date,
                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                      ),
                  ],
                ),
                if (showActions) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      order.date,
                      style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
