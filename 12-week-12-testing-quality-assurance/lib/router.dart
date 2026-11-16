import 'package:go_router/go_router.dart';

import 'features/chat_screen.dart';
import 'features/multimodal_screen.dart';
import 'pages/note_detail_page.dart';
import 'pages/notes_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const NotesPage();
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        return const ChatScreen();
      },
    ),
    GoRoute(
      path: '/ai-tools',
      builder: (context, state) {
        return const MultimodalScreen();
      },
    ),
    GoRoute(
      path: '/note/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');

        if (id == null) {
          return const NotesPage();
        }

        return NoteDetailPage(noteId: id);
      },
    ),
  ],
);
