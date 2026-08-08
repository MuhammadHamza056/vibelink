class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    this.userId = '',
    this.appVersion = '1.0.0',
    this.deviceInfo = '',
    this.createdAt,
  });

  final String id;
  final String userId;
  final int rating;
  final String comment;
  final String appVersion;
  final String deviceInfo;
  final DateTime? createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      rating: (json['rating'] ?? 5) as int,
      comment: (json['comment'] ?? '') as String,
      appVersion: (json['appVersion'] ?? '1.0.0') as String,
      deviceInfo: (json['deviceInfo'] ?? '') as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
    };
  }
}
