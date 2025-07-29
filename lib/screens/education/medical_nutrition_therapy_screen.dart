import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'blog_post_detail_screen.dart';
import 'video_player_screen.dart';
import 'article_view_screen.dart';

class MedicalNutritionTherapyScreen extends StatefulWidget {
  const MedicalNutritionTherapyScreen({super.key});

  @override
  State<MedicalNutritionTherapyScreen> createState() => _MedicalNutritionTherapyScreenState();
}

class _MedicalNutritionTherapyScreenState extends State<MedicalNutritionTherapyScreen> {
  int _selectedTabIndex = 1; // 0 for Articles, 1 for Videos (default to Videos as shown in UI)
  String _selectedFilter = 'All';
  String _selectedSort = 'Most Recent';

  final List<Map<String, dynamic>> _articles = [
    {
      'title': 'Why We Should Use Coveshield',
      'timestamp': '20-01-2025 10:25pm',
      'isFavorite': true,
      'image': 'assets/images/education/virus_article.jpg',
      'description': 'Covishield Vaccine is used for preventing COVID-19 infection. Moreover, even if you get infected, Covishield Vaccine may help reduce the severity of that infection. However, make sure to covishield Vaccine i...',
    },
    {
      'title': 'Why We Should Use Coveshield',
      'timestamp': '20-01-2025 10:25pm',
      'isFavorite': true,
      'image': 'assets/images/education/virus_article.jpg',
      'description': 'Covishield Vaccine is used for preventing COVID-19 infection. Moreover, even if you get infected, Covishield Vaccine may help reduce the severity of that infection. However, make sure to covishield Vaccine i...',
    },
    {
      'title': 'Why We Should Use Coveshield',
      'timestamp': '20-01-2025 10:25pm',
      'isFavorite': true,
      'image': 'assets/images/education/virus_article.jpg',
      'description': 'Covishield Vaccine is used for preventing COVID-19 infection. Moreover, even if you get infected, Covishield Vaccine may help reduce the severity of that infection. However, make sure to covishield Vaccine i...',
    },
  ];

  final List<Map<String, dynamic>> _videos = [
    {
      'title': 'Why We Should Use Coveshield',
      'timestamp': '20-01-2025 10:25pm',
      'isFavorite': false,
      'image': 'assets/images/education/virus_article.jpg',
      'duration': '10:45',
    },
    {
      'title': 'Why We Should Use Coveshield',
      'timestamp': '20-01-2025 10:25pm',
      'isFavorite': false,
      'image': 'assets/images/education/virus_article.jpg',
      'duration': '10:45',
    },
    {
      'title': 'Why We Should Use Coveshield',
      'timestamp': '20-01-2025 10:25pm',
      'isFavorite': false,
      'image': 'assets/images/education/virus_article.jpg',
      'duration': '10:45',
    },
  ];

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
        title: const Text(
          'Medical Nutrition Therapy',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Content Type Tabs
          _buildContentTabs(),
          
          // Filter and Sort Options
          _buildFilterOptions(),
          
          // Content List
          Expanded(
            child: _selectedTabIndex == 0 
                ? _buildArticlesList() 
                : _buildVideosList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 
                      ? AppColors.primaryColor 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Articles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTabIndex == 0 
                        ? Colors.white 
                        : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 
                      ? AppColors.primaryColor 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Videos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTabIndex == 1 
                        ? Colors.white 
                        : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Filter Dropdown
          Expanded(
            child: _buildDropdown(
              value: _selectedFilter,
              items: ['All', 'Favorites', 'Recent', 'Popular'],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          // Sort Dropdown
          Expanded(
            child: _buildDropdown(
              value: _selectedSort,
              items: ['Most Recent', 'Oldest', 'Most Popular', 'Alphabetical'],
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: Container(),
        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildArticlesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        return _buildArticleCard(article, index);
      },
    );
  }

  Widget _buildVideosList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _buildVideoCard(video, index);
      },
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                image: const DecorationImage(
                  image: AssetImage('assets/images/education/virus_article.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Article Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Favorite Icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          article['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _articles[index]['isFavorite'] = !article['isFavorite'];
                          });
                        },
                        child: Icon(
                          article['isFavorite'] 
                              ? Icons.favorite 
                              : Icons.favorite_border,
                          color: article['isFavorite'] 
                              ? Colors.green 
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Timestamp
                  Text(
                    article['timestamp'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    article['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Read More Link
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleViewScreen(
                            title: article['title'],
                            timestamp: article['timestamp'],
                            imageUrl: article['image'],
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Read More',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              title: video['title'],
              timestamp: video['timestamp'],
              videoUrl: video['image'],
              duration: video['duration'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail with Overlay
            Stack(
              children: [
                // Video Thumbnail
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: Colors.grey[200],
                    image: const DecorationImage(
                      image: AssetImage('assets/images/education/virus_article.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                // Video Overlay Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.9),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Duration and Camera Icon
                        Row(
                          children: [
                            const Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              video['duration'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Play Button
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Video Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Video Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Favorite Icon
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                video['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _videos[index]['isFavorite'] = !video['isFavorite'];
                                });
                              },
                              child: Icon(
                                video['isFavorite'] 
                                    ? Icons.favorite 
                                    : Icons.favorite_border,
                                color: video['isFavorite'] 
                                    ? Colors.green 
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Timestamp
                        Text(
                          video['timestamp'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 