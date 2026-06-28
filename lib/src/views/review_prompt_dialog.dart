import 'package:flutter/material.dart';

import '../l10n/app_help_center_localizations.dart';
import '../models/review_prompt.dart';

/// Shows the review prompt as a modal dialog.
///
/// Mirrors SwiftHelpCenter's ReviewPromptView with:
/// - Star-bubble icon + title + request text
/// - Four action buttons: Never, Hold on, Settings, Review
///
/// Call this after a review prompt manager reports that a prompt is ready.
Future<void> showReviewPromptDialog(
  BuildContext context,
  ReviewPromptManager manager,
  AppHelpCenterLocalizations l10n,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _ReviewPromptDialog(
      manager: manager,
      l10n: l10n,
    ),
  );
}

class _ReviewPromptDialog extends StatelessWidget {
  const _ReviewPromptDialog({
    required this.manager,
    required this.l10n,
  });

  final ReviewPromptManager manager;
  final AppHelpCenterLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star bubble icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  size: 34,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                l10n.text('reviewPrompt.title'),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Request description
              Text(
                l10n.text('reviewPrompt.request'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Action buttons (2x2 grid on wide, 1 column on narrow)
              LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns = constraints.maxWidth >= 340;
                  return GridView.count(
                    crossAxisCount: useTwoColumns ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: useTwoColumns ? 3.2 : 4.5,
                    children: [
                      // Never prompt
                      _ActionButton(
                        icon: Icons.cancel_outlined,
                        label: l10n.text('reviewPrompt.never'),
                        style: _ActionButtonStyle.border,
                        onPressed: () {
                          manager.neverPrompt();
                          Navigator.of(context).pop();
                        },
                      ),
                      // Hold on
                      _ActionButton(
                        icon: Icons.schedule_outlined,
                        label: l10n.text('reviewPrompt.holdOn'),
                        style: _ActionButtonStyle.border,
                        onPressed: () {
                          manager.holdOn();
                          Navigator.of(context).pop();
                        },
                      ),
                      // Go to settings
                      _ActionButton(
                        icon: Icons.settings_outlined,
                        label: l10n.text('reviewPrompt.settings'),
                        style: _ActionButtonStyle.border,
                        onPressed: () {
                          final callback = manager.config.onOpenSettings;
                          if (callback != null) {
                            callback();
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      // Go to review
                      _ActionButton(
                        icon: Icons.star,
                        label: l10n.text('reviewPrompt.review'),
                        style: _ActionButtonStyle.filled,
                        onPressed: () {
                          final callback = manager.config.onReview;
                          if (callback != null) {
                            callback();
                          }
                          // Mark as reviewed after user taps review
                          manager.neverPrompt();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ActionButtonStyle { border, filled }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.style,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final _ActionButtonStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (style == _ActionButtonStyle.filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: FittedBox(child: Text(label)),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: FittedBox(child: Text(label)),
    );
  }
}
