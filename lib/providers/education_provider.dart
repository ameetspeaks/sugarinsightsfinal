import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/enums/content_type.dart';
import '../core/enums/share_platform.dart';
import '../models/article.dart';
import '../models/education_category.dart';
import '../models/video.dart';
import '../services/education_service.dart';

class EducationProvider extends ChangeNotifier {
  final _educationService = EducationService(Supabase.instance.client);

  bool _isLoading = false;
  String? _error;
  List<EducationCategory> _categories = [];
  Map<String, List<Article>> _articlesByCategory = {};
  Map<String, List<Video>> _videosByCategory = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<EducationCategory> get categories => _categories;
  Map<String, List<Article>> get articlesByCategory => _articlesByCategory;
  Map<String, List<Video>> get videosByCategory => _videosByCategory;
  EducationService get educationService => _educationService;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _educationService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadArticlesForCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final articles = await _educationService.getArticles(categoryId: categoryId);
      _articlesByCategory[categoryId] = articles;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVideosForCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final videos = await _educationService.getVideos(categoryId: categoryId);
      _videosByCategory[categoryId] = videos;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite({
    required String contentId,
    required ContentType contentType,
  }) async {
    try {
      await _educationService.toggleFavorite(
        contentId: contentId,
        contentType: contentType,
      );

      // Update local state
      if (contentType == ContentType.article) {
        _articlesByCategory = Map.fromEntries(
          _articlesByCategory.entries.map((entry) {
            final articles = entry.value.map((article) {
              if (article.id == contentId) {
                return article.copyWith(isFavorite: !article.isFavorite);
              }
              return article;
            }).toList();
            return MapEntry(entry.key, articles);
          }),
        );
      } else {
        _videosByCategory = Map.fromEntries(
          _videosByCategory.entries.map((entry) {
            final videos = entry.value.map((video) {
              if (video.id == contentId) {
                return video.copyWith(isFavorite: !video.isFavorite);
              }
              return video;
            }).toList();
            return MapEntry(entry.key, videos);
          }),
        );
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> recordView({
    required String contentId,
    required ContentType contentType,
    int? viewDuration,
  }) async {
    try {
      await _educationService.recordView(
        contentId: contentId,
        contentType: contentType,
        viewDuration: viewDuration,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> recordShare({
    required String contentId,
    required ContentType contentType,
    required SharePlatform platform,
  }) async {
    try {
      await _educationService.recordShare(
        contentId: contentId,
        contentType: contentType,
        platform: platform,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> recordVideoProgress({
    required String videoId,
    required int currentPositionSeconds,
  }) async {
    try {
      await _educationService.recordView(
        contentId: videoId,
        contentType: ContentType.video,
        viewDuration: currentPositionSeconds,
      );

      // Update local state
      _videosByCategory = Map.fromEntries(
        _videosByCategory.entries.map((entry) {
          final videos = entry.value.map((video) {
            if (video.id == videoId) {
              return video.copyWith(lastPlaybackPosition: currentPositionSeconds);
            }
            return video;
          }).toList();
          return MapEntry(entry.key, videos);
        }),
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}