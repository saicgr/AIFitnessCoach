import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitwiz/core/theme/theme_colors.dart';
import 'package:fitwiz/data/models/chat_message.dart';
import 'package:fitwiz/data/repositories/chat_repository.dart';
import 'package:fitwiz/widgets/pill_app_bar.dart';

/// Overlay that lets the user search through chat messages.
class ChatSearchOverlay extends ConsumerStatefulWidget {
  final List<ChatMessage> messages;
  final void Function(String messageId) onScrollToMessage;

  const ChatSearchOverlay({
    super.key,
    required this.messages,
    required this.onScrollToMessage,
  });

  @override
  ConsumerState<ChatSearchOverlay> createState() => _ChatSearchOverlayState();
}

class _ChatSearchOverlayState extends ConsumerState<ChatSearchOverlay> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<ChatMessage> _results = [];
  List<ChatMessage> _serverResults = [];
  bool _isSearchingServer = false;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = value.trim().toLowerCase();
      if (query.isEmpty) {
        setState(() {
          _query = '';
          _results = [];
          _serverResults = [];
          _isSearchingServer = false;
        });
        return;
      }
      // Local search first
      setState(() {
        _query = query;
        _results = widget.messages
            .where((m) => m.content.toLowerCase().contains(query))
            .toList();
      });

      // Server search in parallel
      _searchServer(query);
    });
  }

  Future<void> _searchServer(String query) async {
    setState(() => _isSearchingServer = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final serverResults = await repo.searchChatHistory(query);
      if (mounted && _query == query) {
        // Merge: add server results not already in local results
        final localIds = _results.map((m) => m.id).whereType<String>().toSet();
        final newServerResults = serverResults
            .where((m) => m.id != null && !localIds.contains(m.id))
            .toList();
        setState(() {
          _serverResults = newServerResults;
          _isSearchingServer = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearchingServer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final allResults = [..._results, ..._serverResults];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const PillAppBar(
        title: 'Search Chat',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onSearchChanged,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(color: colors.textMuted),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                filled: true,
                fillColor: colors.glassSurface,
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
                  borderSide: BorderSide(color: colors.accent),
                ),
              ),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Text(
                      'Type to search',
                      style: TextStyle(color: colors.textMuted),
                    ),
                  )
                : allResults.isEmpty && !_isSearchingServer
                    ? Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(color: colors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: allResults.length + (_isSearchingServer ? 1 : 0),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          if (index == allResults.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final message = allResults[index];
                          return _SearchResultCard(
                            message: message,
                            query: _query,
                            colors: colors,
                            onTap: () {
                              if (message.id != null) {
                                widget.onScrollToMessage(message.id!);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final ChatMessage message;
  final String query;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.message,
    required this.query,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.elevated,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    message.isUser ? Icons.person : Icons.smart_toy,
                    size: 14,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.isUser ? 'You' : (message.agentConfig.displayName),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildHighlightedText(message.content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text) {
    // Show a trimmed preview around the first match
    final lowerText = text.toLowerCase();
    final matchIndex = lowerText.indexOf(query);
    if (matchIndex == -1) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.textSecondary, fontSize: 14),
      );
    }

    // Build spans with the matching part bolded
    final spans = <TextSpan>[];
    int current = 0;
    int searchFrom = 0;

    while (searchFrom < text.length) {
      final idx = lowerText.indexOf(query, searchFrom);
      if (idx == -1) break;

      // Text before match
      if (idx > current) {
        spans.add(TextSpan(
          text: text.substring(current, idx),
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ));
      }

      // Matched text
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ));

      current = idx + query.length;
      searchFrom = current;
    }

    // Remaining text
    if (current < text.length) {
      spans.add(TextSpan(
        text: text.substring(current),
        style: TextStyle(color: colors.textSecondary, fontSize: 14),
      ));
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}
