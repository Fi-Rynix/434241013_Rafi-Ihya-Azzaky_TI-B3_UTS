import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ticket/presentation/providers/helpdesk_provider.dart';
import '../../data/models/ticket_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/ticket_provider.dart';
import '../providers/ticket_pagination.dart';
import '../providers/ticket_pagination_provider.dart';
import '../models/ticket_filter_model.dart';
import './ticket_detail_page.dart';
import './create_ticket_page.dart';
import '../../../../shared/widgets/load_more_button.dart';

class TicketListPage extends ConsumerStatefulWidget {
  const TicketListPage({super.key});

  @override
  ConsumerState<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends ConsumerState<TicketListPage> {
  TicketFilter _filter = TicketFilter.all; // default All for all roles
  final Map<int, String> _userNames = {};
  final Map<int, String> _helpdeskNames = {};
  int? _helpdeskId;

  @override
  void initState() {
    super.initState();
    // Load first page after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        if (user.role == 'helpdesk') {
          // All roles default to 'all' now
          _filter = TicketFilter.all;
          _loadHelpdeskIdAndRefresh(user.idUser);
        } else if (user.role == 'admin') {
          _filter = TicketFilter.all;
          ref.read(paginatedAllTicketsProvider.notifier).loadFirstPage();
        } else {
          _filter = TicketFilter.all;
          ref.read(paginatedUserTicketsProvider.notifier).loadFirstPage();
        }
      }
    });
  }

  Future<void> _loadHelpdeskIdAndRefresh(int idUser) async {
    if (_helpdeskId != null) {
      // Already have helpdesk id — load using current filter
      if (_filter == TicketFilter.all) {
        ref.read(paginatedMyHelpdeskTicketsProvider.notifier).loadFirstPage();
      } else {
        ref.read(paginatedTicketsByStatusProvider(_filter.statusValue).notifier).loadFirstPage();
      }
      return;
    }
    try {
      final helpdeskAsync = await ref.read(helpdeskByUserProvider(idUser).future);
      if (mounted && helpdeskAsync != null) {
        setState(() => _helpdeskId = helpdeskAsync.idHelpdesk);
        // Load with current filter
        if (_filter == TicketFilter.all) {
          ref.read(paginatedMyHelpdeskTicketsProvider.notifier).loadFirstPage();
        } else {
          ref.read(paginatedTicketsByStatusProvider(_filter.statusValue).notifier).loadFirstPage();
        }
      }
    } catch (e) {
      print('ERROR loading helpdesk: $e');
    }
  }

  void _onFilterChanged(TicketFilter filter) {
    setState(() => _filter = filter);
    final notifier = ref.read(paginatedTicketsByStatusProvider(filter.statusValue).notifier);
    notifier.loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Center(child: Text('Not authenticated'));
    }

    final roleName = currentUser.role;
    final filterOptions = _getFilterOptions(roleName);

    // Watch paginated state based on current filter & role
    // - 'all' for helpdesk → current helpdesk's tickets (any status)
    // - 'all' for admin → all tickets in system
    // - 'all' for user → current user's tickets
    // - specific status → filter by status (all roles)
    final paginationState = _filter == TicketFilter.all
        ? (roleName == 'admin'
            ? ref.watch(paginatedAllTicketsProvider)
            : roleName == 'helpdesk'
                ? ref.watch(paginatedMyHelpdeskTicketsProvider)
                : ref.watch(paginatedUserTicketsProvider))
        : ref.watch(paginatedTicketsByStatusProvider(_filter.statusValue));

    return Scaffold(
      body: Column(
        children: [
          // Compact filter dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.filter_alt_outlined, size: 18, color: AppTheme.iconStroke(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TicketFilter>(
                      isExpanded: true,
                      value: _filter,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: filterOptions.map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      )).toList(),
                      onChanged: (f) {
                        if (f != null) _onFilterChanged(f);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Ticket list with pagination
          Expanded(
            child: _buildTicketList(context, currentUser, roleName, paginationState),
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
                ref.read(paginatedUserTicketsProvider.notifier).refresh();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTicketList(
    BuildContext context,
    dynamic currentUser,
    String roleName,
    PaginationState<Ticket> paginationState,
  ) {
    if (paginationState.isLoading && paginationState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (paginationState.error != null && paginationState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${paginationState.error}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _refreshPaginated(roleName),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final tickets = paginationState.items;

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No tickets found', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    // Update names cache
    _updateNamesCache(tickets);

    return RefreshIndicator(
      onRefresh: () async => _refreshPaginated(roleName),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tickets.length + 1, // +1 for Load More button
        itemBuilder: (context, index) {
          if (index == tickets.length) {
            // Load More button at bottom
            return LoadMoreButton(
              isLoading: paginationState.isLoading,
              hasMore: paginationState.hasMore,
              onPressed: () {
                // If 'all' is selected, use role-specific all-tickets provider
                final notifier = _filter == TicketFilter.all
                    ? (roleName == 'admin'
                        ? ref.read(paginatedAllTicketsProvider.notifier)
                        : roleName == 'helpdesk'
                            ? ref.read(paginatedMyHelpdeskTicketsProvider.notifier)
                            : ref.read(paginatedUserTicketsProvider.notifier))
                    : ref.read(paginatedTicketsByStatusProvider(_filter.statusValue).notifier);
                notifier.loadMore();
              },
              currentCount: tickets.length,
            );
          }

          final ticket = tickets[index];
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
              _refreshPaginated(roleName);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                          ? Icon(Icons.image, color: Colors.grey[400], size: 30)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isAdmin
                          ? _buildAdminView(ticket, creatorName, helpdeskName)
                          : isHelpdesk
                              ? _buildHelpdeskView(ticket, creatorName)
                              : _buildUserView(context, ticket, helpdeskName),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _refreshPaginated(String roleName) {
    if (_filter == TicketFilter.all) {
      if (roleName == 'admin') {
        ref.read(paginatedAllTicketsProvider.notifier).refresh();
      } else if (roleName == 'helpdesk') {
        ref.read(paginatedMyHelpdeskTicketsProvider.notifier).refresh();
      } else {
        ref.read(paginatedUserTicketsProvider.notifier).refresh();
      }
    } else {
      ref.read(paginatedTicketsByStatusProvider(_filter.statusValue).notifier).refresh();
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

  void _updateNamesCache(List<Ticket> tickets) async {
    final repo = ref.read(ticketRepositoryProvider);

    for (final ticket in tickets) {
      if (!_userNames.containsKey(ticket.idUser)) {
        repo.getUsernameById(ticket.idUser).then((name) {
          if (mounted && name != null) {
            setState(() => _userNames[ticket.idUser] = name);
          }
        });
      }

      if (ticket.idHelpdesk != null && !_helpdeskNames.containsKey(ticket.idHelpdesk)) {
        repo.getHelpdeskNameById(ticket.idHelpdesk!).then((name) {
          if (mounted && name != null) {
            setState(() => _helpdeskNames[ticket.idHelpdesk!] = name);
          }
        });
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
            Text('#${ticket.idTicket}', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
            _StatusBadge(status: ticket.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(ticket.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(ticket.description, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('By: $creatorName', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            if (helpdeskName != null)
              Text('To: $helpdeskName', style: const TextStyle(fontSize: 11, color: Colors.blue)),
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
            Text('#${ticket.idTicket}', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
            _StatusBadge(status: ticket.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(ticket.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(ticket.description, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Text('By: $creatorName', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildUserView(BuildContext context, Ticket ticket, String? helpdeskName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('#${ticket.idTicket}', style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context), fontWeight: FontWeight.w600)),
            _StatusBadge(status: ticket.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          ticket.title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryText(context)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          ticket.description,
          style: TextStyle(fontSize: 13, color: AppTheme.textSubtle(context)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (ticket.idHelpdesk != null && helpdeskName != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Oleh: Saya', style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
              Text('Ke: $helpdeskName', style: TextStyle(fontSize: 11, color: AppTheme.iconStroke(context), fontWeight: FontWeight.w600)),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Oleh: Saya', style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
            ],
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;

  const _StatusBadge({required this.status});

  String _key() {
    switch (status) {
      case TicketStatus.open: return 'open';
      case TicketStatus.assigned: return 'assigned';
      case TicketStatus.inProgress: return 'inProgress';
      case TicketStatus.pendingUnassign: return 'pendingUnassign';
      case TicketStatus.done: return 'done';
      case TicketStatus.cancelled: return 'cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.badgeColors(context, _key());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 9, color: colors.text, fontWeight: FontWeight.bold, letterSpacing: 0.3),
      ),
    );
  }

  Color _getColor() => Colors.transparent; // legacy no-op
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  // kept for backwards compatibility — not used after dropdown refactor
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}