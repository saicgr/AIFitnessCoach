/// Social-era preset — **Instagram Post**. A faithful IG feed card on black:
/// an avatar-row header (avatar + handle, verified tick), a large square photo
/// in the middle, the like/comment/share action glyphs, a likes count, and a
/// caption line with the bolded handle. The header, like-count and caption are
/// editable text; the photo binds to the share's hero image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialIgPostDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialIgPost',
    accent: accent,
    background: solidBg(const Color(0xFF000000)),
    elements: [
      // Header — avatar + handle + verified.
      avatarRowEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.9, 0.06),
        fallbackGlyph: '🏋️',
        sub: 'Original audio',
        verified: true,
        fontSize: 26,
      ),
      // The square photo.
      photoEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(1.0, 0.62),
        binding: const DataBinding(BindingSource.heroImageUrl),
        mask: PhotoMask.rect,
        cornerRadius: 0,
      ),
      // Action glyph row (like / comment / share — bookmark right).
      textEl(
        pos: const Offset(0.2, 0.82),
        size: const Size(0.4, 0.04),
        literal: '♡    💬    ↪',
        fontSize: 26,
        color: white,
      ),
      iconEl(
        pos: const Offset(0.92, 0.82),
        size: const Size(0.08, 0.04),
        emoji: '🔖',
      ),
      // Likes count.
      textEl(
        pos: const Offset(0.15, 0.88),
        size: const Size(0.6, 0.03),
        literal: '2,481 likes',
        font: CardFontIx.cond,
        fontSize: 24,
        color: white,
      ),
      // Caption — bold handle + title.
      textEl(
        pos: const Offset(0.42, 0.925),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.socialHandle),
        font: CardFontIx.cond,
        fontSize: 22,
        color: white,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.42, 0.96),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 20,
        color: white70,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.04, 0.04), color: white70),
    ],
  );
}
