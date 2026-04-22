class Notification {
  final String id;
  final String title;
  final String description;
  final String time;
  final String relatedTicketId;
  final DateTime createdAt;
  final bool isRead;

  Notification({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.relatedTicketId,
    required this.createdAt,
    this.isRead = false,
  });

  // CopyWith method untuk immutability
  Notification copyWith({
    String? id,
    String? title,
    String? description,
    String? time,
    String? relatedTicketId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      relatedTicketId: relatedTicketId ?? this.relatedTicketId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
