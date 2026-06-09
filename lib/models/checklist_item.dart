class ChecklistItem {
  final String id;
  final String coupleId;
  final String phase;
  final String task;
  final bool isCompleted;
  final DateTime? dueDate;
  final String? linkedVendorId;
  final String? linkedVendorName;

  const ChecklistItem({
    required this.id,
    required this.coupleId,
    required this.phase,
    required this.task,
    this.isCompleted = false,
    this.dueDate,
    this.linkedVendorId,
    this.linkedVendorName,
  });

  ChecklistItem copyWith({bool? isCompleted}) => ChecklistItem(
        id: id,
        coupleId: coupleId,
        phase: phase,
        task: task,
        isCompleted: isCompleted ?? this.isCompleted,
        dueDate: dueDate,
        linkedVendorId: linkedVendorId,
        linkedVendorName: linkedVendorName,
      );
}

List<ChecklistItem> get defaultChecklist => [
      ChecklistItem(id: '1', coupleId: '', phase: '12+ Months Before', task: 'Set your total wedding budget'),
      ChecklistItem(id: '2', coupleId: '', phase: '12+ Months Before', task: 'Create your guest list estimate'),
      ChecklistItem(id: '3', coupleId: '', phase: '12+ Months Before', task: 'Choose your wedding date'),
      ChecklistItem(id: '4', coupleId: '', phase: '12+ Months Before', task: 'Decide on your wedding style/theme'),
      ChecklistItem(id: '5', coupleId: '', phase: '9–12 Months Before', task: 'Book your venue'),
      ChecklistItem(id: '6', coupleId: '', phase: '9–12 Months Before', task: 'Hire a photographer'),
      ChecklistItem(id: '7', coupleId: '', phase: '9–12 Months Before', task: 'Book catering or choose venue catering'),
      ChecklistItem(id: '8', coupleId: '', phase: '9–12 Months Before', task: 'Start planning honeymoon'),
      ChecklistItem(id: '9', coupleId: '', phase: '6–9 Months Before', task: 'Book videographer'),
      ChecklistItem(id: '10', coupleId: '', phase: '6–9 Months Before', task: 'Send save-the-dates'),
      ChecklistItem(id: '11', coupleId: '', phase: '6–9 Months Before', task: 'Book florist'),
      ChecklistItem(id: '12', coupleId: '', phase: '6–9 Months Before', task: 'Book hair & makeup artist'),
      ChecklistItem(id: '13', coupleId: '', phase: '3–6 Months Before', task: 'Order wedding dress/attire'),
      ChecklistItem(id: '14', coupleId: '', phase: '3–6 Months Before', task: 'Send formal invitations'),
      ChecklistItem(id: '15', coupleId: '', phase: '3–6 Months Before', task: 'Book music/DJ'),
      ChecklistItem(id: '16', coupleId: '', phase: '3–6 Months Before', task: 'Plan honeymoon details'),
      ChecklistItem(id: '17', coupleId: '', phase: '1–3 Months Before', task: 'Confirm all vendor bookings'),
      ChecklistItem(id: '18', coupleId: '', phase: '1–3 Months Before', task: 'Track RSVP responses'),
      ChecklistItem(id: '19', coupleId: '', phase: '1–3 Months Before', task: 'Finalize seating arrangement'),
      ChecklistItem(id: '20', coupleId: '', phase: '1 Month Before', task: 'Final dress fitting'),
      ChecklistItem(id: '21', coupleId: '', phase: '1 Month Before', task: 'Create day-of timeline'),
      ChecklistItem(id: '22', coupleId: '', phase: 'Week Of', task: 'Confirm all vendors one final time'),
      ChecklistItem(id: '23', coupleId: '', phase: 'Week Of', task: 'Prepare vendor payments/tips'),
      ChecklistItem(id: '24', coupleId: '', phase: 'Day Of', task: 'Enjoy your wedding day!'),
    ];
