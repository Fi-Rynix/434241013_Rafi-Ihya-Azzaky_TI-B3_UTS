import 'comment_model.dart';

class Ticket {
  final String id;
  final String title;
  final String description;
  final String status; // "open", "assigned", "in_progress", "done", "cancelled"
  final String createdBy; // username of user who created
  final String? assignedTo; // username of technician
  final DateTime createdAt;
  final List<Comment> comments;
  final String? photoPath; // Path to photo file or base64 string

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdBy,
    this.assignedTo,
    required this.createdAt,
    this.comments = const [],
    this.photoPath,
  });

  // Method untuk update status
  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? createdBy,
    String? assignedTo,
    DateTime? createdAt,
    List<Comment>? comments,
    String? photoPath,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      comments: comments ?? this.comments,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
