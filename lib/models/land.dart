class Land {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String address;
  final String city;
  final String state;
  final double areaSqFt;
  final int totalSpots;
  final int twoWheelerSpots;
  final int fourWheelerSpots;
  final double pricePerHour;
  final List<String> amenities;
  final List<String> images;
  final String status;
  final double averageRating;
  final int reviewCount;
  final String ownerName;
  final String ownerPhone;

  Land({
    required this.id, required this.title, required this.description,
    required this.lat, required this.lng, required this.address,
    required this.city, required this.state, required this.areaSqFt,
    required this.totalSpots, required this.twoWheelerSpots, required this.fourWheelerSpots,
    required this.pricePerHour, required this.amenities, required this.images,
    required this.status, required this.averageRating, required this.reviewCount,
    required this.ownerName, required this.ownerPhone,
  });

  factory Land.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] ?? {};
    final coords = loc['coordinates'] ?? [0, 0];
    final owner = json['owner'] ?? {};
    return Land(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      lat: (coords[1] ?? 0).toDouble(),
      lng: (coords[0] ?? 0).toDouble(),
      address: loc['address'] ?? '',
      city: loc['city'] ?? '',
      state: loc['state'] ?? '',
      areaSqFt: (json['areaSqFt'] ?? 0).toDouble(),
      totalSpots: json['totalSpots'] ?? 0,
      twoWheelerSpots: json['twoWheelerSpots'] ?? 0,
      fourWheelerSpots: json['fourWheelerSpots'] ?? 0,
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] ?? 'pending',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      ownerName: owner['name'] ?? '',
      ownerPhone: owner['phone'] ?? '',
    );
  }
}
