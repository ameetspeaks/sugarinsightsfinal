const express = require('express');
const router = express.Router();
const { verifyToken, requirePermission } = require('../middleware/auth');
const { supabase } = require('../config/database');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads (memory storage for Supabase)
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'), false);
    }
  }
});

// Cache for blog data
const blogCache = new Map();
const BLOG_CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

// Get all blog content (articles + videos) - optimized
router.get('/', verifyToken, requirePermission('blog:read'), async (req, res) => {
  try {
    console.log('Blog route called');
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    // Check cache
    const cacheKey = `blog_${page}_${limit}`;
    const cachedData = blogCache.get(cacheKey);
    
    if (cachedData && (Date.now() - cachedData.timestamp) < BLOG_CACHE_DURATION) {
      console.log('Returning cached blog data');
      return res.json(cachedData.data);
    }

    console.log('Blog query params:', { page, limit, offset });

    // Get articles with optimized query
    console.log('Fetching articles...');
    let articles = [];
    let articlesError = null;
    
    try {
        const { data: articlesData, error: articlesDataError } = await supabase
            .from('articles')
            .select('id, title, content, author, is_published, is_featured, created_at, updated_at, blog_category_id')
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);
        
        articles = articlesData || [];
        articlesError = articlesDataError;
    } catch (err) {
        console.log('Articles table might not exist:', err.message);
        articles = [];
        articlesError = null;
    }

    console.log('Articles result:', { 
      articlesCount: articles?.length || 0, 
      articlesError: articlesError?.message 
    });

    // Get videos with optimized query
    console.log('Fetching videos...');
    let videos = [];
    let videosError = null;
    
    try {
        const { data: videosData, error: videosDataError } = await supabase
            .from('videos')
            .select('id, title, description, video_url, thumbnail_url, duration, is_published, is_featured, created_at, updated_at, category_id')
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);
        
        videos = videosData || [];
        videosError = videosDataError;
    } catch (err) {
        console.log('Videos table might not exist:', err.message);
        videos = [];
        videosError = null;
    }

    console.log('Videos result:', { 
      videosCount: videos?.length || 0, 
      videosError: videosError?.message 
    });

    if (articlesError || videosError) {
      console.error('Blog database errors:', { articlesError, videosError });
      return res.status(500).json({
        error: 'Database error',
        message: articlesError?.message || videosError?.message
      });
    }

    // Get categories with optimized query
    console.log('Fetching categories...');
    let categories = [];
    let categoriesError = null;
    
    try {
        const { data: categoriesData, error: categoriesDataError } = await supabase
            .from('education_categories')
            .select('id, name, description')
            .order('name', { ascending: true });
        
        categories = categoriesData || [];
        categoriesError = categoriesDataError;
    } catch (err) {
        console.log('Categories table might not exist:', err.message);
        categories = [];
        categoriesError = null;
    }

    console.log('Categories result:', { 
      categoriesCount: categories?.length || 0, 
      categoriesError: categoriesError?.message 
    });

    // Combine and format content
    const content = [
      ...(articles || []).map(article => ({
        ...article,
        type: 'article',
        display_type: 'Article'
      })),
      ...(videos || []).map(video => ({
        ...video,
        type: 'video',
        display_type: 'Video'
      }))
    ].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    console.log('Combined content:', { 
      totalContent: content.length,
      articles: articles?.length || 0,
      videos: videos?.length || 0,
      categories: categories?.length || 0
    });

    const responseData = {
      content,
      categories,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: content.length,
        totalPages: Math.ceil(content.length / limit)
      }
    };

    blogCache.set(cacheKey, { data: responseData, timestamp: Date.now() });
    res.json(responseData);

  } catch (error) {
    console.error('Get blog content error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Get all categories
router.get('/categories', verifyToken, requirePermission('blog:read'), async (req, res) => {
  try {
    const { data: categories, error } = await supabase
      .from('education_categories')
      .select('*')
      .order('name', { ascending: true });

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json(categories || []);
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Get single category by ID
router.get('/categories/:id', verifyToken, requirePermission('blog:read'), async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: category, error } = await supabase
      .from('education_categories')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    if (!category) {
      return res.status(404).json({
        error: 'Category not found',
        message: 'Category with the specified ID was not found'
      });
    }

    res.json(category);
  } catch (error) {
    console.error('Get category error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Create new category
router.post('/categories', verifyToken, requirePermission('blog:write'), upload.single('image'), async (req, res) => {
  try {
    const { name, description, icon_name, sort_order } = req.body;
    let imagePath = null;

    // Handle image upload to Supabase storage
    if (req.file) {
      try {
        const fileName = `category_${Date.now()}_${req.file.originalname}`;
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('educationcategories')
          .upload(fileName, req.file.buffer, {
            contentType: req.file.mimetype,
            cacheControl: '3600'
          });

        if (uploadError) {
          console.error('Storage upload error:', uploadError);
          return res.status(500).json({
            error: 'Storage upload failed',
            message: uploadError.message
          });
        }

        // Get public URL
        const { data: urlData } = supabase.storage
          .from('educationcategories')
          .getPublicUrl(fileName);

        imagePath = urlData.publicUrl;
      } catch (storageError) {
        console.error('Storage error:', storageError);
        return res.status(500).json({
          error: 'Storage error',
          message: storageError.message
        });
      }
    }

    const { data: category, error } = await supabase
      .from('education_categories')
      .insert({
        name,
        description,
        icon_name,
        image_path: imagePath,
        sort_order: sort_order ? parseInt(sort_order) : null,
        is_active: req.body.is_active === 'true' || req.body.is_active === true
      })
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(201).json(category);
  } catch (error) {
    console.error('Create category error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Update category
router.put('/categories/:id', verifyToken, requirePermission('blog:write'), upload.single('image'), async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, icon_name, sort_order } = req.body;
    let imagePath = null;

    // Handle image upload to Supabase storage
    if (req.file) {
      try {
        const fileName = `category_${Date.now()}_${req.file.originalname}`;
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('educationcategories')
          .upload(fileName, req.file.buffer, {
            contentType: req.file.mimetype,
            cacheControl: '3600'
          });

        if (uploadError) {
          console.error('Storage upload error:', uploadError);
          return res.status(500).json({
            error: 'Storage upload failed',
            message: uploadError.message
          });
        }

        // Get public URL
        const { data: urlData } = supabase.storage
          .from('educationcategories')
          .getPublicUrl(fileName);

        imagePath = urlData.publicUrl;
      } catch (storageError) {
        console.error('Storage error:', storageError);
        return res.status(500).json({
          error: 'Storage error',
          message: storageError.message
        });
      }
    }

    const updateData = { 
      name, 
      description, 
      icon_name,
      sort_order: sort_order ? parseInt(sort_order) : null,
      is_active: req.body.is_active === 'true' || req.body.is_active === true
    };
    
    if (imagePath) {
      updateData.image_path = imagePath;
    }

    const { data: category, error } = await supabase
      .from('education_categories')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json(category);
  } catch (error) {
    console.error('Update category error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Get single category
router.get('/categories/:id', verifyToken, requirePermission('blog:read'), async (req, res) => {
  try {
    const { id } = req.params;

    const { data: category, error } = await supabase
      .from('education_categories')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    if (!category) {
      return res.status(404).json({
        error: 'Category not found',
        message: 'The requested category does not exist'
      });
    }

    res.json(category);
  } catch (error) {
    console.error('Get category error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Delete category
router.delete('/categories/:id', verifyToken, requirePermission('blog:delete'), async (req, res) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('education_categories')
      .delete()
      .eq('id', id);

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json({ message: 'Category deleted successfully' });
  } catch (error) {
    console.error('Delete category error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Create new article
router.post('/articles', verifyToken, requirePermission('blog:write'), upload.single('image'), async (req, res) => {
  try {
    const { 
      title, 
      content, 
      category_id, 
      summary, 
      author, 
      read_time, 
      status, 
      is_featured 
    } = req.body;
    
    // Handle image upload to Supabase storage
    let imageUrl = null;
    if (req.file) {
      try {
        const fileName = `articles/${Date.now()}_${req.file.originalname}`;
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('articles')
          .upload(fileName, req.file.buffer, {
            contentType: req.file.mimetype,
            cacheControl: '3600'
          });

        if (uploadError) {
          console.error('Image upload error:', uploadError);
          return res.status(500).json({
            error: 'Image upload failed',
            message: uploadError.message
          });
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('articles')
          .getPublicUrl(fileName);
        
        imageUrl = publicUrl;
      } catch (uploadError) {
        console.error('Image upload error:', uploadError);
        return res.status(500).json({
          error: 'Image upload failed',
          message: uploadError.message
        });
      }
    }

    const articleData = {
      title,
      content,
      category_id,
      summary: summary || null,
      author: author || null,
      read_time: read_time ? parseInt(read_time) : null,
      is_published: status === 'published',
      is_featured: is_featured === 'true' || is_featured === true,
      image_url: imageUrl
    };

    const { data: article, error } = await supabase
      .from('articles')
      .insert(articleData)
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(201).json(article);
  } catch (error) {
    console.error('Create article error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Create new video
router.post('/videos', verifyToken, requirePermission('blog:write'), async (req, res) => {
  try {
    const { title, description, video_url, category_id } = req.body;

    const { data: video, error } = await supabase
      .from('videos')
      .insert({
        title,
        description,
        video_url,
        category_id
      })
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(201).json(video);
  } catch (error) {
    console.error('Create video error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Update article
router.put('/articles/:id', verifyToken, requirePermission('blog:write'), upload.single('image'), async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      title, 
      content, 
      category_id, 
      summary, 
      author, 
      read_time, 
      status, 
      is_featured 
    } = req.body;
    
    // Handle image upload to Supabase storage
    let imageUrl = null;
    if (req.file) {
      try {
        const fileName = `articles/${Date.now()}_${req.file.originalname}`;
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('articles')
          .upload(fileName, req.file.buffer, {
            contentType: req.file.mimetype,
            cacheControl: '3600'
          });

        if (uploadError) {
          console.error('Image upload error:', uploadError);
          return res.status(500).json({
            error: 'Image upload failed',
            message: uploadError.message
          });
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('articles')
          .getPublicUrl(fileName);
        
        imageUrl = publicUrl;
      } catch (uploadError) {
        console.error('Image upload error:', uploadError);
        return res.status(500).json({
          error: 'Image upload failed',
          message: uploadError.message
        });
      }
    }

    const updateData = {
      title,
      content,
      category_id,
      summary: summary || null,
      author: author || null,
      read_time: read_time ? parseInt(read_time) : null,
      is_published: status === 'published',
      is_featured: is_featured === 'true' || is_featured === true
    };
    
    if (imageUrl) {
      updateData.image_url = imageUrl;
    }

    const { data: article, error } = await supabase
      .from('articles')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(200).json(article);
  } catch (error) {
    console.error('Update article error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Update video
router.put('/videos/:id', verifyToken, requirePermission('blog:write'), async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, video_url, category_id } = req.body;

    const { data: video, error } = await supabase
      .from('videos')
      .update({
        title,
        description,
        video_url,
        category_id
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(200).json(video);
  } catch (error) {
    console.error('Update video error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Get single article
router.get('/articles/:id', verifyToken, requirePermission('blog:read'), async (req, res) => {
  try {
    const { id } = req.params;

    const { data: article, error } = await supabase
      .from('articles')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    if (!article) {
      return res.status(404).json({
        error: 'Article not found',
        message: 'The requested article does not exist'
      });
    }

    res.json(article);
  } catch (error) {
    console.error('Get article error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Delete article
router.delete('/articles/:id', verifyToken, requirePermission('blog:delete'), async (req, res) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('articles')
      .delete()
      .eq('id', id);

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json({ message: 'Article deleted successfully' });
  } catch (error) {
    console.error('Delete article error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Delete video
router.delete('/videos/:id', verifyToken, requirePermission('blog:delete'), async (req, res) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('videos')
      .delete()
      .eq('id', id);

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json({ message: 'Video deleted successfully' });
  } catch (error) {
    console.error('Delete video error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

module.exports = router; 