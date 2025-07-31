import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/content_type.dart';
import '../../core/enums/share_platform.dart';
import '../../models/article.dart';
import '../../providers/education_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';

class BlogPostDetailScreen extends StatefulWidget {
  final Article article;

  const BlogPostDetailScreen({
    super.key,
    required this.article,
  });

  @override
  State<BlogPostDetailScreen> createState() => _BlogPostDetailScreenState();
}

class _BlogPostDetailScreenState extends State<BlogPostDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _recordView();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showAppBarTitle) {
      setState(() => _showAppBarTitle = true);
    } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
      setState(() => _showAppBarTitle = false);
    }
  }

  Future<void> _recordView() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<EducationProvider>(context, listen: false);
      await provider.recordView(
        contentId: widget.article.id,
        contentType: ContentType.article,
      );
    } catch (e) {
      setState(() => _error = 'Failed to record view: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareArticle() async {
    try {
      final provider = Provider.of<EducationProvider>(context, listen: false);
      await Share.share(
        'Check out this article: ${widget.article.title}\n\n'
        '${widget.article.summary ?? ''}\n\n'
        'Read more in the Sugar Insights app!',
        subject: widget.article.title,
      );
      await provider.recordShare(
        contentId: widget.article.id,
        contentType: ContentType.article,
        platform: SharePlatform.systemShare,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share article: $e')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const LoadingView(message: 'Loading article...')
          : _error != null
              ? ErrorView(
                  message: _error!,
                  onRetry: _recordView,
                )
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: _buildContent(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: widget.article.imageUrl != null ? 300.0 : 0.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: _showAppBarTitle ? 2 : 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: _showAppBarTitle
          ? Text(
              widget.article.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      actions: [
        Consumer<EducationProvider>(
          builder: (context, provider, child) => IconButton(
            icon: Icon(
              widget.article.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.article.isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: () => provider.toggleFavorite(
              contentId: widget.article.id,
              contentType: ContentType.article,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black),
          onPressed: _shareArticle,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: widget.article.imageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.article.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.article,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_showAppBarTitle) ...[
            Text(
              widget.article.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Metadata row
          Row(
            children: [
              if (widget.article.author != null) ...[
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  widget.article.author!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (widget.article.readTime != null) ...[
                Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${widget.article.readTime} min read',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Article content
          Text(
            widget.article.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}