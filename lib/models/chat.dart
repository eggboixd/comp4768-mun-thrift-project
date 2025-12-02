class ChatMessage {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
        ? (map['timestamp'] is DateTime
          ? map['timestamp']
          : (map['timestamp'] as dynamic).toDate())
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
