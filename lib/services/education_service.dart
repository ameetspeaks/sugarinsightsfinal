import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/enums/content_type.dart';
import '../core/enums/share_platform.dart';
import '../models/article.dart';
import '../models/education_category.dart';
import '../models/video.dart';

class EducationService {
  final SupabaseClient _supabase;

  EducationService(this._supabase);

  Future<List<EducationCategory>> getCategories() async {
    try {
      final response = await _supabase
          .from('education_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      List<EducationCategory> categories = (response as List)
          .map((json) => EducationCategory.fromJson(json))
          .toList();

      // If no categories exist, insert the default blog categories
      if (categories.isEmpty) {
        await _insertDefaultCategories();
        // Fetch again after insertion
        final newResponse = await _supabase
            .from('education_categories')
            .select()
            .eq('is_active', true)
            .order('sort_order');
        
        categories = (newResponse as List)
            .map((json) => EducationCategory.fromJson(json))
            .toList();
      }

      return categories;
    } catch (e) {
      throw 'Failed to load categories: $e';
    }
  }

  Future<void> _insertDefaultCategories() async {
    try {
      final defaultCategories = [
        {
          'name': 'Medical Nutrition Therapy',
          'description': 'Learn about proper nutrition for diabetes management',
          'icon_name': 'assets/icons/blog_category/1.png',
          'is_active': true,
          'sort_order': 1,
        },
        {
          'name': 'Physical Activity & Exercise',
          'description': 'Exercise routines and physical activities for diabetes patients',
          'icon_name': 'assets/icons/blog_category/2.png',
          'is_active': true,
          'sort_order': 2,
        },
        {
          'name': 'Yoga & Diabetes',
          'description': 'Yoga practices and meditation techniques for diabetes management',
          'icon_name': 'assets/icons/blog_category/3.png',
          'is_active': true,
          'sort_order': 3,
        },
        {
          'name': 'Insulin Management Education',
          'description': 'Understanding insulin types, administration, and management',
          'icon_name': 'assets/icons/blog_category/4.png',
          'is_active': true,
          'sort_order': 4,
        },
        {
          'name': 'Weight Management',
          'description': 'Strategies for maintaining healthy weight with diabetes',
          'icon_name': 'assets/icons/blog_category/5.png',
          'is_active': true,
          'sort_order': 5,
        },
        {
          'name': 'Good Sleep Habits',
          'description': 'Importance of sleep and healthy sleep practices for diabetes',
          'icon_name': 'assets/icons/blog_category/6.png',
          'is_active': true,
          'sort_order': 6,
        },
        {
          'name': 'Diabetes Complications',
          'description': 'Understanding and preventing diabetes-related complications',
          'icon_name': 'assets/icons/blog_category/7.png',
          'is_active': true,
          'sort_order': 7,
        },
        {
          'name': 'Psychosocial Care',
          'description': 'Mental health and emotional well-being for diabetes patients',
          'icon_name': 'assets/icons/blog_category/8.png',
          'is_active': true,
          'sort_order': 8,
        },
        {
          'name': 'Intermittent Fasting',
          'description': 'Fasting protocols and their effects on diabetes management',
          'icon_name': 'assets/icons/blog_category/9.png',
          'is_active': true,
          'sort_order': 9,
        },
        {
          'name': 'Blood Pressure Management',
          'description': 'Managing blood pressure alongside diabetes care',
          'icon_name': 'assets/icons/blog_category/10.png',
          'is_active': true,
          'sort_order': 10,
        },
      ];

      await _supabase.from('education_categories').insert(defaultCategories);
    } catch (e) {
      print('Failed to insert default categories: $e');
    }
  }

  Future<List<Article>> getArticles({
    String? categoryId,
    String? query,
    int? limit,
    int? offset,
  }) async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      String selectQuery;
      
      if (user != null) {
        selectQuery = '''
          *,
          education_categories (
            id,
            name
          ),
          user_favorites!fk_user_favorites_articles (
            id
          )
        ''';
      } else {
        selectQuery = '''
          *,
          education_categories (
            id,
            name
          )
        ''';
      }
      
      var queryBuilder = _supabase.from('articles').select(selectQuery);

      // Apply filters
      queryBuilder = queryBuilder.eq('is_published', true);

      if (categoryId != null) {
        queryBuilder = queryBuilder.eq('category_id', categoryId);
      }

      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('title', '%$query%');
      }

      // Apply sorting
      final sortedQuery = queryBuilder.order('published_at', ascending: false);

