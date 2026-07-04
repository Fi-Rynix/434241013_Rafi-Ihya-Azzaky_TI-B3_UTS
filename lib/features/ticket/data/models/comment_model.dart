class Comment {
  final int idComment;
  final int idTicket;
  final int idUser;
  final String message;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined data
  final String? username;

  // Attachment info
  final List<CommentAttachment>? attachments;

  Comment({
    required this.idComment,
    required this.idTicket,
    required this.idUser,
    required this.message,
    required this.isEdited,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.attachments,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    List<CommentAttachment>? attachments;
    if (json['attachments'] != null) {
      attachments = (json['attachments'] as List)
          .map((a) => CommentAttachment.fromJson(a))
          .toList();
    }
    
    return Comment(
      idComment: json['id_comment'] as int,
      idTicket: json['id_ticket'] as int,
      idUser: json['id_user'] as int,
      message: json['message'] as String,
      isEdited: json['is_edited'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      username: json['username'] as String?,
      attachments: attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_comment': idComment,
      'id_ticket': idTicket,
      'id_user': idUser,
      'message': message,
      'is_edited': isEdited,
    };
  }

  Comment copyWith({
    int? idComment,
    int? idTicket,
    int? idUser,
    String? message,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    List<CommentAttachment>? attachments,
  }) {
    return Comment(
      idComment: idComment ?? this.idComment,
      idTicket: idTicket ?? this.idTicket,
      idUser: idUser ?? this.idUser,
      message: message ?? this.message,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      attachments: attachments ?? this.attachments,
    );
  }
}

class CommentAttachment {
  final int idCommentAttachment;
  final int idComment;
  final String storagePath;
  final String mimeType;
  final int fileSize;
  final DateTime uploadedAt;

  CommentAttachment({
    required this.idCommentAttachment,
    required this.idComment,
    required this.storagePath,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory CommentAttachment.fromJson(Map<String, dynamic> json) {
    return CommentAttachment(
      idCommentAttachment: json['id_comment_attachment'] as int,
      idComment: json['id_comment'] as int,
      storagePath: json['storage_path'] as String,
      mimeType: json['mime_type'] as String,
      fileSize: json['file_size'] as int,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  String get publicUrl {
    // Assuming Supabase storage public URL format
    return storagePath;
  }
}
