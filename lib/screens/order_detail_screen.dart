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
import '../utils/order_status_ui.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  /// Pass the current user so silver-account restrictions can be applied
  /// without an extra async fetch.
  final User? currentUser;

  /// When browsing as guest with silver-style UI, apply the same link/website
  /// hiding as a silver account.
  final bool silverGuestExperience;

  const OrderDetailScreen({
    super.key,
    required this.order,
    this.currentUser,
    this.silverGuestExperience = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order;
  bool _isLoading = false;

  bool get _isSilver =>
      widget.currentUser?.isSilverAccount ?? widget.silverGuestExperience;

  /// When [Order.tax] is non-zero, show 6% of (item price + cargo) in listing currency (not raw IQD).
  double _taxSixPercentAmount() {
    final item = double.tryParse(_order.itemPrice) ?? 0;
    final cargo = double.tryParse(_order.cargo) ?? 0;
    return 0.06 * (item + cargo);
  }

  @override
  void initState() {
    super.initState();
    _order = widget.order;
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
    final statusVisual = OrderStatusUi.resolve(_order, context);

    final showAcceptReject = _order.status == '2' || _order.status == '13';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: Text('${l10n.orderId} #${_order.id}', style: TextStyle(color: context.textPrimaryColor)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Status Card — colors/icons match orders list ([OrderStatusUi]).
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusVisual.color.withOpacity(0.22),
                          statusVisual.color.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusVisual.color.withOpacity(0.45)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusVisual.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(statusVisual.icon, color: statusVisual.color, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.status,
                              style: TextStyle(fontSize: 12, color: statusVisual.color.withOpacity(0.9)),
                            ),
                            Text(
                              _order.statusName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: statusVisual.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Product Image — only show for non-sub-item orders
                  if (_order.imageUrl.isNotEmpty && !_order.hasSubItems)
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
                        _buildInfoRow(context, l10n.orderId, _order.id),
                        if (_order.websiteName != null && !_isSilver)
                          _buildInfoRow(context, l10n.website, _order.websiteName!),
                        if (!_order.hasSubItems && _order.size.isNotEmpty)
                          _buildInfoRow(context, l10n.size, _order.size),
                        if (!_order.hasSubItems && _order.color.isNotEmpty)
                          _buildInfoRow(context, l10n.color, _order.color),
                        if (!_order.hasSubItems)
                          _buildInfoRow(context, l10n.qty, '${_order.totalQty}'),
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
                        if (_order.hasSubItems) ...[
                          _buildPriceRow(context, l10n.totalItems, l10n.orderItemsSectionTitle(_order.totalQty)),
                        ] else ...[
                          _buildPriceRow(context, l10n.qty, 'x${_order.totalQty}'),
                        ],
                        // Item price in original currency (dollars) — hidden for Created orders
                        if (_order.status != '1')
                          _buildPriceRow(
                            context,
                            l10n.itemPrice,
                            '${_order.currencySymbol ?? '\$'}${(double.tryParse(_order.itemPrice) ?? 0).toStringAsFixed(2)}',
                          ),
                        if (double.tryParse(_order.cargo) != null && double.parse(_order.cargo) > 0)
                          _buildPriceRow(
                            context,
                            l10n.cargo,
                            '${_order.currencySymbol ?? '\$'}${(double.tryParse(_order.cargo) ?? 0).toStringAsFixed(2)}',
                          ),
                        if (double.tryParse(_order.tax) != null && double.parse(_order.tax) > 0)
                          _buildPriceRow(
                            context,
                            l10n.taxWithPercentLabel,
                            '${_order.currencySymbol ?? '\$'}${_taxSixPercentAmount().toStringAsFixed(2)}',
                          ),
                        if (double.tryParse(_order.shippingPrice) != null &&
                            double.parse(_order.shippingPrice) > 0)
                          _buildPriceRow(
                            context,
                            l10n.shipping,
                            '\$${(double.tryParse(_order.shippingPrice) ?? 0).toStringAsFixed(2)}',
                          ),
                        if (double.tryParse(_order.commission) != null && double.parse(_order.commission) > 0)
                          _buildPriceRow(context, l10n.commission, AppCurrency.format(double.parse(_order.commission), context)),
                        ..._buildExchangeRateRows(context, l10n),
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
                            _order.status == '1'
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.textSecondary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      l10n.pendingPrice,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: context.textSecondaryColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                : Text(
                                    AppCurrency.format(_order.displayTotal, context),
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

                  // Sub-Items
                  if (_order.subItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      context: context,
                      title: l10n.orderItemsSectionTitle(_order.totalQty),
                      child: Column(
                        children: _order.subItems.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          return Column(
                            children: [
                              if (i > 0) Divider(color: context.borderColor, height: 16),
                              _buildSubItemRow(
                                context,
                                l10n,
                                item,
                                hidePrice: _order.status == '1',
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],

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
                        _buildInfoRow(
                          context,
                          l10n.createdAt,
                          _order.date.isNotEmpty ? _order.date : _order.createdAt,
                        ),
                        _buildInfoRow(context, l10n.paymentStatus, _order.paymentStatus == '1' ? l10n.paid : l10n.waiting),
                      ],
                    ),
                  ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (showAcceptReject)
                  Material(
                    elevation: 12,
                    shadowColor: Colors.black26,
                    color: context.surfaceColor,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Row(
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
                            const SizedBox(width: 12),
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
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  /// IQD side of the rate, digits only (e.g. `1400` / `1400.50`) for compact `$1=1400IQD` display.
  String _formatRatePlain(String rate) {
    final r = double.tryParse(rate) ?? 1;
    if (r.truncateToDouble() == r) return r.toInt().toString();
    return r.toStringAsFixed(2);
  }

  /// Item currency → USD and USD → IQD, last lines before the total (uses [currency_convert] + [rate] from API).
  List<Widget> _buildExchangeRateRows(BuildContext context, AppLocalizations l10n) {
    if (_order.status == '1') {
      return const [];
    }
    final r = double.tryParse(_order.rate);
    final cc = double.tryParse(_order.currencyConvert);
    if (r == null || r <= 0 || cc == null || cc <= 0) {
      return const [];
    }
    final sym = _order.currencySymbol ?? '\$';
    final rows = <Widget>[];
    // `currencyconvert`: units of item currency per 1 USD → 1 item unit = 1/cc USD
    if ((cc - 1.0).abs() > 0.0001) {
      rows.add(
        _buildPriceRow(
          context,
          l10n.exchangeRateItemToUsd,
          '${sym}1 = \$${(1 / cc).toStringAsFixed(4)}',
        ),
      );
    }
    // `rate`: IQD per 1 item-currency unit → IQD per 1 USD = rate × (item units per USD)
    final usdToIqd = r * cc;
    rows.add(
      _buildPriceRow(
        context,
        l10n.exchangeRateUsdToIqd,
        '\$1 = ${_formatRatePlain(usdToIqd.toString())} IQD',
      ),
    );
    return rows;
  }

  Widget _buildSubItemRow(
    BuildContext context,
    AppLocalizations l10n,
    SubItem item, {
    bool hidePrice = false,
  }) {
    final isImageUrl = item.image.startsWith('http');
    // qty 0: show localized "This item is out of stock." unless staff set a custom line_note
    const defaultOosNoteEn = 'This item is out of stock.';
    final String? noteTrim = item.lineNote?.trim();
    final String? stockMessage = item.qty == 0
        ? ((noteTrim == null || noteTrim.isEmpty || noteTrim == defaultOosNoteEn)
            ? l10n.outOfStock
            : noteTrim)
        : (noteTrim != null && noteTrim.isNotEmpty ? noteTrim : null);
    final qtyColor = item.qty == 0 ? AppColors.error : AppColors.primary;
    final qtyBg = item.qty == 0 ? AppColors.error.withOpacity(0.12) : AppColors.primary.withOpacity(0.1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isImageUrl
                ? Image.network(
                    item.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported_outlined,
                      color: context.textSecondaryColor,
                      size: 28,
                    ),
                  )
                : Icon(Icons.shopping_bag_outlined, color: context.textSecondaryColor, size: 28),
          ),
        ),
        const SizedBox(width: 12),
        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimaryColor,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.size.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.size,
                        style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: qtyBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'x${item.qty}',
                      style: TextStyle(fontSize: 11, color: qtyColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (stockMessage != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFB74D)),
                        ),
                        child: Text(
                          stockMessage,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: Colors.brown.shade800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (!hidePrice) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)} each',
                      style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                    ),
                    Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: item.qty == 0 ? context.textSecondaryColor : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
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
