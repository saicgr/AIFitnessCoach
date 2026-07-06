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
  // ── Equipment set ─────────────────────────────────────────────────────
  // Hand-authored in the shared stroked style so the whole equipment grid
  // reads as ONE consistent icon vocabulary (Material/FontAwesome have no
  // real gym set). Stylized but uniform.
  'eq_dumbbell': '$_h<path d="M9 12h6 M6.5 8.5v7 M8.5 7v10 M15.5 7v10 '
      'M17.5 8.5v7"/></svg>',
  'eq_barbell': '$_h<path d="M3 12h18 M6.5 8v8 M9 9.5v5 M15 9.5v5 '
      'M17.5 8v8"/></svg>',
  'eq_kettlebell': '$_h<circle cx="12" cy="15.5" r="5"/>'
      '<path d="M9 12.5V11a3 3 0 016 0v1.5"/></svg>',
  'eq_medicine_ball': '$_h<circle cx="12" cy="12" r="8.5"/>'
      '<path d="M4.2 9.5c5 2.4 10.6 2.4 15.6 0 M4.2 14.5c5-2.4 10.6-2.4 15.6 0"/>'
      '</svg>',
  'eq_bench': '$_h<rect x="3.5" y="8.5" width="17" height="3" rx="1.5"/>'
      '<path d="M6.5 11.5v5 M17.5 11.5v5 M5 16.5h3 M16 16.5h3"/></svg>',
  'eq_squat_rack': '$_h<path d="M6 4v16 M18 4v16 M3 9h18 M4.5 20h3 M16.5 20h3 '
      'M6 7.5h2 M16 7.5h2"/></svg>',
  'eq_cable_machine': '$_h<path d="M6 4v16 M6 5h9 M16 6.6v6 M14 12.5h4 '
      'M4.8 13h2.4 M4.8 16h2.4 M4.8 19h2.4"/><circle cx="16" cy="5.3" r="1.3"/>'
      '</svg>',
  'eq_resistance_band': '$_h<circle cx="5" cy="12" r="2.3"/>'
      '<circle cx="19" cy="12" r="2.3"/>'
      '<path d="M7.3 12c1.8-2.3 3.6-2.3 4.7 0 1.1 2.3 2.9 2.3 4.7 0"/></svg>',
  'eq_pull_up_bar': '$_h<path d="M3 8.5h18 M7 8.5V5 M17 8.5V5 M5 5h4 '
      'M15 5h4"/></svg>',
  'eq_trx': '$_h<path d="M12 4v1.5 M12 5.5L8.5 14 M12 5.5L15.5 14 M7 14h3 '
      'M14 14h3 M8.5 14v2.6 M15.5 14v2.6"/></svg>',
  'eq_bodyweight': '$_h<circle cx="12" cy="5" r="2.2"/>'
      '<path d="M12 7.4v6 M6.5 10.5h11 M12 13.4l-3.2 6 M12 13.4l3.2 6"/></svg>',
  'eq_full_gym': '$_h<path d="M4 20V8.5l8-4.5 8 4.5V20 M3 20h18 '
      'M9.5 20v-5h5v5"/></svg>',
  // ── Specialty bars ──────────────────────────────────────────────────
  // Each silhouette distinguishes the bar's defining physical feature so
  // the "Free weights" row doesn't read as 7 identical barbell chips.
  'eq_olympic_barbell': '$_h<path d="M3 12h18 M6.5 8v8 M9 9.5v5 M15 9.5v5 '
      'M17.5 8v8"/><circle cx="7.7" cy="12" r="0.8" fill="#000"/>'
      '<circle cx="16.3" cy="12" r="0.8" fill="#000"/></svg>',
  'eq_ez_bar': '$_h<path d="M3 12h2.2 M18.8 12h2.2 '
      'M5.2 12l2.3-2.3 2.3 4.6 2.4-4.6 2.3 4.6 2.3-4.6 2.4 2.3"/>'
      '<path d="M6.5 8.5v7 M17.5 8.5v7"/></svg>',
  'eq_trap_bar': '$_h<path d="M8.5 8h7l2.7 4-2.7 4h-7l-2.7-4z"/>'
      '<path d="M3 12h2.8 M18.2 12h3"/></svg>',
  'eq_safety_squat_bar': '$_h<path d="M3.5 12h3.5 M17 12h3.5"/>'
      '<path d="M7 12a5 5 0 0110 0"/><path d="M8.5 9.3v3.4 M15.5 9.3v3.4"/>'
      '</svg>',
  'eq_cambered_bar': '$_h<path d="M3 13c4.5-4 13.5-4 18 0"/>'
      '<path d="M6.3 10.3v6 M17.7 10.3v6"/></svg>',
  'eq_swiss_bar': '$_h<rect x="7" y="8" width="10" height="8" rx="1.2"/>'
      '<path d="M7 10.7h10 M7 13.3h10 M3 12h4 M17 12h4"/></svg>',
  'eq_log_bar': '$_h<path d="M3 12h3.5 M17.5 12h3.5"/>'
      '<rect x="6.2" y="9" width="11.6" height="6" rx="3"/></svg>',
};
