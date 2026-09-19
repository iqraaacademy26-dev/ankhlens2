import 'package:flutter/material.dart';

import '../../domain/entities/glyph_sign.dart';

/// Full sign detail view, shown after a glyph is identified — whether by
/// manual selection (confidence omitted, [wasManuallySelected] = true) or,
/// in a later phase, by the ML classifier (confidence supplied).
class GlyphDetailSheet extends StatelessWidget {
  final GlyphSign sign;
  final double? confidence;
  final bool wasManuallySelected;

  const GlyphDetailSheet({
    super.key,
    required this.sign,
    this.confidence,
    this.wasManuallySelected = false,
  });

  static Future<void> show(
    BuildContext context, {
    required GlyphSign sign,
    double? confidence,
    bool wasManuallySelected = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => GlyphDetailSheet(
        sign: sign,
        confidence: confidence,
        wasManuallySelected: wasManuallySelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  sign.imageAssetPath,
                  height: 96,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_not_supported_outlined,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(sign.gardinerCode, style: theme.textTheme.headlineSmall),
                  const SizedBox(width: 8),
                  _ConfidenceBadge(
                    confidence: confidence,
                    wasManuallySelected: wasManuallySelected,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (sign.transliteration != null)
                _DetailRow(label: 'Transliteration', value: sign.transliteration!),
              if (sign.approxPronunciation != null)
                _DetailRow(
                  label: 'Approx. Pronunciation',
                  value: sign.approxPronunciation!,
                ),
              if (sign.literalMeaning != null)
                _DetailRow(label: 'Literal Meaning', value: sign.literalMeaning!),
              if (sign.culturalMeaning != null)
                _DetailRow(label: 'Cultural Meaning', value: sign.culturalMeaning!),
              if (sign.historicalContext != null)
                _DetailRow(
                  label: 'Historical Context',
                  value: sign.historicalContext!,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double? confidence;
  final bool wasManuallySelected;

  const _ConfidenceBadge({this.confidence, required this.wasManuallySelected});

  @override
  Widget build(BuildContext context) {
    final label = wasManuallySelected
        ? 'Manually selected'
        : confidence != null
            ? '${(confidence! * 100).round()}% match'
            : '';
    if (label.isEmpty) return const SizedBox.shrink();
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
