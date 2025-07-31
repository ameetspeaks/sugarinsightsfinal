class Video {
  final String id;
  final String categoryId;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int? duration;
  final String? author;
  final bool isFeatured;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final int? lastPlaybackPosition;

  Video({
    required this.id,
    required this.categoryId,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.duration,
    this.author,
    this.isFeatured = false,
    this.isPublished = false,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.lastPlaybackPosition,
  });

  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get watchProgress {
    if (duration == null || lastPlaybackPosition == null) return 0.0;
    return lastPlaybackPosition! / duration!;
  }

  Video copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? duration,
    String? author,
    bool? isFeatured,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    int? lastPlaybackPosition,
  }) {
    return Video(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      author: author ?? this.author,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      lastPlaybackPosition: lastPlaybackPosition ?? this.lastPlaybackPosition,
    );
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'],
      categoryId: json['category_id'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'],
      duration: json['duration'],
      author: json['author'],
      isFeatured: json['is_featured'] ?? false,
      isPublished: json['is_published'] ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isFavorite: json['user_favorites'] != null && (json['user_favorites'] as List).isNotEmpty,
      lastPlaybackPosition: json['content_views'] != null &&
              (json['content_views'] as List).isNotEmpty
          ? (json['content_views'] as List).first['view_duration']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'author': author,
      'is_featured': isFeatured,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}