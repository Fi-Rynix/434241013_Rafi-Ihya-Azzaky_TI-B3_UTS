import '../../data/models/dashboard_model.dart';
import '../../../ticket/data/repositories/ticket_repository.dart';

class DashboardRepository {
  final TicketRepository _ticketRepository = TicketRepository();

  /// Get dashboard stats for a specific user
  Future<DashboardStats> getUserDashboardStats(String username) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final userTickets = await _ticketRepository.getTicketsByUser(username);
      return DashboardStats.fromUserTickets(userTickets);
    } catch (e) {
      return DashboardStats(
        totalTickets: 0,
        openTickets: 0,
        assignedTickets: 0,
        inProgressTickets: 0,
        doneTickets: 0,
        cancelledTickets: 0,
        activeTickets: 0,
        completedTickets: 0,
      );
    }
  }

  /// Get dashboard stats for admin (all tickets)
  Future<DashboardStats> getAdminDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final allTickets = await _ticketRepository.getAllTickets();
      return DashboardStats.fromAllTickets(allTickets);
    } catch (e) {
      return DashboardStats(
        totalTickets: 0,
        openTickets: 0,
        assignedTickets: 0,
        inProgressTickets: 0,
        doneTickets: 0,
        cancelledTickets: 0,
        activeTickets: 0,
        completedTickets: 0,
      );
    }
  }
}
