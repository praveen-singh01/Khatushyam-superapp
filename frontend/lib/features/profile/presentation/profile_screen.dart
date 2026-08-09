import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
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

  Future<void> _editName() async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(authStateProvider).asData?.value;
    final controller = TextEditingController(text: user?.displayName ?? '');
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
                l10n.profileEditName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: l10n.profileNameHint),
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
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await _persistProfile(displayName: name);
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

  Future<void> _persistProfile({String? displayName, String? photoUrl}) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(displayName: displayName, photoUrl: photoUrl);
      await ref
          .read(authServiceProvider)
          .updateProfile(displayName: displayName, photoUrl: photoUrl);
      ref.invalidate(authStateProvider);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).asData?.value;
    final sub = ref.watch(subscriptionControllerProvider).asData?.value;
    final policiesAsync = ref.watch(legalPoliciesProvider);
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'भक्त';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;
    final isPremium = sub?.isPremium ?? false;
    final days = sub?.daysRemaining;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: () async {
          ref.invalidate(legalPoliciesProvider);
          await ref.read(subscriptionControllerProvider.notifier).refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              l10n.navPremium,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.orangeSoft,
                        backgroundImage:
                            photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                        child:
                            photoUrl == null || photoUrl.isEmpty
                                ? Text(
                                  name.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.orangeDeep,
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
                          color: AppColors.orange,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _busy ? null : _editPhoto,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _busy ? null : _editName,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(l10n.profileEditName),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 14),
            SoftCard(
              onTap: () => context.push(AppRoutes.paywall),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.orangeSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isPremium
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_rounded,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium
                              ? l10n.premiumActive
                              : l10n.premiumInactive,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPremium
                              ? (days != null
                                  ? l10n.profileDaysRemaining(days)
                                  : l10n.premiumActiveHint)
                              : l10n.premiumInactiveHint,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.profilePolicies,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            policiesAsync.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (_, __) => SoftCard(
                    child: Text(l10n.errorGeneric),
                  ),
              data: (policies) {
                return Column(
                  children: [
                    _PolicyTile(
                      title: policies.privacyPolicy.title,
                      onTap: () => _openPolicy(policies.privacyPolicy),
                    ),
                    _PolicyTile(
                      title: policies.deleteAccountPolicy.title,
                      onTap: () => _openPolicy(policies.deleteAccountPolicy),
                    ),
                    _PolicyTile(
                      title: policies.cancellationRefundPolicy.title,
                      onTap:
                          () =>
                              _openPolicy(policies.cancellationRefundPolicy),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed:
                  _busy
                      ? null
                      : () => ref.read(authServiceProvider).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  const _PolicyTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppColors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
