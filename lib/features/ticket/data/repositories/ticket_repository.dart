import '../models/ticket_model.dart';
import '../models/comment_model.dart';

class TicketRepository {
  // Placeholder image in base64 (grey placeholder with image icon)
  static const String _placeholderImage = 'iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAALUlEQVR42mNkYPhfAQMjEwMjAyMDA6OiooICw/+GBkYGRkZGBkZGBkYGBgYGBgYA3rEHvBN3tPEAAAAASUVORK5CYII=';
  
  // Dummy tickets
  static final List<Ticket> _tickets = [
    // User 1 tickets
    Ticket(
      id: 'ticket_001',
      title: "Laptoku nggak mau nyala",
      description: 'plis ini gimana ya, aku butuh banget buat kerjaan ini',
      status: 'open',
      createdBy: 'user1',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      photoPath: _placeholderImage,
      comments: [
        Comment(
          id: 'comment_001',
          author: 'user1',
          content: 'Plis wok ini gimana jir aku butuh banget buat kerjaan ini',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
    ),
    Ticket(
      id: 'ticket_002',
      title: 'LOQ ku matot lagi',
      description: 'Woilah el matot lagi, udah aku restart berkali-kali tetep aja',
      status: 'assigned',
      createdBy: 'user1',
      assignedTo: 'udin',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      photoPath: _placeholderImage,
      comments: [
        Comment(
          id: 'comment_002',
          author: 'user1',
          content: 'Udah aku restart berkali-kali tetep aja',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Comment(
          id: 'comment_003',
          author: 'udin',
          content: 'Baik, saya akan cek segera',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    ),
    // User 2 tickets
    Ticket(
      id: 'ticket_003',
      title: 'Monitor mati total',
      description: 'Monitor saya tiba-tiba mati total, sudah saya coba ganti kabel tapi tetap saja tidak menyala',
      status: 'in_progress',
      createdBy: 'user2',
      assignedTo: 'viki',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      photoPath: _placeholderImage,
      comments: [
        Comment(
          id: 'comment_004',
          author: 'user2',
          content: 'plis ini gimana ya, aku butuh banget buat kerjaan ini',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ],
    ),
    Ticket(
      id: 'ticket_004',
      title: 'Network problem',
      description: 'Wifi di kantor sering putus-putus, sudah coba restart router tapi tetap saja',
      status: 'done',
      createdBy: 'user2',
      assignedTo: 'udin',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      photoPath: null,
      comments: [
        Comment(
          id: 'comment_005',
          author: 'user2',
          content: 'Makasih ya sudah dibantu, sekarang wifi lancar jaya',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    ),
    Ticket(
      id: 'ticket_005',
      title: 'Software installation',
      description: 'Tolong bantuin install linux di laptop saya, saya butuh buat kerjaan',
      status: 'cancelled',
      createdBy: 'user2',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      photoPath: _placeholderImage,
      comments: [],
    ),
  ];

  /// Get all tickets
  Future<List<Ticket>> getAllTickets() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tickets;
  }

  /// Get tickets by user (created by username)
  Future<List<Ticket>> getTicketsByUser(String username) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tickets.where((t) => t.createdBy == username).toList();
  }

  /// Get ticket by id
  Future<Ticket?> getTicketById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get tickets filtered by status
  Future<List<Ticket>> getTicketsByStatus(String status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tickets.where((t) => t.status == status).toList();
  }

  /// Update ticket status
  Future<Ticket?> updateTicketStatus(String ticketId, String newStatus) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = _tickets[index].copyWith(status: newStatus);
        return _tickets[index];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Assign ticket to technician
  Future<Ticket?> assignTicketToTechnician(
    String ticketId,
    String technicianUsername,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = _tickets[index].copyWith(
          assignedTo: technicianUsername,
          status: 'assigned',
        );
        return _tickets[index];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Add comment to ticket
  Future<Ticket?> addCommentToTicket(String ticketId, Comment comment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        final currentComments = List<Comment>.from(_tickets[index].comments);
        currentComments.add(comment);
        _tickets[index] = _tickets[index].copyWith(comments: currentComments);
        return _tickets[index];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create new ticket
  Future<Ticket?> createTicket(
    String title,
    String description,
    String createdBy, {
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final newTicket = Ticket(
        id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        status: 'open',
        createdBy: createdBy,
        createdAt: DateTime.now(),
        photoPath: photoPath,
      );
      _tickets.add(newTicket);
      return newTicket;
    } catch (e) {
      return null;
    }
  }
}
