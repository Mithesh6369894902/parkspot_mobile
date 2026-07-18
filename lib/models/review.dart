class Review {
  final String id;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({required this.id, required this.userName, required this.rating, required this.comment, required this.createdAt});

  factory Review.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    return Review(
      id: json['_id'] ?? '',
      userName: user['name'] ?? 'Anonymous',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
