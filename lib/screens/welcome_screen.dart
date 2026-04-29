import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../generated/app_localizations.dart';
import '../main.dart';
import '../services/language_service.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'main_navigation.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _showLanguageDialog(BuildContext context) {
    final languages = LanguageService.getSupportedLanguages();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : LightColors.surface;
    final borderColor = isDark ? AppColors.border : LightColors.border;
    final textPrimary = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : LightColors.textSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Material(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(ctx)!.selectLanguage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              ...languages.map(
                (lang) => ListTile(
                  tileColor: surfaceColor,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: AppColors.primary),
                  ),
                  title: Text(
                    lang.nativeName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    lang.name,
                    style: TextStyle(color: textSecondary),
                  ),
                  onTap: () async {
                    await LanguageService.setLanguage(lang.locale.languageCode);
                    if (context.mounted) {
                      MyApp.setLocale(context, lang.locale);
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : LightColors.background;
    final textSecondary =
        isDark ? AppColors.textSecondary : LightColors.textSecondary;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // Language button top-right
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: IconButton(
                      onPressed: () => _showLanguageDialog(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: const Icon(
                          Icons.language,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                LayoutBuilder(
                  builder: (context, _) {
                    final w = MediaQuery.sizeOf(context).width;
                    final logoSize = (w * 0.58).clamp(178.0, 255.0);
                    return Column(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.local_shipping_rounded,
                            size: logoSize * 0.72,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: logoSize * 0.1),
                        Text(
                          l10n.welcomeToVelox,
                          style: TextStyle(
                            fontSize: 16,
                            color: textSecondary,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),

                const Spacer(flex: 3),

                // "Do you have an account?" label
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.help_outline,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.haveAccount,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // YES – Sign In
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(
                      l10n.iHaveAnAccount,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // NO – Create account
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SignupScreen()),
                    ),
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(
                      l10n.createNewAccount,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Skip account — same silver-style experience as browsing without login
                TextButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MainNavigation(guestAsSilver: true),
                    ),
                  ),
                  icon: Icon(Icons.skip_next_rounded, color: textSecondary),
                  label: Text(
                    l10n.skipAccount,
                    style:
                        TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
