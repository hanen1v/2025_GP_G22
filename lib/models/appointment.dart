class Appointment {
  final int id;
  final int lawyerId;
  final int clientId;
  final DateTime dateTime;
  final String status; // Upcoming / Active / Past ...
  final double price;
  final int timeslotId;
  final String lawyerName;
  final String lawyerNumber;
  final String lawyerPhoto;
  final bool hasFeedback;

  Appointment({
    required this.id,
    required this.lawyerId,
    required this.clientId,
    required this.dateTime,
    required this.status,
    required this.price,
    required this.timeslotId,
    required this.lawyerName,
    required this.lawyerPhoto,
    required this.lawyerNumber,
    required this.hasFeedback,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: int.parse('${json['AppointmentID']}'),
      lawyerId: int.parse('${json['LawyerID']}'),
      clientId: int.parse('${json['ClientID']}'),
      dateTime: DateTime.parse(json['DateTime']),
      status: (json['Status'] ?? '').toString(),
      price: double.tryParse('${json['Price']}') ?? 0,
      timeslotId: int.parse('${json['timeslot_id']}'),
      lawyerName: (json['LawyerName'] ?? '').toString(),
      lawyerNumber:  (json['lawyerNumber'] ?? '').toString(),
      lawyerPhoto: (json['LawyerPhoto'] ?? '').toString(),
      hasFeedback: (json['HasFeedback'] ?? 0) == 1,
    );
  }

  bool get isUpcoming => status == 'Upcoming';
  bool get isActive   => status == 'Active';
  bool get isPast     => status == 'Past';
}
