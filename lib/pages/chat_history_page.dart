import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session_model.dart';
import '../providers/providers.dart';
import '../widgets/chat_history_card.dart';
import 'document_chat_screen.dart';

class ChatHistoryPage extends ConsumerWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(cloudFirestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatSessionModel>>(
        stream: firestore.chatSessionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading history: ${snapshot.error}"),
            );
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No chat history yet",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: sessions.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return ChatHistoryCard(
                session: session,
                onTap: () {
                  // Navigate to the chat screen with this session ID
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DocumentChatScreen(currentConversationId: session.id),
                    ),
                  );
                },
                onMoreTap: () {
                  // Handle delete or options here
                  _showOptionsModal(context, session, ref);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showOptionsModal(
    BuildContext context,
    ChatSessionModel session,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Delete Conversation",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  // Close the modal bottom sheet first
                  Navigator.pop(modalContext);

                  // Show confirmation dialog
                  _confirmDelete(context, ref, session.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(modalContext),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String sessionId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Chat?"),
          content: const Text("This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog

                try {
                  // Call the delete function
                  await ref
                      .read(cloudFirestoreServiceProvider)
                      .deleteChatSession(sessionId);

                  // Optional: Show a snackbar/toast success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Conversation deleted")),
                    );
                  }
                } catch (e) {
                  // Handle error
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error deleting: $e")),
                    );
                  }
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
