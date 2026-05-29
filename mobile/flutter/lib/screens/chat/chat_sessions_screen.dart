import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/models/chat_session.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/haptic_service.dart';

/// "Ask Coach" conversation list — like ChatGPT/Gemini chat history.
///
/// Instant cache paint + silent refresh (feedback_instant_data), debounced
/// search, a prominent "New chat" row, and per-row Rename / Archive / Delete.
class ChatSessionsScreen extends ConsumerStatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  ConsumerState<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends ConsumerState<ChatSessionsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Silent refresh on open (no pull-to-refresh control).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatSessionsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(chatSessionsProvider.notifier).setQuery(value);
    });
  }

  void _startNewChat() {
    HapticService.light();
    ref.read(chatMessagesProvider.notifier).startNewChat();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chat');
    }
  }

  Future<void> _openSession(ChatSession session) async {
    HapticService.light();
    await ref.read(chatMessagesProvider.notifier).switchToSession(session.id);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () {
            HapticService.light();
            context.pop();
          },
        ),
        title: Text(
          'Chats',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: Icon(Icons.add_rounded, color: colors.accent),
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSearchField(colors),
            _buildNewChatRow(colors),
            Divider(height: 1, color: colors.cardBorder),
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) => _buildList(colors, sessions),
                loading: () => _buildShimmer(colors),
                error: (e, _) => _buildError(colors, e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: colors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search conversations',
          hintStyle: TextStyle(color: colors.textSecondary, fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: colors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildNewChatRow(ThemeColors colors) {
    return InkWell(
      onTap: _startNewChat,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.add_rounded, color: colors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'New chat',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemeColors colors, List<ChatSession> sessions) {
    if (sessions.isEmpty) {
      return _buildEmpty(colors);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sessions.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 16, endIndent: 16, color: colors.cardBorder),
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionRow(
          session: session,
          colors: colors,
          onTap: () => _openSession(session),
          onRename: () => _showRenameDialog(colors, session),
          onArchive: () => _archive(session),
          onDelete: () => _confirmDelete(colors, session),
        );
      },
    );
  }

  Widget _buildEmpty(ThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: colors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No conversations yet'
                  : 'No matches found',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isEmpty
                  ? 'Start a new chat with your coach to see it here.'
                  : 'Try a different search term.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(ThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 16, endIndent: 16, color: colors.cardBorder),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 160,
              height: 14,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeColors colors, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
            const SizedBox(height: 12),
            Text(
              "Couldn't load your chats",
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.accentContrast,
              ),
              onPressed: () => ref.read(chatSessionsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(ThemeColors colors, ChatSession session) async {
    final controller = TextEditingController(text: session.title ?? '');
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Rename chat', style: TextStyle(color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Conversation name',
            hintStyle: TextStyle(color: colors.textSecondary),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text('Save', style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle == null || newTitle.isEmpty || newTitle == session.title) return;
    try {
      await ref.read(chatSessionsProvider.notifier).rename(session.id, newTitle);
    } catch (e) {
      _toast("Couldn't rename: ${e.toString().replaceFirst('Exception: ', '')}");
    }
  }

  Future<void> _archive(ChatSession session) async {
    HapticService.selection();
    try {
      await ref.read(chatSessionsProvider.notifier).archive(session.id, !session.isArchived);
      _toast(session.isArchived ? 'Unarchived' : 'Archived');
    } catch (e) {
      _toast("Couldn't archive: ${e.toString().replaceFirst('Exception: ', '')}");
    }
  }

  Future<void> _confirmDelete(ThemeColors colors, ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Delete chat?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'This permanently deletes "${session.displayTitle}" and all its messages.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final wasActive =
        ref.read(currentChatSessionProvider) == session.id;
    try {
      await ref.read(chatSessionsProvider.notifier).delete(session.id);
    } catch (e) {
      _toast("Couldn't delete: ${e.toString().replaceFirst('Exception: ', '')}");
      return;
    }
    if (!wasActive) return;
    // The active session was deleted — fall back to the latest remaining
    // session, or a brand-new chat if none remain.
    final remaining = ref.read(chatSessionsProvider).valueOrNull ?? const [];
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    if (remaining.isNotEmpty) {
      await chatNotifier.switchToSession(remaining.first.id);
    } else {
      chatNotifier.startNewChat();
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// A single conversation row: title (bold), preview (1 line, muted), relative
/// time, and an overflow menu (Rename / Archive / Delete). Long-press also
/// opens the menu.
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.colors,
    required this.onTap,
    required this.onRename,
    required this.onArchive,
    required this.onDelete,
  });

  final ChatSession session;
  final ThemeColors colors;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () => _showMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(session.sortTime),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (session.preview.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      session.preview.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (session.isArchived) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.archive_outlined,
                            size: 12, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Archived',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 36,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded,
                    color: colors.textSecondary, size: 20),
                onPressed: () => _showMenu(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    HapticService.selection();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colors.textPrimary),
              title: Text('Rename', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.of(ctx).pop();
                onRename();
              },
            ),
            ListTile(
              leading: Icon(
                session.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                color: colors.textPrimary,
              ),
              title: Text(
                session.isArchived ? 'Unarchive' : 'Archive',
                style: TextStyle(color: colors.textPrimary),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                onArchive();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text('Delete', style: TextStyle(color: colors.error)),
              onTap: () {
                Navigator.of(ctx).pop();
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Human-friendly relative time: "Just now", "2h ago", "Yesterday",
  /// "May 12", or "May 12, 2024" for older years.
  static String _relativeTime(DateTime? raw) {
    if (raw == null) return '';
    final dt = raw.toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && now.day == dt.day) return '${diff.inHours}h ago';

    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final monthName = months[dt.month - 1];
    if (dt.year == now.year) return '$monthName ${dt.day}';
    return '$monthName ${dt.day}, ${dt.year}';
  }
}
