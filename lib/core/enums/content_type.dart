enum ContentType {
  article,
  video;

  String get tableName {
    switch (this) {
      case ContentType.article:
        return 'articles';
      case ContentType.video:
        return 'videos';
    }
  }
}