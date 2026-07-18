class Booking {
  final String id;
  final String landId;
  final String landTitle;
  final String landAddress;
  final DateTime startDate;
  final DateTime endDate;
  final int duration;
  final String vehicleType;
  final int vehicleCount;
  final double totalAmount;
  final String status;

  Booking({
    required this.id, required this.landId, required this.landTitle,
    required this.landAddress, required this.startDate, required this.endDate,
    required this.duration, required this.vehicleType, required this.vehicleCount,
    required this.totalAmount, required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final land = json['land'] ?? {};
    final loc = land['location'] ?? {};
    final dates = json['eventDate'] ?? {};
    return Booking(
      id: json['_id'] ?? '',
      landId: land['_id'] ?? json['land'] ?? '',
      landTitle: land['title'] ?? '',
      landAddress: loc['address'] ?? '',
      startDate: DateTime.parse(dates['start'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(dates['end'] ?? DateTime.now().toIso8601String()),
      duration: json['duration'] ?? 0,
      vehicleType: json['vehicleType'] ?? 'four_wheeler',
      vehicleCount: json['vehicleCount'] ?? 1,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }
}
