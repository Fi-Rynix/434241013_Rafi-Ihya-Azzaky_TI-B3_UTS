import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class CommentRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get comments by ticket ID
  Future<List<Comment>> getCommentsByTicket(int idTicket) async {
    try {
      // Fetch comments
      final response = await _client
          .from('comments')
          .select()
          .eq('id_ticket', idTicket)
          .order('created_at', ascending: true);

      final comments = (response as List).map((json) => Comment.fromJson(json)).toList();
      
      if (comments.isEmpty) return comments;
      
      // Fetch usernames
      final userIds = comments.map((c) => c.idUser).toSet().toList();
      final usersResponse = await _client
          .from('users')
          .select('id_user, username')
          .filter('id_user', 'in', '(${userIds.join(",")})');
      
      final userMap = <int, String>{};
      for (final user in (usersResponse as List)) {
        userMap[user['id_user'] as int] = user['username'] as String;
      }
      
      // Fetch attachments for each comment
      final commentIds = comments.map((c) => c.idComment).toList();
      final attachmentsResponse = await _client
          .from('comment_attachments')
          .select()
          .filter('id_comment', 'in', '(${commentIds.join(",")})');
      
      final attachmentsMap = <int, List<CommentAttachment>>{};
      for (final att in (attachmentsResponse as List)) {
        final attachment = CommentAttachment.fromJson(att);
        attachmentsMap.putIfAbsent(attachment.idComment, () => []).add(attachment);
      }
      
      return comments.map((c) => c.copyWith(
        username: userMap[c.idUser],
        attachments: attachmentsMap[c.idComment],
      )).toList();
    } catch (e) {
      print('Error fetching comments: $e');
      rethrow;
    }
  }

  /// Add comment
  Future<Comment?> addComment({
    required int idTicket,
    required int idUser,
    required String message,
  }) async {
    try {
      final response = await _client
          .from('comments')
          .insert({
            'id_ticket': idTicket,
            'id_user': idUser,
            'message': message,
          })
          .select()
          .single();

      return Comment.fromJson(response);
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Upload attachment to comment
  Future<CommentAttachment?> uploadAttachment({
    required int idComment,
    required String filePath,
    required String mimeType,
    required int fileSize,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final storagePath = 'comment-attachments/$idComment/$fileName';
      
      // Upload to storage
      final file = File(filePath);
      await _client.storage.from('comment-attachments').upload(
        storagePath,
        file,
      );
      
      // Get public URL
      final publicUrl = _client.storage.from('comment-attachments').getPublicUrl(storagePath);
      
      // Insert attachment record
      final response = await _client
          .from('comment_attachments')
          .insert({
            'id_comment': idComment,
            'storage_path': publicUrl,
            'mime_type': mimeType,
            'file_size': fileSize,
          })
          .select()
          .single();
      
      return CommentAttachment.fromJson(response);
    } catch (e) {
      print('Error uploading attachment: $e');
      rethrow;
    }
  }

  /// Edit comment (only by author)
  Future<Comment?> editComment({
    required int idComment,
    required int idUser,
    required String message,
  }) async {
    try {
      final response = await _client
          .from('comments')
          .update({
            'message': message,
            'is_edited': true,
          })
          .eq('id_comment', idComment)
          .eq('id_user', idUser)
          .select()
          .maybeSingle();

      if (response == null) return null;
      return Comment.fromJson(response);
    } catch (e) {
      print('Error editing comment: $e');
      rethrow;
    }
  }

  /// Delete comment (only by author)
  Future<bool> deleteComment({
    required int idComment,
    required int idUser,
  }) async {
    try {
      final response = await _client
          .from('comments')
          .delete()
          .eq('id_comment', idComment)
          .eq('id_user', idUser)
          .select()
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }
}
