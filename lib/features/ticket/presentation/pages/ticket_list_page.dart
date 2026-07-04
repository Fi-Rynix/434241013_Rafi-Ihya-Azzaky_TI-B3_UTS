import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ticket/presentation/providers/helpdesk_provider.dart';
import '../../data/models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../models/ticket_filter_model.dart';
import './ticket_detail_page.dart';
import './create_ticket_page.dart';

class TicketListPage extends ConsumerStatefulWidget {
  const TicketListPage({super.key});

  @override
  ConsumerState<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends ConsumerState<TicketListPage> {
  TicketFilter _filter = TicketFilter.all;
  final Map<int, String> _userNames = {};
  final Map<int, String> _helpdeskNames = {};
  int? _helpdeskId;

  void _loadHelpdeskId(int idUser) async {
    if (_helpdeskId != null) return;
    try {
      final helpdeskAsync = await ref.read(helpdeskByUserProvider(idUser).future);
      if (mounted && helpdeskAsync != null) {
        setState(() => _helpdeskId = helpdeskAsync.idHelpdesk);
      }
    } catch (e) {
      print('ERROR loading helpdesk: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Center(child: Text('Not authenticated'));
    }

    // Role is stored as String directly
    final roleName = currentUser.role;

    // Load helpdesk ID if helpdesk role
    if (roleName == 'helpdesk' && _helpdeskId == null) {
      _loadHelpdeskId(currentUser.idUser);
    }

    // Get tickets based on role
    final ticketsAsync = _getTicketsAsync(currentUser, roleName);

    // Get filter options based on role
    final filterOptions = _getFilterOptions(roleName);

    return Scaffold(
      body: Column(
        children: [
          // Filter tabs (role-specific)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: filterOptions.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: filter.label,
                    isSelected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          // Ticket list
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _refreshTickets(currentUser, roleName),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
              data: (tickets) {
                // Filter tickets based on selected filter
                final filteredTickets = _filter == TicketFilter.all
                    ? tickets
                    : tickets.where((t) => t.status.value == _filter.statusValue).toList();

                // Update names cache
                _updateNamesCache(filteredTickets);

                if (filteredTickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No tickets found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _refreshTickets(currentUser, roleName);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = filteredTickets[index];
                      final isAdmin = roleName == 'admin';
                      final isHelpdesk = roleName == 'helpdesk';
                      final creatorName = _userNames[ticket.idUser] ?? 'Loading...';
                      final helpdeskName = ticket.idHelpdesk != null 
                          ? (_helpdeskNames[ticket.idHelpdesk] ?? 'Loading...')
                          : null;

                      return GestureDetector(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TicketDetailPage(ticketId: ticket.idTicket),
                            ),
                          );
                          _refreshTickets(currentUser, roleName);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Thumbnail
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    image: ticket.photoPath != null && ticket.photoPath!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(ticket.photoPath!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: ticket.photoPath == null || ticket.photoPath!.isEmpty
                                      ? Icon(
                                          Icons.image,
                                          color: Colors.grey[400],
                                          size: 30,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: isAdmin
                                      ? _buildAdminView(ticket, creatorName, helpdeskName)
                                      : isHelpdesk
                                          ? _buildHelpdeskView(ticket, creatorName)
                                          : _buildUserView(ticket),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: roleName == 'user'
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateTicketPage(),
                  ),
                );
                _refreshTickets(currentUser, roleName);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  AsyncValue<List<Ticket>> _getTicketsAsync(currentUser, String roleName) {
    switch (roleName) {
      case 'admin':
        return ref.watch(fetchAllTicketsProvider);
      case 'helpdesk':
        if (_helpdeskId != null) {
          return ref.watch(helpdeskTicketsProvider(_helpdeskId!));
        }
        return const AsyncValue.data([]);
      case 'user':
      default:
        return ref.watch(userTicketsProvider(currentUser.idUser));
    }
  }

  List<TicketFilter> _getFilterOptions(String role) {
    switch (role) {
      case 'admin':
        return [
          TicketFilter.all,
          TicketFilter.open,
          TicketFilter.assigned,
          TicketFilter.inProgress,
          TicketFilter.done,
          TicketFilter.cancelled,
        ];
      case 'helpdesk':
        return [
          TicketFilter.all,
          TicketFilter.assigned,
          TicketFilter.inProgress,
          TicketFilter.done,
        ];
      case 'user':
      default:
        return [
          TicketFilter.all,
          TicketFilter.open,
          TicketFilter.assigned,
          TicketFilter.inProgress,
          TicketFilter.done,
          TicketFilter.cancelled,
        ];
    }
  }

  void _refreshTickets(currentUser, String roleName) {
    switch (roleName) {
      case 'admin':
        ref.invalidate(fetchAllTicketsProvider);
        break;
      case 'helpdesk':
        if (_helpdeskId != null) {
          ref.invalidate(helpdeskTicketsProvider(_helpdeskId!));
        }
        break;
      case 'user':
        ref.invalidate(userTicketsProvider(currentUser.idUser));
        break;
    }
  }

  void _updateNamesCache(List<Ticket> tickets) async {
    final repo = ref.read(ticketRepositoryProvider);
    
    for (final ticket in tickets) {
      if (!_userNames.containsKey(ticket.idUser)) {
        final name = await repo.getUsernameById(ticket.idUser);
        if (mounted && name != null) {
          setState(() => _userNames[ticket.idUser] = name);
        }
      }
      
      if (ticket.idHelpdesk != null && !_helpdeskNames.containsKey(ticket.idHelpdesk)) {
        final name = await repo.getHelpdeskNameById(ticket.idHelpdesk!);
        if (mounted && name != null) {
          setState(() => _helpdeskNames[ticket.idHelpdesk!] = name);
        }
      }
    }
  }

  Widget _buildAdminView(Ticket ticket, String creatorName, String? helpdeskName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '#${ticket.idTicket}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
            _StatusBadge(status: ticket.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          ticket.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          ticket.description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'By: $creatorName',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            if (helpdeskName != null)
              Text(
                'To: $helpdeskName',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHelpdeskView(Ticket ticket, String creatorName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '#${ticket.idTicket}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
            _StatusBadge(status: ticket.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          ticket.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          ticket.description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          'By: $creatorName',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildUserView(Ticket ticket) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: _StatusBadge(status: ticket.status),
        ),
        const SizedBox(height: 8),
        Text(
          ticket.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          ticket.description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          color: _getColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case TicketStatus.open:
        return const Color(0xFFDC2626);
      case TicketStatus.assigned:
        return const Color(0xFFF97316);
      case TicketStatus.inProgress:
        return const Color(0xFF3B82F6);
      case TicketStatus.pendingUnassign:
        return const Color(0xFFA855F7);
      case TicketStatus.done:
        return const Color(0xFF10B981);
      case TicketStatus.cancelled:
        return const Color(0xFF6B7280);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000072) : const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF525252),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
