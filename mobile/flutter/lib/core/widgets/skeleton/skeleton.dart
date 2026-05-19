/// Part 1 of the instant-load standard — skeleton kit barrel export.
///
/// Import this single file to get the whole skeleton + cache-first-view kit:
///
/// ```dart
/// import 'package:fitwiz/core/widgets/skeleton/skeleton.dart';
/// ```
///
/// Exposes:
///  - [SkeletonShimmer], [SkeletonBox], [SkeletonText], [SkeletonCircle]
///    — the shimmer primitives (one shared shimmer implementation).
///  - [SkeletonCard], [SkeletonList], [SkeletonGrid]
///    — list / card / grid placeholder layouts.
///  - [CacheFirstView]
///    — the skeleton-on-first-open, content-instantly-otherwise host widget.
library;

export 'cache_first_view.dart';
export 'skeleton_box.dart';
export 'skeleton_list.dart';
