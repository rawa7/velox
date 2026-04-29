import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/currency.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../generated/app_localizations.dart';
import '../main.dart';
import '../utils/color_utils.dart';
import '../widgets/language_flag_asset.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'statement_screen.dart';
import 'notifications_screen.dart';
import 'edit_profile_screen.dart';

/// Account tab index in [MainNavigation] (5 tabs: Home, Store, New Order, My Orders, Account).
const int kAccountTabIndexFull = 4;
/// Account tab index when silver / guest layout (4 tabs, no center New Order).
const int kAccountTabIndexSilver = 3;

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    this.selectedTabIndex = 0,
    this.accountTabIndex = kAccountTabIndexFull,
  });

  /// Current bottom-nav index from [MainNavigation] (must update when tabs change).
  final int selectedTabIndex;
  final int accountTabIndex;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  /// WhatsApp chat (+964 750 774 6088)
  static const String _supportWhatsAppE164 = '9647507746088';

  User? _user;
  ProfileData? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didUpdateWidget(AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // IndexedStack keeps this screen alive — reload wallet / available_capacity when user opens Account.
    if (widget.selectedTabIndex == widget.accountTabIndex &&
        oldWidget.selectedTabIndex != widget.accountTabIndex) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      _user = await StorageService.getUser();
      if (_user != null) {
        final result = await ApiService.getProfile(
          customerId: _user!.id,
          mergeIntoUser: _user,
        );
        if (result['success'] == true) {
          _profile = result['data'] as ProfileData;
          final updated = result['user'] as User?;
          if (updated != null) {
            _user = updated;
            await StorageService.saveUser(updated);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(l10n.logout, style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
        content: Text(l10n.areYouSureLogout, style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.8))),
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

    if (confirm == true) {
      await StorageService.clearUser();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = await StorageService.getUser();
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppColors.error),
            const SizedBox(width: 10),
            Text(
              'Delete Account',
              style: TextStyle(
                color: ctx.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: ctx.textSecondaryColor, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    if (user != null) {
      await ApiService.deactivateAccount(customerId: user.id);
    }
    await StorageService.clearUser();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _changeLanguage() async {
    final languages = LanguageService.getSupportedLanguages();
    final currentLocale = await LanguageService.getSelectedLanguage();

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectLanguage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              final isSelected = currentLocale.languageCode == lang.locale.languageCode;
              return ListTile(
                leading: LanguageFlagAsset(assetPath: lang.flagAssetPath),
                title: Text(
                  lang.name,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  lang.nativeName,
                  style: TextStyle(color: context.textSecondaryColor),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () async {
                  await LanguageService.setLanguage(lang.locale.languageCode);
                  if (mounted) {
                    MyApp.setLocale(context, lang.locale);
                    Navigator.pop(context);
                  }
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
        title: Text(l10n.account),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _buildProfileHeader(l10n),
                    const SizedBox(height: 20),

                    // Wallet Section
                    if (_profile != null) ...[
                      _buildWalletCard(l10n),
                      const SizedBox(height: 20),
                    ],

                    // Quick Actions
                    _buildSection(
                      title: l10n.quickLinks,
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: l10n.profile,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          ),
                        ),
                        _buildMenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.accountStatement,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StatementScreen()),
                          ),
                        ),
                        _buildMenuItem(
                          icon: Icons.notifications_outlined,
                          title: l10n.notifications,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          ),
                        ),
                        _buildMenuItem(
                          icon: Icons.lock_outline,
                          title: l10n.changePassword,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Settings Section
                    _buildSection(
                      title: l10n.settings,
                      children: [
                        _buildThemeToggle(),
                        _buildMenuItem(
                          icon: Icons.language_outlined,
                          title: l10n.language,
                          onTap: _changeLanguage,
                        ),
                        _buildMenuItem(
                          icon: Icons.chat_rounded,
                          title: l10n.chatOnWhatsApp,
                          onTap: _openSupportWhatsApp,
                          iconColor: const Color(0xFF25D366),
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: l10n.helpAndSupport,
                          onTap: () => _showHelpDialog(l10n),
                        ),
                        if (_user?.usertype == '1')
                          _buildMenuItem(
                            icon: Icons.delete_forever_outlined,
                            title: 'Delete Account',
                            titleColor: AppColors.error,
                            iconColor: AppColors.error,
                            onTap: _deleteAccount,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.logout),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  void _showCustomerQrDialog(AppLocalizations l10n, String payload) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        // Use [Dialog] instead of [AlertDialog]: [QrImageView] uses LayoutBuilder,
        // which breaks AlertDialog's IntrinsicWidth measurement.
        return Dialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.myQrCode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                QrImageView(
                  data: payload,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  payload,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(AppLocalizations l10n) {
    final userName = _user?.name ?? '';
    final qrPayload = _profile?.qrCodePayload;
    final c1 = parseHexColor(_user?.color1);
    final c2 = parseHexColor(_user?.color2);
    final onCard = parseHexColor(_user?.textColor) ?? Colors.white;
    final List<Color> gradientColors = () {
      if (c1 != null && c2 != null) return [c1, c2];
      if (c1 != null) return [c1, c1.withOpacity(0.88)];
      if (c2 != null) return [c2.withOpacity(0.88), c2];
      return AppColors.primaryGradient;
    }();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: onCard.withOpacity(0.2),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: onCard,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isNotEmpty ? userName : l10n.hello,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: onCard,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.phone ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: onCard.withOpacity(0.85),
                  ),
                ),
                if (_profile?.accountInfo.accountType.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: onCard.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _profile!.accountInfo.localizedAccountType(
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onCard,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (qrPayload != null)
            Material(
              color: onCard.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _showCustomerQrDialog(l10n, qrPayload),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    color: onCard,
                    size: 26,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.wallet,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      l10n.currentBalance,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppCurrency.format(_profile!.accountInfo.currentBalance, context),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: context.borderColor),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWalletStat(
                  l10n.debtLimit,
                  AppCurrency.format(_profile!.accountInfo.debtLimit, context),
                  AppColors.error,
                ),
              ),
              Container(width: 1, height: 40, color: context.borderColor),
              Expanded(
                child: _buildWalletStat(
                  l10n.availableCapacity,
                  AppCurrency.format(_profile!.accountInfo.availableCapacity, context),
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          color: AppColors.primary,
          size: 22,
        ),
        title: Text(
          isDark ? AppLocalizations.of(context)!.darkMode : AppLocalizations.of(context)!.lightMode,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: isDark,
          activeColor: AppColors.primary,
          onChanged: (val) {
            final mode = val ? ThemeMode.dark : ThemeMode.light;
            MyApp.setThemeMode(context, mode);
          },
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: titleColor ?? context.textPrimaryColor,
                  fontWeight: titleColor != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSupportWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$_supportWhatsAppE164');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  void _showHelpDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        final onSurface = Theme.of(ctx).colorScheme.onSurface;
        return AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text(l10n.helpAndSupport, style: TextStyle(color: onSurface)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.helpMessage,
                  style: TextStyle(color: onSurface.withOpacity(0.85)),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openSupportWhatsApp(),
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  label: Text(l10n.chatOnWhatsApp),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }
}
