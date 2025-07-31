import 'package:flutter/material.dart';

class EducationCategory {
  final String id;
  final String name;
  final IconData? icon; // Made optional for backward compatibility
  final String? imagePath; // New field for custom image icons
  final String? iconName; // New field for asset icon names
  final int articleCount;
  final int blogCount;
  final String? description;

  const EducationCategory({
    required this.id,
    required this.name,
    this.icon,
    this.imagePath,
    this.iconName,
    required this.articleCount,
    required this.blogCount,
    this.description,
  });

  // Get total content count
  int get totalContent => articleCount + blogCount;

  // Get content summary text
  String get contentSummary => '$articleCount Articles And $blogCount Blogs Added';

  // Copy with method for immutability
  EducationCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    String? imagePath,
    String? iconName,
    int? articleCount,
    int? blogCount,
    String? description,
  }) {
    return EducationCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
      iconName: iconName ?? this.iconName,
      articleCount: articleCount ?? this.articleCount,
      blogCount: blogCount ?? this.blogCount,
      description: description ?? this.description,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon?.codePoint,
      'imagePath': imagePath,
      'iconName': iconName,
      'articleCount': articleCount,
      'blogCount': blogCount,
      'description': description,
    };
  }

  // JSON deserialization
  factory EducationCategory.fromJson(Map<String, dynamic> json) {
    return EducationCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] != null ? IconData(json['icon'] as int, fontFamily: 'MaterialIcons') : null,
      imagePath: json['imagePath'] as String?,
      iconName: json['icon_name'] as String?,
      articleCount: json['articleCount'] as int? ?? 0,
      blogCount: json['blogCount'] as int? ?? 0,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EducationCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EducationCategory(id: $id, name: $name, articleCount: $articleCount, blogCount: $blogCount)';
  }
} 