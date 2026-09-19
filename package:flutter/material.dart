import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/agency_profile.dart';
import 'providers/agency_profile_providers.dart';

class AgencyContactScreen extends ConsumerWidget {
  const AgencyContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(agencyProfileStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Guide & Agency')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load contact info: $err')),
        data: (profile) {
          if (profile == null || !profile.hasAnyContactMethod) {
            return const _NoAgencyConfigured();
          }
          return _AgencyContactContent(profile: profile);
        },
      ),
    );
  }
}

class _NoAgencyConfigured extends StatelessWidget {
  const _NoAgencyConfigured();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent_outlined, size: 56),
            SizedBox(height: 12),
            Text(
              "No agency or guide contact is set up for this app yet.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgencyContactContent extends StatelessWidget {
  final AgencyProfileInfo profile;
  const _AgencyContactContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (profile.logoAssetPath != null)
          Center(
            child: Image.asset(
              profile.logoAssetPath!,
              height: 72,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        if (profile.agencyName != null) ...[
          const SizedBox(height: 12),
          Text(
            profile.agencyName!,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        if (profile.guideName != null)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: profile.guidePhotoPath != null
                    ? AssetImage(profile.guidePhotoPath!)
                    : null,
                child: profile.guidePhotoPath == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(profile.guideName!),
              subtitle: const Text('Your licensed guide'),
            ),
          ),
        const SizedBox(height: 16),
        if (profile.contactWhatsapp != null)
          _ContactButton(
            icon: Icons.chat_bubble_outline,
            label: 'Message on WhatsApp',
            onPressed: () => _openWhatsapp(profile.contactWhatsapp!),
          ),
        if (profile.contactPhone != null) ...[
          const SizedBox(height: 12),
          _ContactButton(
            icon: Icons.call_outlined,
            label: 'Call ${profile.contactPhone}',
            onPressed: () => _launchUri(Uri(scheme: 'tel', path: profile.contactPhone)),
          ),
        ],
      ],
    );
  }

  Future<void> _openWhatsapp(String rawNumber) async {
    final digitsOnly = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    await _launchUri(Uri.parse('https://wa.me/$digitsOnly'));
  }

  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
