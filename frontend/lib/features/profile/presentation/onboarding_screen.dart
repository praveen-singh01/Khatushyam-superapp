import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import 'profile_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String _digitsOnly(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  bool _validPhone(String digits) => RegExp(r'^[6-9]\d{9}$').hasMatch(digits);

  String? _validatePhone(String digits) {
    if (digits.isEmpty) {
      return 'Mobile number zaroori hai';
    }
    if (digits.length < 10) {
      return 'Poora 10-digit number likhein (${digits.length}/10)';
    }
    if (digits.length > 10) {
      return 'Sirf 10 digit likhein — +91 alag se lagaya gaya hai';
    }
    if (!RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Indian mobile 6, 7, 8 ya 9 se shuru hota hai';
    }
    if (!_validPhone(digits)) {
      return 'Yeh number sahi nahi lag raha. Dobara check karein';
    }
    return null;
  }

  String _messageForError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final code = _apiErrorCode(error);

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Server slow hai. Thodi der baad phir try karein';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Internet check karein aur phir try karein';
      }

      switch (code) {
        case 'INVALID_PHONE':
          return 'Yeh mobile number accept nahi hua. Sahi number likhein';
        case 'USER_NOT_FOUND':
          return 'Account nahi mila. Sign out karke phir login karein';
        case 'UNAUTHORIZED':
        case 'UNAUTHENTICATED':
          return 'Session expire ho gayi. Phir se sign in karein';
      }

      if (status == 401 || status == 403) {
        return 'Session expire ho gayi. Phir se sign in karein';
      }
      if (status == 400) {
        return 'Number sahi format mein nahi hai. Dobara check karein';
      }
      if (status != null && status >= 500) {
        return 'Server mein dikkat hai. Thodi der baad try karein';
      }
    }
    return 'Number save nahi ho saka. Phir koshish karein';
  }

  String? _apiErrorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final raw = data['error'] ?? data['message'] ?? data['code'];
      if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    }
    return null;
  }

  Future<void> _submit() async {
    final phone = _digitsOnly(_phoneController.text);
    final validationError = _validatePhone(phone);
    if (validationError != null) {
      setState(() => _error = validationError);
      _phoneFocus.requestFocus();
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final googleName =
          ref.read(authStateProvider).asData?.value?.displayName?.trim();
      await ref.read(appProfileProvider.notifier).completeOnboarding(
        phone: phone,
        displayName:
            (googleName != null && googleName.isNotEmpty) ? googleName : null,
      );
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageForError(error));
      _phoneFocus.requestFocus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authName =
        ref.watch(authStateProvider).asData?.value?.displayName?.trim();
    final greeting =
        (authName != null && authName.isNotEmpty)
            ? 'Jai Shree Shyam, ${authName.split(' ').first}'
            : 'Jai Shree Shyam';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Opacity(
              opacity: 0.18,
              child: Image.asset(
                'assets/images/peacock_feather.png',
                width: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: 80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/applogo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          greeting,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ek chhota sa kadam',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Apna mobile number dein — hum aapse bhakti seva ke liye jude rahenge.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.line),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'MOBILE NUMBER',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.inkMuted,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                enabled: !_busy,
                                autofocus: true,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                onChanged: (_) {
                                  if (_error != null) {
                                    setState(() => _error = null);
                                  }
                                },
                                onSubmitted: (_) => _submit(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppColors.ink,
                                ),
                                decoration: InputDecoration(
                                  hintText: '98XXXXXXXX',
                                  hintStyle: TextStyle(
                                    color: AppColors.inkMuted.withValues(
                                      alpha: 0.55,
                                    ),
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 14,
                                      right: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.phone_android_rounded,
                                          color:
                                              _error != null
                                                  ? AppColors.error
                                                  : AppColors.orange,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '+91',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.ink,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 1,
                                          height: 22,
                                          color: AppColors.line,
                                        ),
                                      ],
                                    ),
                                  ),
                                  filled: true,
                                  fillColor:
                                      _error != null
                                          ? AppColors.error.withValues(
                                            alpha: 0.06,
                                          )
                                          : AppColors.orangeSoft.withValues(
                                            alpha: 0.45,
                                          ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color:
                                          _error != null
                                              ? AppColors.error
                                              : AppColors.line,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color:
                                          _error != null
                                              ? AppColors.error
                                              : AppColors.line,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color:
                                          _error != null
                                              ? AppColors.error
                                              : AppColors.orange,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppColors.error,
                                                fontWeight: FontWeight.w700,
                                                height: 1.35,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child:
                                      _busy
                                          ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            'Continue',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Aapka number sirf app seva ke liye safe rakha jayega.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
