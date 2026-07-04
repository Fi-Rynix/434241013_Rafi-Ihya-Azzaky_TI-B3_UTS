enum TicketFilter {
  all('', 'All'),
  open('open', 'Open'),
  assigned('assigned', 'Assigned'),
  inProgress('in_progress', 'In Progress'),
  done('done', 'Done'),
  cancelled('cancelled', 'Cancelled');

  final String statusValue;
  final String label;

  const TicketFilter(this.statusValue, this.label);
}
