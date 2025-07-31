import 'package:flutter/foundation.dart';

enum ContentType {
  article,
  video;

  String get value => toString().split('.').last;
}

enum SharePlatform {
  whatsapp,
  email,
  twitter,
  facebook,
  copy;

  String get value => toString().split('.').last;
}

class UserInteraction {
  final String id;
  final String userId;
  final ContentType contentType;
  final String contentId;
  final InteractionType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const UserInteraction({
    required this.id,
    required this.userId,
    required this.contentType,
    required this.contentId,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content_type': contentType.value,
      'content_id': contentId,
      'type': type.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserInteraction.fromJson(Map<String, dynamic> json) {
    return UserInteraction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contentType: ContentType.values.firstWhere(
        (e) => e.value == json['content_type'],
      ),
      contentId: json['content_id'] as String,
      type: InteractionType.values.firstWhere(
        (e) => e.value == json['type'],
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

enum InteractionType {
  view,
  favorite,
  share;

  String get value => toString().split('.').last;
}

class ViewInteraction extends UserInteraction {
  final int? duration;
  final bool completed;

  ViewInteraction({
    required super.id,
    required super.userId,
    required super.contentType,
    required super.contentId,
    required super.createdAt,
    super.updatedAt,
    this.duration,
    this.completed = false,
  }) : super(
          type: InteractionType.view,
          metadata: {
            'duration': duration,
            'completed': completed,
          },
        );

  factory ViewInteraction.fromJson(Map<String, dynamic> json) {
    final interaction = UserInteraction.fromJson(json);
    return ViewInteraction(
      id: interaction.id,
      userId: interaction.userId,
      contentType: interaction.contentType,
      contentId: interaction.contentId,
      createdAt: interaction.createdAt,
      updatedAt: interaction.updatedAt,
      duration: interaction.metadata?['duration'] as int?,
      completed: interaction.metadata?['completed'] as bool? ?? false,
    );
  }
}

class ShareInteraction extends UserInteraction {
  final SharePlatform platform;

  ShareInteraction({
    required super.id,
    required super.userId,
    required super.contentType,
    required super.contentId,
    required super.createdAt,
    required this.platform,
  }) : super(
          type: InteractionType.share,
          metadata: {
            'platform': platform.value,
          },
        );

  factory ShareInteraction.fromJson(Map<String, dynamic> json) {
    final interaction = UserInteraction.fromJson(json);
    return ShareInteraction(
      id: interaction.id,
      userId: interaction.userId,
      contentType: interaction.contentType,
      contentId: interaction.contentId,
      createdAt: interaction.createdAt,
      platform: SharePlatform.values.firstWhere(
        (e) => e.value == interaction.metadata?['platform'],
      ),
    );
  }
}