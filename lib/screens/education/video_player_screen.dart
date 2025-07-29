import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String? title;
  final String? timestamp;
  final String? videoUrl;
  final String? duration;

  const VideoPlayerScreen({
    super.key,
    this.title,
    this.timestamp,
    this.videoUrl,
    this.duration,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _isFavorite = false; // Default to false as shown in the UI
  bool _isPlaying = false;
  double _progress = 0.3; // 30% progress as shown in UI
  bool _isMuted = false;
  bool _isFullscreen = false;

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
          widget.title ?? 'Why we should use coveshielda',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player
            _buildVideoPlayer(),
            
            // Article Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Favorite Icon
                  _buildTitleSection(),
                  
                  const SizedBox(height: 8),
                  
                  // Timestamp
                  _buildTimestamp(),
                  
                  const SizedBox(height: 24),
                  
                  // Article Content
                  _buildArticleContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        image: const DecorationImage(
          image: AssetImage('assets/images/education/virus_article.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Video Controls Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Column(
                children: [
                  // Progress Bar
                  _buildProgressBar(),
                  
                  const SizedBox(height: 8),
                  
                  // Control Buttons
                  _buildControlButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        // Progress Bar
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        // Folder Icon
        IconButton(
          onPressed: () {
            // TODO: Implement playlist functionality
          },
          icon: const Icon(
            Icons.folder,
            color: Colors.white,
            size: 18,
          ),
        ),
        
        const SizedBox(width: 4),
        
        // Volume Control
        IconButton(
          onPressed: () {
            setState(() {
              _isMuted = !_isMuted;
            });
          },
          icon: Icon(
            _isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 18,
          ),
        ),
        
        const Spacer(),
        
        // Playback Controls
        IconButton(
          onPressed: () {
            // TODO: Implement rewind
          },
          icon: const Icon(
            Icons.replay_10,
            color: Colors.white,
            size: 18,
          ),
        ),
        
        IconButton(
          onPressed: () {
            setState(() {
              _isPlaying = !_isPlaying;
            });
          },
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 24,
          ),
        ),
        
        IconButton(
          onPressed: () {
            // TODO: Implement fast forward
          },
          icon: const Icon(
            Icons.forward_10,
            color: Colors.white,
            size: 18,
          ),
        ),
        
        IconButton(
          onPressed: () {
            // TODO: Implement skip to end
          },
          icon: const Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 18,
          ),
        ),
        
        const Spacer(),
        
        // Settings
        IconButton(
          onPressed: () {
            // TODO: Implement settings
          },
          icon: const Icon(
            Icons.settings,
            color: Colors.white,
            size: 18,
          ),
        ),
        
        const SizedBox(width: 4),
        
        // Fullscreen
        IconButton(
          onPressed: () {
            setState(() {
              _isFullscreen = !_isFullscreen;
            });
          },
          icon: Icon(
            _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Row(
      children: [
        // Title
        Expanded(
          child: Text(
            widget.title ?? 'Why We Should Use Coveshield',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Favorite Icon
        GestureDetector(
          onTap: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.green : Colors.grey,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp() {
    return Text(
      widget.timestamp ?? '20-01-2025 10:25pm',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildArticleContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Article Content
        _buildParagraph(
          'COVID-19, also known as the Coronavirus, is a global pandemic that has affected people all around the world. It first emerged in a lab in Wuhan, China, in late 2019 and quickly spread to countries around the world. This virus was reportedly caused by SARS-CoV-2. Since then, it has spread rapidly to many countries, causing widespread illness and impacting our lives in numerous ways.',
        ),
        
        const SizedBox(height: 16),
        
        _buildParagraph(
          'This video provides detailed information about the COVID-19 virus, its origins, and the importance of vaccination in preventing the spread of the disease.',
        ),
        
        const SizedBox(height: 16),
        
        _buildParagraph(
          'Vaccination has become a crucial tool in our fight against this virus. Vaccines like Covishield have been developed to help prevent infection and reduce the severity of illness in those who do get infected.',
        ),
        
        const SizedBox(height: 16),
        
        _buildParagraph(
          'It is important to follow public health guidelines, maintain good hygiene practices, and stay informed about the latest developments in our ongoing battle against COVID-19.',
        ),
      ],
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );
  }
} 