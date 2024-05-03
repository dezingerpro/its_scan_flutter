class GateAssignment {
  final int gateAssignmentId;
  final int gateId;
  final int miqaatId;
  final int memberId;

  GateAssignment({
    required this.gateAssignmentId,
    required this.gateId,
    required this.miqaatId,
    required this.memberId,
  });

  factory GateAssignment.fromJson(Map<String, dynamic> json) {
    return GateAssignment(
      gateAssignmentId: json['gate_assignment_id'],
      gateId: json['gate_id'],
      miqaatId: json['miqaat_id'],
      memberId: json['member_id'],
    );
  }
}