import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Zealova's custom line-icon set.
///
/// A single, consistent stroked icon vocabulary used across the redesigned
/// home + nutrition surfaces — replacing emoji and ad-hoc Material glyphs.
/// Icons are inline SVG strings (rendered via `SvgPicture.string`) so there
/// are no asset files / pubspec globs to register, and `currentColor` tinting
/// is applied through a `ColorFilter` so every icon follows the theme accent
/// or whatever colour the call site passes.
///
/// To swap in bespoke brand artwork later, only the [_svg] map changes.
class LineIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;

  const LineIcon(
    this.name, {
    super.key,
    this.size = 22,
    this.color = const Color(0xFFFAFAFA),
  });

  @override
  Widget build(BuildContext context) {
    final svg = _svg[name] ?? _svg['help']!;
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

const String _h =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
    'stroke="#000" stroke-width="1.8" stroke-linecap="round" '
    'stroke-linejoin="round">';

const Map<String, String> _svg = {
  'workout': '$_h<path d="M6.5 6.5v11M3.7 9.2v5.6M17.5 6.5v11M20.3 9.2v5.6'
      'M6.5 12h11"/></svg>',
  'nutrition': '$_h<path d="M12 8.5c-1.6-2.6-7-2.2-7 3.2 0 4.8 3 8.8 4.8 8.8'
      '.9 0 1.1-.5 2.2-.5s1.3.5 2.2.5c1.8 0 4.8-4 4.8-8.8 0-5.4-5.4-5.8-7-3.2z"/>'
      '<path d="M12 8.5c0-2 1-3.4 3.4-4"/></svg>',
  'activity': '$_h<circle cx="13.5" cy="4.8" r="2.2"/><path d="M13.5 9l-2.3 '
      '4.6 3.4 1.9 1 5.5M11.2 13.6L6.8 15M14.6 15.5l4.4 1.9"/></svg>',
  'sleep': '$_h<path d="M20.5 14.2A8.5 8.5 0 119.8 3.5a6.7 6.7 0 0010.7 '
      '10.7z"/></svg>',
  'fasting': '$_h<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3.2 '
      '2.2"/></svg>',
  'water': '$_h<path d="M12 3.2c3.8 4.7 6 7.7 6 10.6a6 6 0 01-12 0c0-2.9 2.2-'
      '5.9 6-10.6z"/></svg>',
  'play': '$_h<path d="M8 5.5l11 6.5-11 6.5z"/></svg>',
  'plus': '$_h<path d="M12 5.5v13M5.5 12h13"/></svg>',
  'check': '$_h<circle cx="12" cy="12" r="8.5"/><path d="M8.5 12.3l2.5 2.5 '
      '4.5-5"/></svg>',
  'eye': '$_h<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 '
      '2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/></svg>',
  'chat': '$_h<path d="M20.5 12a8 8 0 01-11.5 7.2L4 20.5l1.3-5A8 8 0 1120.5 '
      '12z"/></svg>',
  'spark': '$_h<path d="M12 3l2.3 6 6 2.3-6 2.3L12 20l-2.3-6.4-6-2.3 6-2.3z"/>'
      '</svg>',
  'refresh': '$_h<path d="M20 11a8 8 0 10-2.3 6M20 5v6h-6"/></svg>',
  'custom_trend': '$_h<path d="M3.2 15.8l4.6-5 3.4 3 5-6.2"/>'
      '<path d="M11.6 7.6h4.6v4.4"/><path d="M17 16v6M14 19h6"/></svg>',
  'more': '$_h<circle cx="12" cy="5" r="1.6" fill="#000"/><circle cx="12" '
      'cy="12" r="1.6" fill="#000"/><circle cx="12" cy="19" r="1.6" '
      'fill="#000"/></svg>',
  'bell': '$_h<path d="M6 9a6 6 0 0112 0c0 5 2 6 2 7H4c0-1 2-2 2-7z"/>'
      '<path d="M9.5 20a2.5 2.5 0 005 0"/></svg>',
  'flame': '$_h<path d="M12 3c.5 3 3.5 4 3.5 8a3.5 3.5 0 01-7 0c0-1.6.8-2.6 '
      '1.6-3.4.4 1.8 1.9 1.7 1.9-4.6z"/></svg>',
  'help': '$_h<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.6a2.4 2.4 0 '
      '014.6.9c0 1.6-2.2 2-2.2 3.5M12 17h.01"/></svg>',
};
