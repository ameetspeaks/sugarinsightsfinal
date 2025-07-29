import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BlogPostDetailScreen extends StatefulWidget {
  final String? title;
  final String? timestamp;
  final String? imageUrl;
  final String? content;

  const BlogPostDetailScreen({
    super.key,
    this.title,
    this.timestamp,
    this.imageUrl,
    this.content,
  });

  @override
  State<BlogPostDetailScreen> createState() => _BlogPostDetailScreenState();
}

class _BlogPostDetailScreenState extends State<BlogPostDetailScreen> {
  bool _isFavorite = true; // Default to true as shown in the UI

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
            // Header Image
            _buildHeaderImage(),
            
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

  Widget _buildHeaderImage() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        image: const DecorationImage(
          image: AssetImage('assets/images/education/virus_article.jpg'),
          fit: BoxFit.cover,
        ),
      ),
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
        // Paragraph 1
        _buildParagraph(
          'COVID-19, also known as the Coronavirus, is a global pandemic that has affected people all around the world. It first emerged in a lab in Wuhan, China, in late 2019 and quickly spread to countries around the world. This virus was reportedly caused by SARS-CoV-2. Since then, it has spread rapidly to many countries, causing widespread illness and impacting our lives in numerous ways.',
        ),
        
        const SizedBox(height: 16),
        
        // Paragraph 2
        _buildParagraph(
          'This blog talks about the details of this virus and also drafts an essay on COVID-19 in 100, 200 and 250 words for students and professionals. COVID-19, also known as the Coronavirus, is a global pandemic that has affected people all around the world.',
        ),
        
        const SizedBox(height: 16),
        
        // Paragraph 3
        _buildParagraph(
          'It first emerged in a lab in Wuhan, China, in late 2019 and quickly spread to countries around the world. This virus was reportedly caused by SARS-CoV-2.',
        ),
        
        const SizedBox(height: 16),
        
        // Additional paragraphs for more content
        _buildParagraph(
          'The impact of COVID-19 has been unprecedented, affecting every aspect of our daily lives. From healthcare systems to economies, from education to social interactions, the pandemic has reshaped how we live and work.',
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