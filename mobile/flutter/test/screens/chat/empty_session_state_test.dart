// Regression gate for row 53 (E2E): tapping a saved conversation in HISTORY
// whose messages were lost server-side (chat_history rows gone, session
// shell + derived coach_memory survived) opened a chat screen PIXEL
// IDENTICAL to a brand-new chat — no title, no messages, no indication
// anything was wrong. The tap read as a no-op, and the user had no way to
// tell they'd opened the wrong thing or that the conversation was gone.
//
// `chat_screen.dart`'s empty-messages branch now checks
// `currentChatSessionProvider != null` (the same signal
// `_runOpenStateLadderBody` already uses to mean "this is an existing
// session, not an organic new chat") and renders [EmptySessionState] instead
// of the generic "TRY ASKING…" landing when that's true. This test covers
// the extracted widget directly — the routing condition itself is a
// one-line reuse of an existing, already-covered guard
// (chat_screen.dart:~419/450).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/chat/widgets/empty_session_state.dart';

Widget _wrap(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets(
      'tells the user the conversation is empty and not new, instead of '
      'reading as a silent no-op', (tester) async {
    var backTapped = false;
    await tester.pumpWidget(_wrap(EmptySessionState(
      onBackToChats: () => backTapped = true,
    )));

    // The two things the pre-fix screen never said: this is a real
    // conversation (not "Try asking…"), and it's genuinely empty.
    expect(find.text('This conversation has no messages'), findsOneWidget);
    expect(
      find.textContaining("didn't save"),
      findsOneWidget,
      reason: 'Must distinguish "this chat lost its messages" from '
          '"you haven\'t chatted yet" — the two states the pre-fix screen '
          'rendered identically.',
    );
    // Must NOT show the brand-new-chat copy — that's the exact confusion
    // this state exists to prevent.
    expect(find.textContaining('Try asking'), findsNothing);

    await tester.tap(find.text('Back to Chats'));
    await tester.pump();
    expect(backTapped, isTrue,
        reason: 'The only escape from an orphaned session must actually '
            'fire — the pre-fix screen offered no way to tell you\'d '
            'opened the wrong thing, let alone recover from it.');
  });
}
