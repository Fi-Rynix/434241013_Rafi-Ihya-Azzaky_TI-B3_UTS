enum TicketFilter {
  all(''),
  open('open'),
  assigned('assigned'),
  inProgress('in_progress'),
  done('done'),
  cancelled('cancelled');

  final String statusValue;

  const TicketFilter(this.statusValue);
}
