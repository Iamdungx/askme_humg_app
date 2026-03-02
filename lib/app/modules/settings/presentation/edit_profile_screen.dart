import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/layout/app_bottom_sheet.dart';
import 'package:askme_humg/app/global_widgets/ui/app_avatar.dart';
import 'package:askme_humg/app/global_widgets/ui/app_button.dart';
import 'package:askme_humg/app/global_widgets/ui/profile_name_row.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/profile/presentation/profile_providers.dart';
import 'package:askme_humg/app/modules/settings/presentation/settings_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// BACKLOG-02: Edit Profile screen.
///
/// Allows the authenticated user to update their display name and avatar.
/// Email row shows humgEmail (if verified) or Google email with "not verified"
/// badge + "Verify now" link.
class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  static const int _maxNameLength = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    final user = ref.watch(authStateProvider).asData?.value;

    final nameController = useTextEditingController(
      text: user?.displayName ?? '',
    );
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final pickedAvatarPath = useState<String?>(null);
    final hasChanges = useState(false);

    useEffect(() {
      void listener() {
        final nameChanged =
            nameController.text.trim() != (user?.displayName ?? '');
        hasChanges.value = nameChanged || pickedAvatarPath.value != null;
      }

      nameController.addListener(listener);
      return () => nameController.removeListener(listener);
    }, [nameController, user?.displayName]);

    // Load the last avatar change timestamp to enforce 7-day cooldown.
    final avatarUpdatedAtAsync = user != null
        ? ref.watch(avatarUpdatedAtProvider(user.uid))
        : const AsyncData<DateTime?>(null);
    final lastAvatarChange = avatarUpdatedAtAsync.asData?.value;
    final avatarCooldownUntil =
        lastAvatarChange?.add(const Duration(days: 7));
    final isAvatarOnCooldown = avatarCooldownUntil != null &&
        DateTime.now().isBefore(avatarCooldownUntil);

    final editState = ref.watch(editProfileProvider);
    final isLoading = editState.isLoading;

    ref.listen(editProfileProvider, (_, next) {
      next.when(
        loading: () {},
        error: (e, _) {
          final message = e is AvatarCooldownFailure
              ? _cooldownMessage(l10n, e.nextAllowedAt)
              : l10n.editProfileSaveFailed;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: cs.error,
            ),
          );
        },
        data: (_) {
          // Invalidate cooldown after successful avatar change so the button
          // re-evaluates with the fresh avatarUpdatedAt from Firestore.
          if (user != null) {
            ref.invalidate(avatarUpdatedAtProvider(user.uid));
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.editProfileSuccess)),
          );
          Navigator.of(context).maybePop();
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.editProfileTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: isLoading ? null : () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Form(
        key: formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Hero section ──────────────────────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: _HeroSection(
                        user: user,
                        pickedAvatarPath: pickedAvatarPath.value,
                        isLoading: isLoading,
                        isAvatarOnCooldown: isAvatarOnCooldown,
                        avatarCooldownUntil: avatarCooldownUntil,
                        onPickedPath: (path) {
                          pickedAvatarPath.value = path;
                          hasChanges.value = true;
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Display name field ────────────────────────────────
                    _SectionLabel(text: l10n.editProfileDisplayNameLabel),
                    const SizedBox(height: AppSpacing.sm),
                    _NameField(
                      controller: nameController,
                      isLoading: isLoading,
                      l10n: l10n,
                      maxLength: _maxNameLength,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Email row ─────────────────────────────────────────
                    _SectionLabel(text: l10n.editProfileEmailLabel),
                    const SizedBox(height: AppSpacing.sm),
                    _EmailRow(user: user, l10n: l10n),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // ── Save button pinned at bottom ──────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.xl,
              ),
              child: AppButton(
                label: l10n.editProfileSaveButton,
                variant: AppButtonVariant.primary,
                isLoading: isLoading,
                onPressed: hasChanges.value && !isLoading
                    ? () => _onSave(
                          context,
                          ref,
                          formKey: formKey,
                          userId: user?.uid ?? '',
                          originalName: user?.displayName ?? '',
                          nameController: nameController,
                          pickedAvatarPath: pickedAvatarPath.value,
                        )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave(
    BuildContext context,
    WidgetRef ref, {
    required GlobalKey<FormState> formKey,
    required String userId,
    required String originalName,
    required TextEditingController nameController,
    required String? pickedAvatarPath,
  }) async {
    if (!formKey.currentState!.validate()) return;

    final newName = nameController.text.trim();
    final nameChanged = newName != originalName;

    await ref.read(editProfileProvider.notifier).save(
          userId: userId,
          name: nameChanged ? newName : null,
          avatarLocalPath: pickedAvatarPath,
        );
  }
}

// ---------------------------------------------------------------------------
// Hero section — avatar with glow + name + verified badge (mirrors ProfileHeader)
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.user,
    required this.pickedAvatarPath,
    required this.isLoading,
    required this.isAvatarOnCooldown,
    required this.onPickedPath,
    this.avatarCooldownUntil,
  });

  final AuthUser? user;
  final String? pickedAvatarPath;
  final bool isLoading;
  final bool isAvatarOnCooldown;
  final DateTime? avatarCooldownUntil;
  final ValueChanged<String> onPickedPath;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final cameraDisabled = isLoading || isAvatarOnCooldown;
    final isVerified = user?.isHumgVerified ?? false;
    final displayName = user?.displayName ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Radial glow — same tint as ProfileHeader ring
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.secondary.withValues(alpha: 0.18),
                    cs.surface.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),

            // Avatar + camera button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                _AvatarPreview(
                  currentAvatarUrl: user?.photoUrl,
                  pickedAvatarPath: pickedAvatarPath,
                ),
                GestureDetector(
                  onTap: cameraDisabled
                      ? () => _showCooldownSnackBar(context, l10n, cs)
                      : () => _showAvatarPicker(context, onPickedPath),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cameraDisabled
                          ? cs.onSurface.withValues(alpha: 0.3)
                          : cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                      boxShadow: cameraDisabled
                          ? null
                          : [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(
                      isAvatarOnCooldown
                          ? LucideIcons.lock
                          : LucideIcons.camera,
                      size: 14,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Name + verified badge — shared widget with ProfileHeader
        ProfileNameRow(name: displayName, isHumgVerified: isVerified),

        // Cooldown hint
        if (isAvatarOnCooldown && avatarCooldownUntil != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _CooldownHint(until: avatarCooldownUntil!, l10n: l10n),
        ],
      ],
    );
  }

  void _showCooldownSnackBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    if (!isAvatarOnCooldown || avatarCooldownUntil == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_cooldownMessage(l10n, avatarCooldownUntil!)),
        backgroundColor: cs.error,
      ),
    );
  }

  Future<void> _showAvatarPicker(
    BuildContext context,
    ValueChanged<String> onPicked,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showAppBottomSheet<void>(
      context: context,
      builder: (ctx) => AppBottomSheetBody(
        children: [
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: const Icon(LucideIcons.image),
            title: Text(l10n.editProfilePickFromGallery),
            onTap: () async {
              Navigator.of(ctx).pop();
              if (context.mounted) {
                await _pickImage(context, ImageSource.gallery, onPicked);
              }
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.camera),
            title: Text(l10n.editProfileTakePhoto),
            onTap: () async {
              Navigator.of(ctx).pop();
              if (context.mounted) {
                await _pickImage(context, ImageSource.camera, onPicked);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    ImageSource source,
    ValueChanged<String> onPicked,
  ) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) onPicked(picked.path);
    } on PlatformException catch (e) {
      // Camera unavailable on simulator, or permission permanently denied
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      final cs = Theme.of(context).colorScheme;
      final isUnavailable = e.code == 'channel-error' ||
          e.code == 'camera_access_denied' ||
          e.code == 'photo_access_denied';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUnavailable
                ? l10n.editProfilePickerUnavailable
                : l10n.editProfilePickerPermissionDenied,
          ),
          backgroundColor: cs.error,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Shared cooldown message helper — used by both hint widget and snackbar
// ---------------------------------------------------------------------------

String _cooldownMessage(AppLocalizations l10n, DateTime until) {
  final remaining = until.difference(DateTime.now()).inDays;
  return remaining > 0
      ? l10n.editProfileAvatarCooldown(remaining)
      : l10n.editProfileAvatarCooldownToday;
}

// ---------------------------------------------------------------------------
// Cooldown hint shown below the avatar when the 7-day window is active
// ---------------------------------------------------------------------------

class _CooldownHint extends StatelessWidget {
  const _CooldownHint({required this.until, required this.l10n});

  final DateTime until;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _cooldownMessage(l10n, until);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.clock, size: 12, color: cs.error),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar preview — wraps AppAvatar with edit-screen sizing and ring style
// ---------------------------------------------------------------------------

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.currentAvatarUrl,
    required this.pickedAvatarPath,
  });

  final String? currentAvatarUrl;
  final String? pickedAvatarPath;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // AppAvatar.size already includes the ring border visually, so we
    // pass a slightly larger size here to match the 96px content + 2.5px ring.
    return AppAvatar(
      imageUrl: currentAvatarUrl,
      localFile: pickedAvatarPath != null ? File(pickedAvatarPath!) : null,
      size: 101,
      showRing: true,
      ringColor: cs.secondary,
      ringWidth: 2.5,
    );
  }
}

