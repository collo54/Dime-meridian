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

  // Buffer for Raw PCM Data
  final List<int> _pcmBuffer = [];

  Timer? _hardTimeout;
  bool _sessionActive = false;
  bool _closing = false;

  // ElevenLabs Agents usually stream at 16kHz (16000)
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
      _pcmBuffer.clear();

      _channel = WebSocketChannel.connect(Uri.parse(signedUrl));

      _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          debugPrint("❌ WebSocket error: $e");
          disconnect();
        },
        onDone: () {
          debugPrint("🔌 WebSocket closed by server");
          // If the server closes the connection (normal end of turn),
          // play whatever audio we managed to buffer.
          if (_pcmBuffer.isNotEmpty) {
            _playBufferedAudio();
          }
          _sessionActive = false;
        },
      );

      _hardTimeout = Timer(_maxSessionDuration, () {
        debugPrint("⏹️ Agent hard timeout reached");
        disconnect();
      });

      // 1️⃣ Send Initiation (Required by Spec)
      // We accept the default PCM stream.
      _sendJson({
        "type": "conversation_initiation_client_data",
        // Optional: You can still set voice settings here if needed
        // "conversation_config_override": { "tts": { "stability": 0.5 } }
      });

      // 2️⃣ Wait briefly for handshake
      await Future.delayed(const Duration(milliseconds: 500));

      // 3️⃣ Send Text Prompt
      // The agent interprets "user_message" as speech to respond to.
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

    // The spec uses 'type' to identify messages
    final type = data['type'];

    switch (type) {
      case 'audio':
        // Spec: "audio_event" contains "audio_base_64"
        final chunk = data['audio_event']?['audio_base_64'];
        if (chunk != null) {
          _pcmBuffer.addAll(base64Decode(chunk));
        }
        break;

      case 'agent_response':
        // Spec: "agent_response_event" contains "agent_response"
        debugPrint(
          "🤖 Agent Text: ${data['agent_response_event']?['agent_response']}",
        );
        break;

      case 'ping':
        // Spec: Respond with 'pong' and 'event_id'
        _sendJson({
          "type": "pong",
          "event_id": data['ping_event']?['event_id'],
        });
        break;

      case 'interruption':
        // If we interrupted the agent, clear buffer
        _pcmBuffer.clear();
        break;
    }
  }

  Future<void> _playBufferedAudio() async {
    if (_pcmBuffer.isEmpty) return;

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/agent_${_uuid.v4()}.wav');

      // 1. Add WAV Header to Raw PCM
      // This tricks Android into playing the raw data correctly
      final wavBytes = _createWavHeader(_pcmBuffer.length, _sampleRate);
      wavBytes.addAll(_pcmBuffer);

      await file.writeAsBytes(wavBytes, flush: true);

      debugPrint("🎵 Playing generated WAV (${file.lengthSync()} bytes)...");

      // Notify UI: START
      isAgentSpeaking.value = true;

      await _player.play(DeviceFileSource(file.path));

      // Wait for playback to finish
      await _player.onPlayerComplete.first;
    } catch (e) {
      debugPrint("❌ Audio Playback Error: $e");
    } finally {
      // Notify UI: STOP (Even if error occurs)
      isAgentSpeaking.value = false;
    }
  }

  /// Creates a standard WAV header for 16-bit Mono PCM audio
  List<int> _createWavHeader(int pcmLength, int sampleRate) {
    int channels = 1;
    int byteRate = sampleRate * channels * 2; // 16-bit = 2 bytes
    int totalDataLen = pcmLength + 36;

    var header = Uint8List(44);
    var view = ByteData.view(header.buffer);

    _writeString(view, 0, 'RIFF');
    view.setUint32(4, totalDataLen, Endian.little);
    _writeString(view, 8, 'WAVE');
    _writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little); // PCM
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, channels * 2, Endian.little);
    view.setUint16(34, 16, Endian.little); // 16-bit
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
    isAgentSpeaking.value = false; // Reset UI
    _closing = true;
    _hardTimeout?.cancel();
    _channel?.sink.close();
    _player.stop();
    _sessionActive = false;
    debugPrint("🛑 Agent Disconnected.");
  }
}
