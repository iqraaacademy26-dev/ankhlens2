import 'package:flutter/material.dart';

/// The mandatory disclaimer from architecture doc §5.2. This exact meaning
/// must always be shown before a generated cartouche result — an agency
/// white-label build may translate the copy via `core/branding` overrides,
/// but may not remove or soften the claim itself.
///
/// Simplification note: this requires per-session acknowledgment (tap
/// "I understand" once per time the screen is opened) rather than tracking
/// true first-ever-use via persisted storage. Wiring this to `shared_preferences`
/// to make it a true one-time acknowledgment is a small follow-up, not a
/// structural change.
class ApproximationDisclaimerBanner extends StatelessWidget {
  final VoidCallback onAcknowledge;

  const ApproximationDisclaimerBanner({super.key, required this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Text(
                'Before you continue',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.onErrorContainer),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This is an approximate phonetic rendering of your name using '
            'Egyptian hieroglyphic signs, not a historically authentic '
            'ancient Egyptian translation.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onAcknowledge,
              child: const Text('I understand'),
            ),
          ),
        ],
      ),
    );
  }
}
