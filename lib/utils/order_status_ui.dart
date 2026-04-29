import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/order_model.dart';

/// Visual style (icon + color) for an order row, aligned with `statue` IDs in the backend.
abstract final class OrderStatusUi {
  OrderStatusUi._();

  static String _norm(String? s) =>
      (s ?? '').toLowerCase().replaceAll(RegExp(r'[\s\n\r]+'), ' ').trim();

  static ({Color color, IconData icon}) resolve(Order order, BuildContext context) {
    final sid = order.status.trim();
    final nm = _norm(order.statusName);

    if (nm.contains('international') && nm.contains('warehouse')) {
      return (color: const Color(0xFF0485db), icon: Icons.warehouse_outlined);
    }

    switch (sid) {
      case '6': // Rejected
        return (color: AppColors.error, icon: Icons.close_rounded);
      case '14': // Canceled
        return (color: AppColors.error, icon: Icons.close_rounded);
      case '16': // Purchased
      case '3': // Approved
      case '-2': // Completed
        return (color: AppColors.success, icon: Icons.check_circle_outline_rounded);
      case '1': // Created
      case '7': // Created recintly
      case '2': // Processing — same treatment as Created
        return (color: AppColors.info, icon: Icons.hourglass_empty_rounded);
      case '13': // Pending — same icon as Created, distinct color
        return (color: const Color(0xFF7a8704), icon: Icons.hourglass_empty_rounded);
      case '20': // Awaiting Payment
        return (color: const Color(0xFF04168c), icon: Icons.payments_outlined);
      case '4': // In Transit
        return (color: const Color(0xFF047f8c), icon: Icons.flight_takeoff_rounded);
      case '-1': // Delivered to Erbil
        return (color: const Color(0xFF035e0c), icon: Icons.inventory_2_outlined);
      case '-3': // Refunded
        return (color: const Color(0xFF4d36ff), icon: Icons.reply_rounded);
      case '19': // Erbil warehouse
        return (color: const Color(0xFF07b056), icon: Icons.warehouse_outlined);
      case '17': // Out for delivery
        return (color: const Color(0xFF2f51fa), icon: Icons.local_shipping_outlined);
      case '18': // Store
        return (color: AppColors.info, icon: Icons.storefront_outlined);
      case '21': // lost
        return (color: context.textSecondaryColor, icon: Icons.help_outline_rounded);
      default:
        break;
    }

    if (nm.contains('reject')) {
      return (color: AppColors.error, icon: Icons.close_rounded);
    }
    if (nm.contains('cancel')) {
      return (color: AppColors.error, icon: Icons.close_rounded);
    }
    if (nm.contains('purchased') || nm.contains('approved') || nm.contains('completed')) {
      return (color: AppColors.success, icon: Icons.check_circle_outline_rounded);
    }
    if (nm.contains('processing') || nm.contains('created')) {
      return (color: AppColors.info, icon: Icons.hourglass_empty_rounded);
    }
    if (nm.contains('pending')) {
      return (color: const Color(0xFF7a8704), icon: Icons.hourglass_empty_rounded);
    }
    if (nm.contains('awaiting payment') || (nm.contains('awaiting') && nm.contains('payment'))) {
      return (color: const Color(0xFF04168c), icon: Icons.payments_outlined);
    }
    if (nm.contains('in transit')) {
      return (color: const Color(0xFF047f8c), icon: Icons.flight_takeoff_rounded);
    }
    if (nm.contains('delivered') && nm.contains('erbil')) {
      return (color: const Color(0xFF035e0c), icon: Icons.inventory_2_outlined);
    }
    if (nm.contains('refunded')) {
      return (color: const Color(0xFF4d36ff), icon: Icons.reply_rounded);
    }
    if (nm.contains('erbil') && nm.contains('warehouse')) {
      return (color: const Color(0xFF07b056), icon: Icons.warehouse_outlined);
    }
    if (nm.contains('out for delivery')) {
      return (color: const Color(0xFF2f51fa), icon: Icons.local_shipping_outlined);
    }

    return (color: context.textSecondaryColor, icon: Icons.info_outline_rounded);
  }
}
