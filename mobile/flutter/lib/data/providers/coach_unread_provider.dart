import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unread proactive coach messages (server-computed in /home/bootstrap:
/// proactive chat_history rows newer than users.coach_chat_last_seen_at).
///
/// Seeded by BootstrapPrefetchService on every bootstrap; cleared optimistically
/// when the coach chat opens (ChatScreen also POSTs /chat/seen so the server
/// stamp moves forward and the next bootstrap agrees).
final coachUnreadCountProvider = StateProvider<int>((ref) => 0);

/// SharedPreferences key for the server-nudge-engine liveness flag delivered
/// by /home/bootstrap (`server_nudges_active`). While true, the local
/// template-notification barrage (daily bundles / afternoon nudge / streak
/// alert / weekly summary) stands down in favor of the server's context-aware
/// coach pushes — never double-send, never dead-air (flag flips false within
/// 48h if the engagement cron stops logging sends).
const String kServerNudgesActivePrefsKey = 'server_nudges_active';
