import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../subscription/presentation/subscription_providers.dart';
import '../data/legal_policies.dart';
import 'policy_screen.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  Future<void> _editProfileDetails() async {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.read(appProfileProvider).asData?.value;
    final auth = ref.read(authStateProvider).asData?.value;
    final nameController = TextEditingController(
      text: profile?.displayName ?? auth?.displayName ?? '',
    );
    final phoneController = TextEditingController(
      text: profile?.phone ?? '',
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Profile badlein',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: l10n.profileNameHint),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Mobile number',
                  prefixText: '+91 ',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.profileSave),
              ),
            ],
          ),
        );
      },
    );
    if (saved != true || !mounted) return;
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    nameController.dispose();
    phoneController.dispose();
    if (name.isEmpty && phone.isEmpty) return;
    await _persistProfile(
      displayName: name.isEmpty ? null : name,
      phone: phone.isEmpty ? null : phone,
    );
  }

  Future<void> _editPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.path.toLowerCase();
      final contentType =
          ext.endsWith('.png')
              ? 'image/png'
              : ext.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      final publicUrl = await ref
          .read(profileRepositoryProvider)
          .uploadProfilePhoto(bytes: bytes, contentType: contentType);
      await _persistProfile(photoUrl: publicUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistProfile({
    String? displayName,
    String? photoUrl,
    String? phone,
  }) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(appProfileProvider.notifier)
          .updateProfile(
            displayName: displayName,
            photoUrl: photoUrl,
            phone: phone,
          );
      if (displayName != null || photoUrl != null) {
        await ref
            .read(authServiceProvider)
            .updateProfile(displayName: displayName, photoUrl: photoUrl);
        ref.invalidate(authStateProvider);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openPolicy(LegalPolicy policy) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PolicyScreen(policy: policy)),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).asData?.value;
    final profile = ref.watch(appProfileProvider).asData?.value;
    final sub = ref.watch(subscriptionControllerProvider).asData?.value;
    final policiesAsync = ref.watch(legalPoliciesProvider);
    final name =
        (profile?.displayName?.trim().isNotEmpty == true
            ? profile!.displayName!
            : (user?.displayName?.trim().isNotEmpty == true
                ? user!.displayName!
                : 'Bhakt'));
    final email = profile?.email ?? user?.email ?? '';
    final phone = profile?.phone;
    final photoUrl = profile?.photoUrl ?? user?.photoUrl;
    final isPremium = sub?.isPremium ?? false;
    final days = sub?.daysRemaining;
    final localeLabel =
        Localizations.localeOf(context).languageCode == 'hi' ? 'हिंदी' : 'English';
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async {
            ref.invalidate(legalPoliciesProvider);
            await ref.read(appProfileProvider.notifier).refresh();
            await ref.read(subscriptionControllerProvider.notifier).refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        elevation: 1,
                        shadowColor: AppColors.ink.withValues(alpha: 0.08),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _toast('सूचनाएँ जल्द यहाँ आएंगी'),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.ink,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileHeroCard(
                name: name,
                email: email,
                phone: phone,
                photoUrl: photoUrl,
                busy: _busy,
                onEditPhoto: _editPhoto,
                onEditProfile: _editProfileDetails,
              ),
              if (_busy) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.orange,
                ),
              ],
              const SizedBox(height: 14),
              _PremiumCard(
                isPremium: isPremium,
                daysRemaining: days,
                onTap: () => context.push(AppRoutes.paywall),
              ),
              const SizedBox(height: 22),
              Text(
                'Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              _SettingsGroup(
                children: [
                  _SettingsRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile Details',
                    onTap: _editProfileDetails,
                  ),
                  _SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () => _toast('सूचना सेटिंग्स जल्द'),
                  ),
                  _SettingsRow(
                    icon: Icons.public_rounded,
                    label: 'Language',
                    trailing: localeLabel,
                    onTap: () => _toast('भाषा बदलना जल्द उपलब्ध होगा'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                l10n.profilePolicies,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              policiesAsync.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.orange),
                      ),
                    ),
                error:
                    (_, __) => _SettingsGroup(
                      children: [
                        _SettingsRow(
                          icon: Icons.error_outline_rounded,
                          label: l10n.errorGeneric,
                          onTap: () => ref.invalidate(legalPoliciesProvider),
                        ),
                      ],
                    ),
                data: (policies) {
                  return _SettingsGroup(
                    children: [
                      _SettingsRow(
                        icon: Icons.description_outlined,
                        label: policies.privacyPolicy.title,
                        onTap: () => _openPolicy(policies.privacyPolicy),
                      ),
                      _SettingsRow(
                        icon: Icons.description_outlined,
                        label: policies.deleteAccountPolicy.title,
                        onTap:
                            () => _openPolicy(policies.deleteAccountPolicy),
                      ),
                      _SettingsRow(
                        icon: Icons.public_rounded,
                        label: policies.cancellationRefundPolicy.title,
                        onTap:
                            () =>
                                _openPolicy(policies.cancellationRefundPolicy),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap:
                      _busy
                          ? null
                          : () => ref.read(authServiceProvider).signOut(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.signOut,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.busy,
    required this.onEditPhoto,
    required this.onEditProfile,
    this.phone,
  });

  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final bool busy;
  final VoidCallback onEditPhoto;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : 'B';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: -6,
            bottom: -6,
            child: Opacity(
              opacity: 0.92,
              child: Image.asset(
                'assets/images/peacock_feather.png',
                width: 88,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            left: -8,
            top: -10,
            child: Icon(
              Icons.brightness_low_rounded,
              size: 64,
              color: AppColors.orange.withValues(alpha: 0.08),
            ),
          ),
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.orangeSoft,
                    backgroundImage:
                        photoUrl != null && photoUrl!.isNotEmpty
                            ? NetworkImage(photoUrl!)
                            : null,
                    child:
                        photoUrl == null || photoUrl!.isEmpty
                            ? Text(
                              initial,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                            )
                            : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: const Color(0xFF5A3A1A),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: busy ? null : onEditPhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (phone != null && phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '+91 $phone',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: busy ? null : onEditProfile,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: AppColors.orange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Profile badlein',
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.isPremium,
    required this.daysRemaining,
    required this.onTap,
  });

  final bool isPremium;
  final int? daysRemaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFF1D6), Color(0xFFFFE0A8), Color(0xFFFFD28A)],
        ),
        border: Border.all(color: const Color(0xFFF0D48A)),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/images/hero_darshan.jpg',
                width: 130,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFF5A3A1A),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Shyam Premium',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5A3A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isPremium
                      ? 'Aapki sadasyata sakriya hai'
                      : 'Abhi muft yojana pe hain',
                  style: TextStyle(
                    color:
                        isPremium
                            ? const Color(0xFF2E8B57)
                            : AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (isPremium && daysRemaining != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Color(0xFF5A3A1A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.profileDaysRemaining(daysRemaining!),
                        style: const TextStyle(
                          color: Color(0xFF5A3A1A),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        child: Text(
                          isPremium
                              ? 'Sadasyata dekhein ›'
                              : 'Premium join karein ›',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.ink, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
