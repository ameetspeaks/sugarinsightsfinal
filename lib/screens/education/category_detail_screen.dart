import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/content_type.dart';
import '../../models/education_category.dart';
import '../../providers/education_provider.dart';
import '../../widgets/education/article_card.dart';
import '../../widgets/education/video_card.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import 'blog_post_detail_screen.dart';
import 'video_player_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final EducationCategory category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await Future.wait([
      provider.loadArticlesForCategory(widget.category.id),
      provider.loadVideosForCategory(widget.category.id),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
          tabs: const [
            Tab(text: 'Articles'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
      body: Consumer<EducationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingView(message: 'Loading content...');
          }

          if (provider.error != null) {
            return ErrorView(
              message: provider.error!,
              onRetry: _loadData,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildArticlesTab(provider),
              _buildVideosTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArticlesTab(EducationProvider provider) {
    final articles = provider.articlesByCategory[widget.category.id] ?? [];

    if (articles.isEmpty) {
      return Center(
        child: Text(
          'No articles available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadArticlesForCategory(widget.category.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ArticleCard(
              article: article,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlogPostDetailScreen(
                      article: article,
                    ),
                  ),
                );
              },
              onFavorite: () {
                provider.toggleFavorite(
                  contentId: article.id,
                  contentType: ContentType.article,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideosTab(EducationProvider provider) {
    final videos = provider.videosByCategory[widget.category.id] ?? [];

    if (videos.isEmpty) {
      return Center(
        child: Text(
          'No videos available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadVideosForCategory(widget.category.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: VideoCard(
              video: video,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      video: video,
                    ),
                  ),
                );
              },
              onFavorite: () {
                provider.toggleFavorite(
                  contentId: video.id,
                  contentType: ContentType.video,
                );
              },
            ),
          );
        },
      ),
    );
  }
}