      // Apply pagination
      var paginatedQuery = sortedQuery;
      if (limit != null) {
        paginatedQuery = sortedQuery.limit(limit);
      }
      if (offset != null) {
        paginatedQuery = paginatedQuery.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await paginatedQuery;

      return (response as List)
          .map((json) => Article.fromJson(json))
          .toList();
    } catch (e) {
      throw 'Failed to load articles: $e';
    }
  }

  Future<Article> getArticleById(String articleId) async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      String selectQuery;
      
      if (user != null) {
        selectQuery = '''
          *,
          education_categories (
            id,
            name
          ),
          user_favorites!fk_user_favorites_articles (
            id
          )
        ''';
      } else {
        selectQuery = '''
          *,
          education_categories (
            id,
            name
          )
        ''';
      }
      
      final response = await _supabase
          .from('articles')
          .select(selectQuery)
          .eq('id', articleId)
          .single();

      return Article.fromJson(response);
    } catch (e) {
      throw 'Failed to load article: $e';
    }
  }

  Future<List<Video>> getVideos({
    String? categoryId,
    String? query,
    int? limit,
    int? offset,
  }) async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      String selectQuery;
      
      if (user != null) {
        selectQuery = '''
          *,
          education_categories (
            id,
            name
          ),
          user_favorites!fk_user_favorites_videos (
            id
          ),
          content_views (
            view_duration
          )
        ''';
      } else {
        selectQuery = '''
          *,
          education_categories (
            id,
            name
          ),
          content_views (
            view_duration
          )
        ''';
      }
      
      var queryBuilder = _supabase.from('videos').select(selectQuery);

      // Apply filters
      queryBuilder = queryBuilder.eq('is_published', true);

      if (categoryId != null) {
        queryBuilder = queryBuilder.eq('category_id', categoryId);
      }

      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('title', '%$query%');
      }

      // Apply sorting
      final sortedQuery = queryBuilder.order('published_at', ascending: false);

      // Apply pagination
      var paginatedQuery = sortedQuery;
      if (limit != null) {
        paginatedQuery = sortedQuery.limit(limit);
      }
      if (offset != null) {
        paginatedQuery = paginatedQuery.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await paginatedQuery;

      return (response as List)
          .map((json) => Video.fromJson(json))
          .toList();
    } catch (e) {
      throw 'Failed to load videos: $e';
    }
  }

  Future<Video> getVideoById(String videoId) async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      String selectQuery;
      
      if (user != null) {
        selectQuery = '''
          *,
          education_categories (
            id,
            name
          ),
          user_favorites!fk_user_favorites_videos (
            id
          ),
          content_views (
            view_duration
          )
        ''';
      } else {
        selectQuery = '''
          *,
          education_categories (
            id,
            name
          ),
          content_views (
            view_duration
          )
        ''';
      }
      
      final response = await _supabase
          .from('videos')
          .select(selectQuery)
          .eq('id', videoId)
          .single();

      return Video.fromJson(response);
    } catch (e) {
      throw 'Failed to load video: $e';
    }
  }

  Future<void> toggleFavorite({
    required String contentId,
    required ContentType contentType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final existingFavorite = await _supabase
          .from('user_favorites')
          .select()
          .eq('user_id', userId)
          .eq('content_id', contentId)
          .eq('content_type', contentType.tableName)
          .maybeSingle();

      if (existingFavorite == null) {
        await _supabase.from('user_favorites').insert({
          'user_id': userId,
          'content_id': contentId,
          'content_type': contentType.tableName,
        });
      } else {
        await _supabase
            .from('user_favorites')
            .delete()
            .eq('id', existingFavorite['id']);
      }
    } catch (e) {
      throw 'Failed to toggle favorite: $e';
    }
  }

  Future<void> recordView({
    required String contentId,
    required ContentType contentType,
    int? viewDuration,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('content_views').insert({
        'user_id': userId,
        'content_id': contentId,
        'content_type': contentType.tableName,
        if (viewDuration != null) 'view_duration': viewDuration,
      });
    } catch (e) {
      throw 'Failed to record view: $e';
    }
  }

  Future<void> recordShare({
    required String contentId,
    required ContentType contentType,
    required SharePlatform platform,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('content_shares').insert({
        'user_id': userId,
        'content_id': contentId,
        'content_type': contentType.tableName,
        'share_platform': platform.value,
      });
    } catch (e) {
      throw 'Failed to record share: $e';
    }
  }
}