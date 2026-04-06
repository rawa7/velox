import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/currency.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../generated/app_localizations.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  /// Pass the current user so silver-account restrictions can be applied
  /// without an extra async fetch.
  final User? currentUser;

  const OrderDetailScreen({super.key, required this.order, this.currentUser});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order;
  bool _isLoading = false;

  bool get _isSilver => widget.currentUser?.isSilverAccount ?? false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
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
      case '1':
        return Icons.hourglass_empty;
      case '2':
        return Icons.sync;
      case '3':
        return Icons.check_circle;
      case '4':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<void> _openProductUrl() async {
    if (_order.link.isNotEmpty) {
      final uri = Uri.parse(_order.link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _acceptOrder() async {
    final l10n = AppLocalizations.of(context)!;
    final user = await StorageService.getUser();
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        title: Text(l10n.confirmAccept, style: TextStyle(color: ctx.textPrimaryColor)),
        content: Text(l10n.areYouSureAccept, style: TextStyle(color: ctx.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final result = await ApiService.acceptOrder(
      customerId: user.id,
      orderId: int.parse(_order.id),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] ? l10n.orderAccepted : l10n.errorProcessingOrder)),
          backgroundColor: result['success'] ? AppColors.success : AppColors.error,
        ),
      );
      if (result['success']) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _rejectOrder() async {
    final l10n = AppLocalizations.of(context)!;
    final user = await StorageService.getUser();
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.confirmReject, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.areYouSureReject, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final result = await ApiService.rejectOrder(
      customerId: user.id,
      orderId: int.parse(_order.id),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] ? l10n.orderRejected : l10n.errorProcessingOrder)),
          backgroundColor: result['success'] ? AppColors.success : AppColors.error,
        ),
      );
      if (result['success']) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(_order.status);
    final statusIcon = _getStatusIcon(_order.status);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: Text('${l10n.order} #${_order.serial}', style: TextStyle(color: context.textPrimaryColor)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card (blue for visibility; icon/name keep semantic color)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.25),
                          AppColors.primary.withOpacity(0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(statusIcon, color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.status,
                              style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.9)),
                            ),
                            Text(
                              _order.statusName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Product Image
                  if (_order.imageUrl.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _order.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.image_not_supported, size: 60, color: context.textSecondaryColor),
                          ),
                        ),
                      ),
                    ),

                  // Order Details Card
                  _buildCard(
                    context: context,
                    title: l10n.orderDetails,
                    child: Column(
                      children: [
                        _buildInfoRow(context, l10n.serialNumber, _order.serial),
                        if (_order.websiteName != null && !_isSilver)
                          _buildInfoRow(context, l10n.website, _order.websiteName!),
                        if (_order.size.isNotEmpty)
                          _buildInfoRow(context, l10n.size, _order.size),
                        if (_order.color.isNotEmpty)
                          _buildInfoRow(context, l10n.color, _order.color),
                        _buildInfoRow(context, l10n.qty, _order.qty),
                        if (_order.link.isNotEmpty && !_isSilver) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _openProductUrl,
                            child: Row(
                              children: [
                                const Icon(Icons.link, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.viewDetails,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Details Card
                  _buildCard(
                    context: context,
                    title: l10n.totalPrice,
                    child: Column(
                      children: [
                        _buildPriceRow(context, l10n.itemPrice, AppCurrency.format(double.tryParse(_order.itemPrice) ?? 0)),
                        _buildPriceRow(context, l10n.qty, 'x${_order.qty}'),
                        if (double.tryParse(_order.shippingPrice) != null && double.parse(_order.shippingPrice) > 0)
                          _buildPriceRow(context, l10n.shipping, AppCurrency.format(double.parse(_order.shippingPrice))),
                        if (double.tryParse(_order.cargo) != null && double.parse(_order.cargo) > 0)
                          _buildPriceRow(context, l10n.cargo, AppCurrency.format(double.parse(_order.cargo))),
                        if (double.tryParse(_order.commission) != null && double.parse(_order.commission) > 0)
                          _buildPriceRow(context, l10n.commission, AppCurrency.format(double.parse(_order.commission))),
                        if (double.tryParse(_order.tax) != null && double.parse(_order.tax) > 0)
                          _buildPriceRow(context, l10n.tax, AppCurrency.format(double.parse(_order.tax))),
                        Divider(color: context.borderColor, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.totalPrice,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            Text(
                              AppCurrency.format(_order.displayTotal),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  if (_order.note.isNotEmpty)
                    _buildCard(
                      context: context,
                      title: l10n.note,
                      child: Text(
                        _order.note,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondaryColor,
                          height: 1.5,
                        ),
                      ),
                    ),

                  // Order Info
                  const SizedBox(height: 16),
                  _buildCard(
                    context: context,
                    title: l10n.createdAt,
                    child: Column(
                      children: [
                        _buildInfoRow(context, l10n.orderId, '#${_order.id}'),
                        _buildInfoRow(context, l10n.createdAt, _order.date),
                        _buildInfoRow(context, l10n.paymentStatus, _order.paymentStatus == '1' ? l10n.paid : l10n.waiting),
                      ],
                    ),
                  ),

                  // Action Buttons
                  if (_order.status == '1') ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _rejectOrder,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.close),
                            label: Text(l10n.reject),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _acceptOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: context.textPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(Icons.check, color: context.textPrimaryColor),
                            label: Text(l10n.accept, style: TextStyle(color: context.textPrimaryColor)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required BuildContext context, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.textPrimaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: context.textSecondaryColor)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimaryColor)),
        ],
      ),
    );
  }
}
