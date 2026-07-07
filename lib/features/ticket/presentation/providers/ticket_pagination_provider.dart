import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/helpdesk_provider.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';
import 'ticket_provider.dart';
import 'ticket_pagination.dart';

/// Paginated tickets for current user (or all if admin)
class PaginatedTicketsNotifier extends PaginationNotifier<Ticket> {
  final Ref ref;
  final String? roleFilter;
  final int? userId;
  final int? helpdeskId;
  final Future<List<Ticket>> Function({DateTime? cursor, int limit})? customFetcher;

  PaginatedTicketsNotifier(
    this.ref, {
    this.roleFilter,
    this.userId,
    this.helpdeskId,
    this.customFetcher,
  }) : super(
          fetcher: customFetcher ?? _defaultFetcher(ref, roleFilter: roleFilter, userId: userId, helpdeskId: helpdeskId),
        );
}

Future<List<Ticket>> Function({DateTime? cursor, int limit}) _defaultFetcher(
  Ref ref, {
  String? roleFilter,
  int? userId,
  int? helpdeskId,
}) {
  return ({DateTime? cursor, int limit = 20}) async {
    final repo = ref.read(ticketRepositoryProvider);
    if (roleFilter != null && roleFilter != 'all') {
      return repo.getTicketsByStatus(roleFilter, cursor: cursor, limit: limit);
    }
    if (helpdeskId != null) {
      return repo.getTicketsByHelpdesk(helpdeskId, cursor: cursor, limit: limit);
    }
    if (userId != null) {
      return repo.getTicketsByUser(userId, cursor: cursor, limit: limit);
    }
    return repo.getAllTickets(cursor: cursor, limit: limit);
  };
}

/// Family provider for current user tickets
final paginatedUserTicketsProvider =
    StateNotifierProvider<PaginatedTicketsNotifier, PaginationState<Ticket>>((ref) {
  final user = ref.watch(currentUserProvider);
  return PaginatedTicketsNotifier(ref, userId: user?.idUser);
});

/// Family provider for all tickets (admin view)
final paginatedAllTicketsProvider =
    StateNotifierProvider<PaginatedTicketsNotifier, PaginationState<Ticket>>((ref) {
  return PaginatedTicketsNotifier(ref);
});

/// Family provider for tickets filtered by status
final paginatedTicketsByStatusProvider = StateNotifierProvider.family<
    PaginatedTicketsNotifier, PaginationState<Ticket>, String>((ref, status) {
  return PaginatedTicketsNotifier(ref, roleFilter: status);
});

/// Family provider for helpdesk tickets
final paginatedHelpdeskTicketsProvider =
    StateNotifierProvider<PaginatedTicketsNotifier, PaginationState<Ticket>>((ref) {
  return PaginatedTicketsNotifier(ref);
});

/// Provider for current helpdesk's tickets (all statuses combined).
/// Used by helpdesk when "Semua" filter is selected.
final paginatedMyHelpdeskTicketsProvider =
    StateNotifierProvider<PaginatedTicketsNotifier, PaginationState<Ticket>>((ref) {
  return PaginatedTicketsNotifier(
    ref,
    customFetcher: ({DateTime? cursor, int limit = 20}) async {
      final user = ref.read(currentUserProvider);
      if (user == null) return [];
      final helpdeskAsync = await ref.read(helpdeskByUserProvider(user.idUser).future);
      if (helpdeskAsync == null) return [];
      final repo = ref.read(ticketRepositoryProvider);
      return repo.getTicketsByHelpdesk(
        helpdeskAsync.idHelpdesk,
        cursor: cursor,
        limit: limit,
      );
    },
  );
});
