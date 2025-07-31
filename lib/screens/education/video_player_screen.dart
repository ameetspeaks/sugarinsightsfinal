import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/content_type.dart';
import '../../core/enums/share_platform.dart';
import '../../models/video.dart';
import '../../providers/education_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video video;

  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  bool _isInitialized = false;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() => _isLoading = true);
    try {
      _videoPlayerController = VideoPlayerController.network(widget.video.videoUrl);
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        showControls: true,
        placeholder: _buildPlaceholder(),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      // Start position tracking
      _startProgressTracking();

      // Record view
      final provider = Provider.of<EducationProvider>(context, listen: false);
      await provider.recordView(
        contentId: widget.video.id,
        contentType: ContentType.video,
      );

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_videoPlayerController.value.isPlaying) {
        _updateProgress();
      }
    });
  }

  Future<void> _updateProgress() async {
    if (!mounted) return;
    try {
      final position = _videoPlayerController.value.position.inSeconds;
      final provider = Provider.of<EducationProvider>(context, listen: false);
      await provider.recordVideoProgress(
        videoId: widget.video.id,
        currentPositionSeconds: position,
      );
    } catch (e) {
      // Silently handle progress update errors
      debugPrint('Failed to update video progress: $e');
    }
  }

  Future<void> _shareVideo() async {
    try {
      final provider = Provider.of<EducationProvider>(context, listen: false);
      await Share.share(
        'Check out this video: ${widget.video.title}\n\n'
        '${widget.video.description ?? ''}\n\n'
        'Watch it in the Sugar Insights app!',
        subject: widget.video.title,
      );
      await provider.recordShare(
        contentId: widget.video.id,
        contentType: ContentType.video,
        platform: SharePlatform.systemShare,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share video: $e')),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: widget.video.thumbnailUrl != null
            ? Image.network(
                widget.video.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white54,
                    size: 80,
                  );
                },
              )
            : const Icon(
                Icons.play_circle_outline,
                color: Colors.white54,
                size: 80,
              ),
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<EducationProvider>(
            builder: (context, provider, child) => IconButton(
              icon: Icon(
                widget.video.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: widget.video.isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: () => provider.toggleFavorite(
                contentId: widget.video.id,
                contentType: ContentType.video,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareVideo,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingView(message: 'Loading video...')
          : _error != null
              ? ErrorView(
                  message: _error!,
                  onRetry: _initializePlayer,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Player
                    AspectRatio(
                      aspectRatio: _videoPlayerController.value.aspectRatio,
                      child: _isInitialized
                          ? Chewie(controller: _chewieController!)
                          : _buildPlaceholder(),
                    ),

                    // Video Info
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.video.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Metadata row
                              Row(
                                children: [
                                  if (widget.video.author != null) ...[
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.video.author!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  if (widget.video.duration != null) ...[
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.video.formattedDuration,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Description
                              if (widget.video.description != null)
                                Text(
                                  widget.video.description!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}