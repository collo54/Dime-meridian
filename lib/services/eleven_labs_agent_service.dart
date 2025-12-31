import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ElevenLabsAgentService {
  WebSocketChannel? _channel;
  final AudioPlayer _player = AudioPlayer();
  final Uuid _uuid = const Uuid();
  final ValueNotifier<bool> isAgentSpeaking = ValueNotifier(false);

  // Queue system for playing chunks sequentially
  final List<String> _fileQueue = [];
  bool _isPlayingQueue = false;

  Timer? _hardTimeout;
  bool _sessionActive = false;
  bool _closing = false;

  static const int _sampleRate = 16000;
  static const Duration _maxSessionDuration = Duration(seconds: 30);

  Future<void> startSession({required String contextText}) async {
    if (_sessionActive) return;

    try {
      debugPrint("🗣️ Fetching ElevenLabs signed URL...");
      final result = await FirebaseFunctions.instance
          .httpsCallable('getAgentSignedUrl')
          .call();

      final data = Map<String, dynamic>.from(result.data);
      final signedUrl = data['signedUrl'] as String;

      debugPrint("🔌 Connecting...");
      _sessionActive = true;
      _closing = false;
      _fileQueue.clear();
      _isPlayingQueue = false;

      _channel = WebSocketChannel.connect(Uri.parse(signedUrl));

      _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          debugPrint("❌ WebSocket error: $e");
          disconnect();
        },
        onDone: () {
          debugPrint("🔌 WebSocket closed by server");
          _sessionActive = false;
          // We don't disconnect here immediately to allow the queue to finish playing
        },
      );

      _hardTimeout = Timer(_maxSessionDuration, () {
        debugPrint("⏹️ Agent hard timeout reached");
        disconnect();
      });

      _sendJson({"type": "conversation_initiation_client_data"});

      await Future.delayed(const Duration(milliseconds: 500));

      _sendJson({
        "type": "user_message",
        "text": "Summarize this data in 2 sentences: $contextText",
      });
    } catch (e) {
      debugPrint("❌ Start Session Failed: $e");
      disconnect();
    }
  }

  void _onMessage(dynamic message) async {
    if (_closing) return;

    final Map<String, dynamic> data = jsonDecode(message);
    final type = data['type'];

    switch (type) {
      case 'audio':
        // ⚡️ CRITICAL CHANGE: Process audio IMMEDIATELY
        final chunk = data['audio_event']?['audio_base_64'];
        if (chunk != null) {
          // Wrap this single chunk in a WAV header and queue it
          await _processAndQueueAudioChunk(base64Decode(chunk));
        }
        break;

      case 'agent_response':
        debugPrint(
          "🤖 Agent Text: ${data['agent_response_event']?['agent_response']}",
        );
        break;

      case 'ping':
        _sendJson({
          "type": "pong",
          "event_id": data['ping_event']?['event_id'],
        });
        break;

      case 'interruption':
        _clearQueue(); // Stop playing if interrupted
        break;
    }
  }

  // --- NEW: Queue System ---

  Future<void> _processAndQueueAudioChunk(Uint8List pcmData) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/chunk_${_uuid.v4()}.wav';
      final file = File(filePath);

      // Add WAV Header to this specific chunk
      final wavBytes = _createWavHeader(pcmData.length, _sampleRate);
      wavBytes.addAll(pcmData);

      await file.writeAsBytes(wavBytes, flush: true);

      // Add to queue and trigger playback if not already running
      _fileQueue.add(filePath);

      if (!_isPlayingQueue) {
        _playQueue();
      }
    } catch (e) {
      debugPrint("Error queuing chunk: $e");
    }
  }

  Future<void> _playQueue() async {
    if (_fileQueue.isEmpty) {
      _isPlayingQueue = false;
      isAgentSpeaking.value = false;
      return;
    }

    _isPlayingQueue = true;
    isAgentSpeaking.value = true;

    final filePath = _fileQueue.removeAt(0);

    try {
      await _player.play(DeviceFileSource(filePath));
      await _player.onPlayerComplete.first; // Wait for this chunk to finish

      // Delete temp file to save space
      File(filePath).delete().ignore();
    } catch (e) {
      debugPrint("Error playing chunk: $e");
    }

    // Play next chunk
    _playQueue();
  }

  void _clearQueue() {
    _fileQueue.clear();
    _player.stop();
    _isPlayingQueue = false;
    isAgentSpeaking.value = false;
  }

  // --- Helpers ---

  List<int> _createWavHeader(int pcmLength, int sampleRate) {
    int channels = 1;
    int byteRate = sampleRate * channels * 2;
    int totalDataLen = pcmLength + 36;

    var header = Uint8List(44);
    var view = ByteData.view(header.buffer);

    _writeString(view, 0, 'RIFF');
    view.setUint32(4, totalDataLen, Endian.little);
    _writeString(view, 8, 'WAVE');
    _writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little);
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, channels * 2, Endian.little);
    view.setUint16(34, 16, Endian.little);
    _writeString(view, 36, 'data');
    view.setUint32(40, pcmLength, Endian.little);

    return header.toList();
  }

  void _writeString(ByteData view, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      view.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  void _sendJson(Map<String, dynamic> payload) {
    if (_channel == null || _closing) return;
    _channel!.sink.add(jsonEncode(payload));
  }

  void disconnect() {
    if (_closing) return;
    _closing = true;
    _hardTimeout?.cancel();
    _channel?.sink.close();

    // Allow queue to finish playing before stopping?
    // No, disconnect usually means "Force Stop".
    _clearQueue();

    _sessionActive = false;
    debugPrint("🛑 Agent Disconnected.");
  }
}
