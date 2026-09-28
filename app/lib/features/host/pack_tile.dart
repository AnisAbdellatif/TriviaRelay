import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';

/// A pack's picture, square and rounded, or a quiet placeholder for a pack
/// without one (Sporcle's catalog has plenty).
///
/// Sporcle's image hosts send no CORS headers, so the web build can't fetch
/// the bytes; it shows them as plain `<img>` elements instead. Android fetches
/// them as usual, decoded at the size they're shown.
class PackImage extends StatelessWidget {
  const PackImage({super.key, required this.url, this.size = 64});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    final placeholder = ColoredBox(
      color: FzColors.bgGlow,
      child: Center(
        child: Icon(
          Icons.quiz_outlined,
          color: FzColors.faint,
          size: size * .42,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .2),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: kIsWeb
                    ? null
                    : (size * MediaQuery.devicePixelRatioOf(context)).round(),
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (_, child, frame, synchronous) =>
                    synchronous || frame != null ? child : placeholder,
              ),
      ),
    );
  }
}

/// One pack in a list: picture, name, and what it holds.
class PackTile extends StatelessWidget {
  const PackTile({
    super.key,
    required this.pack,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final PackSummary pack;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final description = pack.description?.trim() ?? '';
    return InkWell(
      key: Key('pack-${pack.id}'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: FzPanel(
        borderColor: selected ? FzColors.ac : null,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            PackImage(url: pack.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FzDirection(
                    text: pack.name,
                    child: Text(
                      pack.name.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: fz.h(15.5, weight: FontWeight.w700),
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    FzDirection(
                      text: description,
                      child: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fz.m(12, color: FzColors.dim),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  FzTag(packFacts(pack)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (selected && trailing == null)
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(Icons.check_circle, color: FzColors.ac),
              ),
          ],
        ),
      ),
    );
  }
}

/// "169 questions · photos · 143K plays".
String packFacts(PackSummary pack) => [
  if (pack.numQuestions != null) '${pack.numQuestions} questions',
  if (pack.hasImages) 'photos',
  if (pack.playCount != null) '${compactCount(pack.playCount!)} plays',
].join(' · ');

/// 950, 14K, 143K, 3.2M.
String compactCount(int n) {
  String short(double v) => v >= 10
      ? v.round().toString()
      : v.toStringAsFixed(1).replaceAll('.0', '');
  if (n >= 1000000) return '${short(n / 1000000)}M';
  if (n >= 1000) return '${short(n / 1000)}K';
  return '$n';
}
