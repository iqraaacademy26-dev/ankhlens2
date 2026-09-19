import 'package:flutter/material.dart';

import '../../domain/entities/glyph_sign.dart';

class SignGridTile extends StatelessWidget {
  final GlyphSign sign;
  final VoidCallback onTap;

  const SignGridTile({super.key, required this.sign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                sign.imageAssetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported_outlined,
                  color: theme.disabledColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sign.gardinerCode,
              style: theme.textTheme.labelMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
