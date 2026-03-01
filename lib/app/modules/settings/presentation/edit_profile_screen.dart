import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// Edit Profile screen — Phase 5.5 / v1.1
///
/// Currently shows a read-only view of the user's name and avatar.
/// Full edit (upload avatar, update name to Firestore) is deferred:
/// TODO(v2): implement avatar upload (Firebase Storage) + name update (Firestore users doc)
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: cs.surfaceContainerHighest,
                    backgroundImage:
                        user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? Icon(LucideIcons.user, size: 40, color: cs.onSurface.withValues(alpha: 0.4))
                        : null,
                  ),
                  // TODO(v2): enable avatar upload — Firebase Storage + Firestore update
                  Tooltip(
                    message: l10n.editProfileChangeAvatar,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primary,
                      child: Icon(LucideIcons.camera, size: 14, color: cs.onPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Name field (read-only placeholder until v2)
              TextFormField(
                initialValue: user?.displayName ?? '',
                decoration: InputDecoration(
                  labelText: l10n.editProfileNameLabel,
                  hintText: l10n.editProfileNameHint,
                  border: const OutlineInputBorder(),
                  // TODO(v2): make editable + save to Firestore
                  enabled: false,
                  suffixIcon: Tooltip(
                    message: 'Coming in next update',
                    child: Icon(LucideIcons.lock, size: 18, color: cs.outline),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Full name editing coming in the next update.',
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Save button — disabled until editable
              // TODO(v2): enable when name field is editable
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(LucideIcons.save),
                label: Text(l10n.editProfileSaveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
