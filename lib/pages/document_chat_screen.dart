import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'; // UPDATED IMPORT
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../constants/colors.dart';
import '../models/chat_message_model.dart';
import '../providers/providers.dart';
import '../services/financial_ai_service.dart';

class DocumentChatScreen extends ConsumerStatefulWidget {
  const DocumentChatScreen({super.key});

  @override
  ConsumerState<DocumentChatScreen> createState() => _DocumentChatScreenState();
}

class _DocumentChatScreenState extends ConsumerState<DocumentChatScreen> {
  final FinancialAiService _aiService = FinancialAiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  // List<Map<String, String>> chatHistory = [];
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  // --- ACTIONS ---

  Future<void> _pickFile() async {
    final file = await _aiService.pickDocument();
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  // Future<void> _sendMessage() async {
  //   final text = _textController.text.trim();
  //   if (text.isEmpty) return;

  //   setState(() {
  //     chatHistory.add({
  //       "role": "user",
  //       "text": text.isEmpty ? "Analyze this document" : text,
  //       "attachment": _selectedFile?.name ?? "No document selected",
  //     });
  //     _isLoading = true;
  //   });
  //   _textController.clear();
  //   _scrollToBottom();

  //   try {
  //     // Pass the file (if selected) to the service
  //     final response = await _aiService.sendMessage(
  //       text,
  //       attachedFile: _selectedFile,
  //     );

  //     setState(() {
  //       chatHistory.add({
  //         "role": "model",
  //         "text": response ?? "No response generated.",
  //       });
  //     });
  //   } catch (e) {
  //     setState(() {
  //       chatHistory.add({"role": "model", "text": "Error: ${e.toString()}"});
  //     });
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     _scrollToBottom();
  //   }
  // }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userModelProvider);
    final firestore = ref.read(cloudFirestoreServiceProvider);
    final uuid = const Uuid();

    // 1. Save USER message to Firestore
    final userMsgId = uuid.v4();
    final userMessage = ChatMessageModel(
      id: userMsgId,
      userId: user.uid,
      text: text,
      role: MessageRole.user,
      attachmentName: _selectedFile?.name,
      createdAt: DateTime.now(),
    );

    // Optimistic UI update isn't strictly needed with StreamBuilder,
    // but saving it triggers the stream update.
    await firestore.saveChatMessage(userMessage);

    setState(() {
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      // 2. Get AI Response
      final responseText = await _aiService.sendMessage(
        text,
        attachedFile: _selectedFile,
      );

      // 3. Save AI message to Firestore
      final aiMsgId = uuid.v4();
      final aiMessage = ChatMessageModel(
        id: aiMsgId,
        userId: user.uid,
        text: responseText,
        role: MessageRole.model,
        createdAt: DateTime.now(),
      );
      await firestore.saveChatMessage(aiMessage);
    } catch (e) {
      // Save error as AI message so user sees it
      final errorId = uuid.v4();
      final errorMessage = ChatMessageModel(
        id: errorId,
        userId: user.uid,
        text: "Error: ${e.toString()}",
        role: MessageRole.model,
        createdAt: DateTime.now(),
      );
      await firestore.saveChatMessage(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
        _selectedFile = null; // Clear file after sending
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    Brightness brightness = MediaQuery.platformBrightnessOf(context);
    final firestore = ref.watch(cloudFirestoreServiceProvider);

    return Scaffold(
      //  backgroundColor: backgroundColor,
      appBar: AppBar(
        // backgroundColor: backgroundColor,
        title: const Text(
          "Docs", // style: TextStyle(color: Colors.white)
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back, //color: Colors.white
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          CircleAvatar(
            // backgroundColor: Colors.deepOrange,
            child: const Text(
              "C", //style: TextStyle(color: Colors.white,)
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 1. Chat Area (StreamBuilder)
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: firestore.chatHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!;

                if (messages.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      messages.length +
                      (_isLoading ? 1 : 0), // Add 1 for loading indicator
                  itemBuilder: (context, index) {
                    // Show loading indicator at the bottom if waiting
                    if (index == messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final msg = messages[index];
                    final isUser = msg.role == MessageRole.user;

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color.fromARGB(80, 128, 128, 128)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.attachmentName != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      msg.attachmentName!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            MarkdownBody(
                              data: msg.text,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(fontSize: 16),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                h1: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                h2: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // // 1. Chat Area
          // Expanded(
          //   child: chatHistory.isEmpty
          //       ? _buildEmptyState()
          //       : ListView.builder(
          //           controller: _scrollController,
          //           padding: const EdgeInsets.all(16),
          //           itemCount: chatHistory.length,
          //           itemBuilder: (context, index) {
          //             final msg = chatHistory[index];
          //             final isUser = msg['role'] == 'user';
          //             return Align(
          //               alignment: isUser
          //                   ? Alignment.centerRight
          //                   : Alignment.centerLeft,
          //               child: Container(
          //                 margin: const EdgeInsets.symmetric(vertical: 8),
          //                 padding: const EdgeInsets.all(16),
          //                 constraints: BoxConstraints(
          //                   maxWidth: MediaQuery.of(context).size.width * 0.85,
          //                 ),
          //                 decoration: BoxDecoration(
          //                   color: isUser
          //                       ? const Color.fromARGB(80, 128, 128, 128)
          //                       : Colors.transparent,
          //                   borderRadius: BorderRadius.circular(18),
          //                 ),
          //                 child: Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   children: [
          //                     if (msg.containsKey('attachment')) ...[
          //                       Container(
          //                         padding: const EdgeInsets.symmetric(
          //                           horizontal: 8,
          //                           vertical: 4,
          //                         ),
          //                         decoration: BoxDecoration(
          //                           color: Colors.black26,
          //                           borderRadius: BorderRadius.circular(8),
          //                         ),
          //                         child: Row(
          //                           mainAxisSize: MainAxisSize.min,
          //                           children: [
          //                             const Icon(
          //                               Icons.description,
          //                               size: 14,
          //                               color: Colors.white70,
          //                             ),
          //                             const SizedBox(width: 4),
          //                             Text(
          //                               msg['attachment']!,
          //                               style: const TextStyle(
          //                                 color: Colors.white70,
          //                                 fontSize: 12,
          //                               ),
          //                             ),
          //                           ],
          //                         ),
          //                       ),
          //                       const SizedBox(height: 8),
          //                     ],
          //                     // UPDATED MARKDOWN WIDGET
          //                     MarkdownBody(
          //                       data: msg['text']!,
          //                       styleSheet: MarkdownStyleSheet(
          //                         p: TextStyle(
          //                           // color: accentColor,
          //                           fontSize: 16,
          //                         ),
          //                         strong: TextStyle(
          //                           // color: accentColor,
          //                           fontWeight: FontWeight.bold,
          //                         ),
          //                         // Add more styling as needed for headers, lists, etc.
          //                         h1: TextStyle(
          //                           // color: accentColor,
          //                           fontSize: 24,
          //                           fontWeight: FontWeight.bold,
          //                         ),
          //                         h2: TextStyle(
          //                           // color: accentColor,
          //                           fontSize: 20,
          //                           fontWeight: FontWeight.bold,
          //                         ),
          //                         // listBullet: TextStyle(color: accentColor),
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             );
          //           },
          //         ),
          // ),

          // 2. Input Area
          Container(
            padding: const EdgeInsets.all(16),
            // decoration: BoxDecoration(color: backgroundColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, left: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            // color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: brightness == Brightness.dark
                                  ? Colors.white24
                                  : kblack00004,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.insert_drive_file,
                                // color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Text(
                                  _selectedFile!.extension?.toUpperCase() ??
                                      "DOC",
                                  style: const TextStyle(
                                    // color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: _removeFile,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                // color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                //  color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  decoration: BoxDecoration(
                    // color: surfaceColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _pickFile,
                        icon: const Icon(
                          Icons.add, //color: Colors.grey
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          //style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Ask Gemini",
                            // hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : _sendMessage,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: brightness == Brightness.dark
                                      ? kwhite25525525510
                                      : kblack000010,
                                ),
                              )
                            : const Icon(
                                Icons.send, //color: Colors.white
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Hello, User",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              // color: Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Upload a document to get started",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
