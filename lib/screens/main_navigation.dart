import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../generated/app_localizations.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'store_screen.dart';
import 'add_order_screen.dart';
import 'my_orders_screen.dart';
import 'account_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await StorageService.getUser();
    if (mounted) setState(() => _user = user);
  }

  bool get _isSilver => _user?.isSilverAccount ?? false;

  // For silver: 0=Home, 1=Store, 2=MyOrders, 3=Account
  // For others: 0=Home, 1=Store, 2=NewOrder, 3=MyOrders, 4=Account
  int get _myOrdersTabIndex => _isSilver ? 2 : 3;

  List<Widget> _buildScreens() {
    if (_isSilver) {
      return [
        const HomeScreen(),
        const StoreScreen(),
        MyOrdersScreen(selectedTabIndex: _currentIndex, myTabIndex: _myOrdersTabIndex),
        const AccountScreen(),
      ];
    }
    return [
      HomeScreen(
        onNavigateToNewOrder: () => setState(() => _currentIndex = 2),
      ),
      const StoreScreen(),
      const AddOrderScreen(),
      MyOrdersScreen(selectedTabIndex: _currentIndex, myTabIndex: _myOrdersTabIndex),
      const AccountScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surface = context.surfaceColor;
    final border = context.borderColor;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            top: BorderSide(color: border, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _isSilver
                  ? _buildSilverNavItems(l10n)
                  : _buildFullNavItems(l10n),
            ),
          ),
        ),
      ),
    );
  }

  /// Silver: Home · Store · My Orders · Account  (no New Order tab)
  List<Widget> _buildSilverNavItems(AppLocalizations l10n) => [
        _buildNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: l10n.home, index: 0),
        _buildNavItem(icon: Icons.store_outlined, activeIcon: Icons.store, label: l10n.store, index: 1),
        _buildNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: l10n.myOrders, index: 2),
        _buildNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: l10n.account, index: 3),
      ];

  /// Standard: Home · Store · New Order (center) · My Orders · Account
  List<Widget> _buildFullNavItems(AppLocalizations l10n) => [
        _buildNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: l10n.home, index: 0),
        _buildNavItem(icon: Icons.store_outlined, activeIcon: Icons.store, label: l10n.store, index: 1),
        _buildNavItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: l10n.newOrder, index: 2, isCenter: true),
        _buildNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: l10n.myOrders, index: 3),
        _buildNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: l10n.account, index: 4),
      ];

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    bool isCenter = false,
  }) {
    final isSelected = _currentIndex == index;

    if (isCenter) {
      return GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: AppColors.primaryGradient)
                : null,
            color: isSelected ? null : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 22,
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
