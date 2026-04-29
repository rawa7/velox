import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../data/cities_data.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../generated/app_localizations.dart';
import '../models/user_model.dart';
import '../utils/country_codes.dart';
import '../utils/post_auth_navigation.dart';

enum _Step { phone, otp, profile }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  _Step _step = _Step.phone;

  // Step 1 – phone
  final _phoneController = TextEditingController();
  CountryCode _selectedCountry = iraqCountryCode;
  String _normalizedPhone = '';
  String _generatedOtp = '';

  // Step 2 – OTP (one field per digit)
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  /// Avoids re-entrant [onChanged] when filling several boxes (e.g. paste).
  bool _otpBulkFilling = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  // Step 3 – profile
  final _nameController = TextEditingController();
  int? _selectedCityId;
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _nameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _generateOtp() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  /// Builds the full international number for OTPIQ (no "+" prefix).
  String _buildNormalizedPhone(String localNumber) {
    // Strip spaces, dashes, parens
    localNumber =
        localNumber.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Remove leading 0 (common local convention: 0750… → 750…)
    if (localNumber.startsWith('0')) {
      localNumber = localNumber.substring(1);
    }
    return '${_selectedCountry.rawCode}$localNumber';
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  // ─── Country picker ────────────────────────────────────────────────────────

  void _openCountryPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : LightColors.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final borderColor = isDark ? AppColors.border : LightColors.border;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(
        selected: _selectedCountry,
        surfaceColor: surfaceColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        borderColor: borderColor,
        onSelected: (c) {
          setState(() => _selectedCountry = c);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ─── Step 1: Send OTP ──────────────────────────────────────────────────────

  Future<void> _sendOtp({bool resend = false}) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage =
          AppLocalizations.of(context)!.pleaseEnterYourPhoneNumber);
      return;
    }

    _normalizedPhone = _buildNormalizedPhone(phone);
    _generatedOtp = _generateOtp();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;
    final check = await ApiService.checkPhoneAvailable(_normalizedPhone);
    if (!mounted) return;

    if (check['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage = check['message']?.toString() ?? l10n.pleaseCheckConnection;
      });
      return;
    }
    if (check['available'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.phoneAlreadyRegistered;
      });
      return;
    }

    final result = await ApiService.sendOtp(
      phoneNumber: _normalizedPhone,
      verificationCode: _generatedOtp,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _isLoading = false;
        if (!resend) _step = _Step.otp;
        for (final c in _otpControllers) {
          c.clear();
        }
      });
      _startResendCountdown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _otpFocusNodes[0].requestFocus();
      });
      if (resend && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.otpSentSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'];
      });
    }
  }

  // ─── Step 2: Verify OTP ────────────────────────────────────────────────────

  void _verifyOtp() {
    final l10n = AppLocalizations.of(context)!;
    final entered = _otpControllers.map((c) => c.text).join();
    if (entered.length < 6) {
      setState(() => _errorMessage = l10n.enterVerificationCode);
      return;
    }
    if (entered == _generatedOtp) {
      setState(() {
        _step = _Step.profile;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = l10n.invalidOtpCode);
    }
  }

  // ─── Step 3: Create account ────────────────────────────────────────────────

  Future<void> _createAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text;

    if (name.length < 2) {
      setState(() => _errorMessage = l10n.nameMustBeAtLeast2Characters);
      return;
    }
    if (_selectedCityId == null) {
      setState(() => _errorMessage = l10n.pleaseSelectCity);
      return;
    }
    if (address.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterYourAddress);
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = l10n.passwordMustBeAtLeast6Characters);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Store phone in full international form for the backend
    final phone = '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

    final signupResult = await ApiService.signup(
      name: name,
      phone: phone,
      address: address,
      password: password,
      cityId: _selectedCityId!,
    );

    if (!mounted) return;

    if (signupResult['success'] == true) {
      final loginResult = await ApiService.login(phone, password);
      if (!mounted) return;

      if (loginResult['success'] == true) {
        final user = loginResult['user'] as User;
        await StorageService.saveUser(user);
        if (!mounted) return;
        await PostAuthNavigation.replaceStackFromSignup(context, user);
      } else {
        setState(() => _isLoading = false);
        _showAccountCreatedDialog();
      }
    } else {
      final msg = signupResult['message'] ?? '';
      setState(() {
        _isLoading = false;
        _errorMessage = msg.toLowerCase().contains('already')
            ? l10n.phoneAlreadyRegistered
            : msg;
      });
    }
  }

  void _showAccountCreatedDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.accountCreated,
                style: TextStyle(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        content: Text(l10n.accountCreatedSuccessMessage,
            style: TextStyle(color: context.textSecondaryColor)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _goBack() {
    if (_step == _Step.otp) {
      setState(() {
        _step = _Step.phone;
        _errorMessage = null;
        _countdownTimer?.cancel();
        for (final c in _otpControllers) {
          c.clear();
        }
      });
    } else if (_step == _Step.profile) {
      setState(() {
        _step = _Step.otp;
        _errorMessage = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  String _stepLabel(AppLocalizations l10n) {
    switch (_step) {
      case _Step.phone:
        return l10n.step1of3;
      case _Step.otp:
        return l10n.step2of3;
      case _Step.profile:
        return l10n.step3of3;
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimaryColor),
          onPressed: _goBack,
        ),
        title: Text(
          _stepLabel(l10n),
          style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _buildStep(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(AppLocalizations l10n) {
    switch (_step) {
      case _Step.phone:
        return _buildPhoneStep(l10n);
      case _Step.otp:
        return _buildOtpStep(l10n);
      case _Step.profile:
        return _buildProfileStep(l10n);
    }
  }

  // ── Step 1 ─────────────────────────────────────────────────────────────────

  Widget _buildPhoneStep(AppLocalizations l10n) {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _gradientTitle(l10n.createNewAccount),
        const SizedBox(height: 8),
        Text(l10n.enterPhoneToRegister,
            style:
                TextStyle(fontSize: 15, color: context.textSecondaryColor)),
        const SizedBox(height: 32),
        if (_errorMessage != null) _errorBanner(_errorMessage!),
        _fieldLabel(l10n.phone),
        const SizedBox(height: 8),
        // Phone field with country picker prefix
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              // Country code button
              GestureDetector(
                onTap: _openCountryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: context.borderColor),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedCountry.flag,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry.dialCode,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: context.textSecondaryColor),
                    ],
                  ),
                ),
              ),
              // Number input
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: l10n.enterYourPhoneNumber,
                    hintStyle:
                        TextStyle(color: context.textSecondaryColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(l10n.whatsappCode,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 36),
        _primaryButton(
          label: l10n.sendVerificationCode,
          icon: Icons.send_rounded,
          onPressed: _isLoading ? null : () => _sendOtp(),
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // ── Step 2 ─────────────────────────────────────────────────────────────────

  Widget _buildOtpStep(AppLocalizations l10n) {
    final displayPhone =
        '${_selectedCountry.dialCode} ${_phoneController.text.trim()}';
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _gradientTitle(l10n.verifyYourPhone),
        const SizedBox(height: 8),
        Text(
          l10n.codeSentTo(displayPhone),
          style: TextStyle(fontSize: 15, color: context.textSecondaryColor),
        ),
        const SizedBox(height: 32),
        if (_errorMessage != null) _errorBanner(_errorMessage!),
        _fieldLabel(l10n.verificationCode),
        const SizedBox(height: 8),
        _buildOtpBoxes(),
        const SizedBox(height: 12),
        Center(
          child: _resendCountdown > 0
              ? Text(
                  l10n.resendIn(_resendCountdown),
                  style: TextStyle(
                      fontSize: 13, color: context.textSecondaryColor),
                )
              : TextButton(
                  onPressed: _isLoading ? null : () => _sendOtp(resend: true),
                  child: Text(l10n.resendCode,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
        ),
        const SizedBox(height: 32),
        _primaryButton(
          label: l10n.verify,
          icon: Icons.check_circle_outline,
          onPressed: _isLoading ? null : _verifyOtp,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // ── Step 3 ─────────────────────────────────────────────────────────────────

  Widget _buildProfileStep(AppLocalizations l10n) {
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _gradientTitle(l10n.completeYourProfile),
        const SizedBox(height: 8),
        Text(l10n.almostThere,
            style:
                TextStyle(fontSize: 15, color: context.textSecondaryColor)),
        const SizedBox(height: 32),
        if (_errorMessage != null) _errorBanner(_errorMessage!),

        _fieldLabel(l10n.fullName),
        const SizedBox(height: 8),
        _buildInput(
          controller: _nameController,
          hint: l10n.enterYourFullName,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),

        _fieldLabel(l10n.city),
        const SizedBox(height: 8),
        _buildCityDropdown(l10n),
        const SizedBox(height: 16),

        _fieldLabel(l10n.address),
        const SizedBox(height: 8),
        _buildInput(
          controller: _addressController,
          hint: l10n.enterYourAddress,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),

        _fieldLabel(l10n.password),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: context.textPrimaryColor),
            decoration: InputDecoration(
              hintText: l10n.enterYourPassword,
              hintStyle: TextStyle(color: context.textSecondaryColor),
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: context.textSecondaryColor),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),

        const SizedBox(height: 36),
        _primaryButton(
          label: l10n.createNewAccount,
          icon: Icons.person_add_rounded,
          onPressed: _isLoading ? null : _createAccount,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── Shared widgets ────────────────────────────────────────────────────────

  Widget _gradientTitle(String text) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          const LinearGradient(colors: AppColors.primaryGradient)
              .createShader(bounds),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textSecondaryColor));
  }

  Widget _buildCityDropdown(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.location_city_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                hint: Text(
                  l10n.selectCity,
                  style: TextStyle(color: context.textSecondaryColor),
                ),
                value: _selectedCityId,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: context.textSecondaryColor),
                dropdownColor: context.surfaceColor,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 16,
                ),
                items: kSignupCities
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCityId = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      children: [
        for (int i = 0; i < 6; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildOtpDigitField(i)),
        ],
      ],
    );
  }

  void _applyOtpDigitsFrom(int startIndex, String digits) {
    final d = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return;
    _otpBulkFilling = true;
    var di = 0;
    var i = startIndex;
    while (di < d.length && i < 6) {
      _otpControllers[i].text = d[di];
      _otpControllers[i].selection = const TextSelection.collapsed(offset: 1);
      di++;
      i++;
    }
    _otpBulkFilling = false;
    if (i < 6) {
      _otpFocusNodes[i].requestFocus();
    } else {
      _otpFocusNodes[5].requestFocus();
      FocusScope.of(context).unfocus();
    }
    setState(() {});
  }

  void _onOtpDigitChanged(int index, String value) {
    if (_otpBulkFilling) return;
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 1) {
      _applyOtpDigitsFrom(index, digitsOnly);
      return;
    }
    if (digitsOnly.isEmpty) {
      _otpControllers[index].clear();
      setState(() {});
      return;
    }
    if (_otpControllers[index].text != digitsOnly) {
      _otpControllers[index].text = digitsOnly;
    }
    _otpControllers[index].selection = const TextSelection.collapsed(offset: 1);
    if (index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
    setState(() {});
  }

  Widget _buildOtpDigitField(int index) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_otpControllers[index].text.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
            final prev = _otpControllers[index - 1].text;
            if (prev.isNotEmpty) {
              _otpControllers[index - 1].text =
                  prev.substring(0, prev.length - 1);
              _otpControllers[index - 1].selection =
                  TextSelection.collapsed(offset: _otpControllers[index - 1].text.length);
            }
            setState(() {});
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: context.textPrimaryColor,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          filled: true,
          fillColor: context.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          counterText: '',
        ),
        onChanged: (v) => _onOtpDigitChanged(index, v),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextAlign textAlign = TextAlign.start,
    double letterSpacing = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlign: textAlign,
        style: TextStyle(
            color: context.textPrimaryColor, letterSpacing: letterSpacing),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: context.textSecondaryColor, letterSpacing: 0),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}

// ─── Country Picker Bottom Sheet ─────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final CountryCode selected;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final ValueChanged<CountryCode> onSelected;

  const _CountryPickerSheet({
    required this.selected,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.onSelected,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<CountryCode> _filtered = allCountryCodes;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? allCountryCodes
          : allCountryCodes.where((c) {
              return c.name.toLowerCase().contains(q) ||
                  c.dialCode.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: widget.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select Country',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: widget.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.borderColor),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: TextStyle(color: widget.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search country or code…',
                  hintStyle: TextStyle(color: widget.textSecondary),
                  prefixIcon: Icon(Icons.search,
                      color: AppColors.primary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final isSelected = c.isoCode == widget.selected.isoCode;
                return ListTile(
                  tileColor: isSelected
                      ? AppColors.primary.withOpacity(0.08)
                      : null,
                  leading: Text(c.flag,
                      style: const TextStyle(fontSize: 26)),
                  title: Text(c.name,
                      style: TextStyle(
                          color: widget.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal)),
                  trailing: Text(
                    c.dialCode,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : widget.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => widget.onSelected(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
