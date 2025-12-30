import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageRole { user, model }

class ChatMessageModel {
  final String id;
  final String userId;
  final String text;
  final MessageRole role; // 'user' or 'model'
  final String? attachmentName; // Name of file if attached
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.role,
    this.attachmentName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'role': role.name, // Saves as 'user' or 'model' string
      'attachmentName': attachmentName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      attachmentName: map['attachmentName'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
