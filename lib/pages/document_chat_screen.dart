import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'; // UPDATED IMPORT
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../constants/colors.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import '../providers/providers.dart';
import '../services/eleven_labs_agent_service.dart';
import '../services/financial_ai_service.dart';

class DocumentChatScreen extends ConsumerStatefulWidget {
  DocumentChatScreen({this.currentConversationId, super.key});
  String? currentConversationId;

  @override
  ConsumerState<DocumentChatScreen> createState() => _DocumentChatScreenState();
}

class _DocumentChatScreenState extends ConsumerState<DocumentChatScreen> {
  final FinancialAiService _aiService = FinancialAiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ElevenLabsAgentService _agentService = ElevenLabsAgentService();
  final SpeechToText _speech = SpeechToText();
  // Inside _DocumentChatScreenState
  String? _currentConversationId; // Null means we are in a "New Chat" state

  // State
  // List<Map<String, String>> chatHistory = [];
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  bool _isListening = false; // Track mic state
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentConversationId != null) {
      _currentConversationId = widget.currentConversationId!;
    }
    _initSpeech();
  }

  @override
  void dispose() {
    _agentService.disconnect(); // Cleanup agent connection
    super.dispose();
  }

  void _initSpeech() async {
    // Request microphone permission on init
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speech.initialize();
      setState(() {});
    }
  }

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

  // --- VOICE LOGIC ---
  void _startListening() async {
    if (!_speechEnabled) return;

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
        });
      },
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);

    // Optional: Auto-send after stopping
    if (_textController.text.isNotEmpty) _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userModelProvider);
    final firestore = ref.read(cloudFirestoreServiceProvider);
    final uuid = const Uuid();

    // 1. If this is a new chat, create the Session ID and save the Session Header
    if (_currentConversationId == null) {
      final newId = uuid.v4();

      final newSession = ChatSessionModel(
        id: newId,
        title: text, // Use first message as title (e.g., "Revenue analysis")
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the "Folder"
      await firestore.saveChatSession(newSession);
      setState(() {
        _currentConversationId = newId;
      });
    }

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
    // 3. Save to the specific conversation ID
    await firestore.saveChatMessage(
      conversationId: _currentConversationId!,
      message: userMessage,
    );

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
      // 4. When saving AI response:
      await firestore.saveChatMessage(
        conversationId: _currentConversationId!,
        message: aiMessage,
      );
      // 4. TRIGGER THE AGENT
      // We pass the full Gemini response (which contains the data insights)
      // to the Agent. The Agent will summarize and speak it.
      if (responseText != null && responseText.isNotEmpty) {
        await _agentService.startSession(contextText: responseText);
      }
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
      // 4. When saving AI response:
      await firestore.saveChatMessage(
        conversationId: _currentConversationId!,
        message: errorMessage,
      );
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
            child: _currentConversationId == null
                ? _buildEmptyState() // "Start a new chat" UI
                : StreamBuilder<List<ChatMessageModel>>(
                    stream: firestore.chatMessagesStream(
                      _currentConversationId!,
                    ),
                    builder: (context, snapshot) {
                      if (_currentConversationId == null)
                        return _buildEmptyState();
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

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
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.85,
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
          // Use ValueListenableBuilder to listen to the service state
          ValueListenableBuilder<bool>(
            valueListenable: _agentService.isAgentSpeaking,
            builder: (context, isSpeaking, child) {
              return
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
                          // MIC BUTTON (New)
                          GestureDetector(
                            // Hold to talk logic
                            onLongPressStart: (_) => _startListening(),
                            onLongPressEnd: (_) => _stopListening(),
                            child: IconButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      // Click to toggle recording if user prefers click over hold
                                      if (_isListening) {
                                        _stopListening();
                                      } else if (_textController.text.isEmpty) {
                                        _startListening();
                                      } else {
                                        _sendMessage();
                                      }
                                    },
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      // If Agent is speaking, show a Volume/Wave icon
                                      isSpeaking
                                          ? Icons.graphic_eq
                                          : (_isListening
                                                ? Icons.mic
                                                : (_textController.text.isEmpty
                                                      ? Icons.mic_none
                                                      : Icons.send)),

                                      // Animate color when speaking
                                      color: isSpeaking
                                          ? Colors.greenAccent
                                          : (_isListening
                                                ? Colors.redAccent
                                                : const Color.fromARGB(
                                                    255,
                                                    184,
                                                    184,
                                                    184,
                                                  )),
                                    ),
                              // Icon(
                              //     // Change icon based on state
                              //     _isListening
                              //         ? Icons.mic
                              //         : (_textController.text.isEmpty
                              //               ? Icons.mic_none
                              //               : Icons.send),
                              //     color: _isListening ? Colors.red : null,
                              //   ),
                            ),
                          ),
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
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
                    SizedBox(height: 4),
                  ],
                ),
              );
            },
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
