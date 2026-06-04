/// Social-era preset — **Reddit Post**. A dark Reddit post card: the
/// "r/Fitness · u/handle" meta line, a bold post title bound to the share, a
/// large image, and the vote / comment bar (upvote arrow in the accent colour,
/// score, comment count). Subreddit line, title and counts are editable; the
/// image binds to the share's hero photo.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialRedditPostDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cardBg = Color(0xFF1A1A1B);
  const fg = Color(0xFFD7DADC);
  const meta = Color(0xFF818384);
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialRedditPost',
    accent: accent,
    background: solidBg(cardBg),
    elements: [
      // Subreddit / author meta.
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.88, 0.03),
        literal: 'r/Fitness  ·  Posted by u/chetan.lifts',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: meta,
        maxLines: 1,
      ),
      // Post title.
      textEl(
        pos: const Offset(0.5, 0.18),
        size: const Size(0.88, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.cond,
        fontSize: 34,
        color: fg,
        lineHeight: 1.15,
        maxLines: 3,
      ),
      // Post image.
      photoEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.88, 0.5),
        binding: const DataBinding(BindingSource.heroImageUrl),
        mask: PhotoMask.rounded,
        cornerRadius: 10,
      ),
      // Vote / comment bar.
      textEl(
        pos: const Offset(0.18, 0.86),
        size: const Size(0.08, 0.04),
        literal: '⬆',
        fontSize: 30,
        color: accent,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.3, 0.86),
        size: const Size(0.2, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 26,
        color: white,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.45, 0.86),
        size: const Size(0.1, 0.04),
        literal: '⬇',
        fontSize: 26,
        color: meta,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.74, 0.86),
        size: const Size(0.32, 0.04),
        literal: '💬 318 Comments',
        font: CardFontIx.condMid,
        fontSize: 20,
        color: meta,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: meta),
    ],
  );
}
