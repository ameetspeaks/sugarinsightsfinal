import 'package:flutter/foundation.dart';

class Article {
  final String id;
  final String categoryId;
  final String title;
  final String content;
  final String? summary;
  final String? imageUrl;
  final String? author;
  final int? readTime;
  final bool isFeatured;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final int viewCount;
  final int shareCount;

  const Article({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    this.summary,
    this.imageUrl,
    this.author,
    this.readTime,
    this.isFeatured = false,
    this.isPublished = false,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.viewCount = 0,
    this.shareCount = 0,
  });

  Article copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? content,
    String? summary,
    String? imageUrl,
    String? author,
    int? readTime,
    bool? isFeatured,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    int? viewCount,
    int? shareCount,
  }) {
    return Article(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      readTime: readTime ?? this.readTime,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      viewCount: viewCount ?? this.viewCount,
      shareCount: shareCount ?? this.shareCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'content': content,
      'summary': summary,
      'image_url': imageUrl,
      'author': author,
      'read_time': readTime,
      'is_featured': isFeatured,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_favorite': isFavorite,
      'view_count': viewCount,
      'share_count': shareCount,
    };
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      imageUrl: json['image_url'] as String?,
      author: json['author'] as String?,
      readTime: json['read_time'] as int?,
      isFeatured: json['is_featured'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isFavorite: json['user_favorites'] != null && (json['user_favorites'] as List).isNotEmpty,
      viewCount: json['view_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Article && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Article(id: $id, title: $title, categoryId: $categoryId)';
  }
}