// ---------------------------------------------------------------------------
// Section label — uppercase small caps style
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Display name text field
// ---------------------------------------------------------------------------

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.isLoading,
    required this.l10n,
    required this.maxLength,
  });

  final TextEditingController controller;
  final bool isLoading;
  final AppLocalizations l10n;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      enabled: !isLoading,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: l10n.editProfileNameHint,
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cs.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        prefixIcon: Icon(LucideIcons.user, size: AppIconSize.md),
        counterStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.45),
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return l10n.editProfileNameEmpty;
        if (trimmed.length > maxLength) return l10n.editProfileNameTooLong;
        return null;
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Email row — verified shows humgEmail, unverified shows Google email
// with "Not verified" chip + "Verify now" link
// ---------------------------------------------------------------------------

class _EmailRow extends StatelessWidget {
  const _EmailRow({required this.user, required this.l10n});

  final AuthUser? user;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bool isVerified = user?.isHumgVerified ?? false;
    final String displayEmail = isVerified
        ? (user?.humgEmail ?? user?.email ?? '')
        : (user?.email ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email card row — intentionally read-only, visually distinct from name field
        Container(
          decoration: BoxDecoration(
            // Dimmer fill + dashed-style border signals non-editable
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isVerified
                  ? cs.outlineVariant.withValues(alpha: 0.5)
                  : cs.error.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                isVerified ? LucideIcons.lock : LucideIcons.mailWarning,
                size: AppIconSize.md,
                color: isVerified
                    ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                    : cs.error.withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  displayEmail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        // Muted text colour signals read-only
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w400,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isVerified) ...[
                const SizedBox(width: AppSpacing.sm),
                _NotVerifiedBadge(label: l10n.editProfileEmailNotVerified),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Helper text row
        if (isVerified)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text(
              l10n.editProfileEmailReadOnlyHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => context.push('/verify-humg'),
              child: Text(
                l10n.editProfileEmailVerifyNow,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Not verified" badge chip
// ---------------------------------------------------------------------------

class _NotVerifiedBadge extends StatelessWidget {
  const _NotVerifiedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.circleAlert,
            size: 11,
            color: cs.error,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: cs.error,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
