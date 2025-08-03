const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const medicationRoutes = require('./routes/medications');
const blogRoutes = require('./routes/blog');
const analyticsRoutes = require('./routes/analytics');
const exportRoutes = require('./routes/export');
const dashboardRoutes = require('./routes/dashboard');

// Import middleware
const { rateLimiter } = require('./middleware/rateLimiter');
const { errorHandler } = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      scriptSrcAttr: ["'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      fontSrc: ["'self'", "https://fonts.gstatic.com", "https://cdnjs.cloudflare.com"],
      connectSrc: ["'self'"]
    }
  }
}));
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(rateLimiter);

// API Routes (existing)
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/medications', medicationRoutes);
app.use('/api/blog', blogRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/export', exportRoutes);
app.use('/api/dashboard', dashboardRoutes); // New dashboard API route

// Landing page route - MUST come before static file serving
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'landing.html'));
});

// App route for user dashboard (placeholder for Flutter web app)
app.get('/app', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Sugar Insights - User Dashboard</title>
            <style>
                body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
                .container { max-width: 600px; margin: 0 auto; }
                .btn { display: inline-block; padding: 15px 30px; background: #4CAF50; color: white; text-decoration: none; border-radius: 8px; margin: 10px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>User Dashboard</h1>
                <p>This is where the Flutter web app will be deployed.</p>
                <p>For now, you can access the mobile app or contact the development team.</p>
                <a href="/" class="btn">Back to Home</a>
                <a href="/admin" class="btn">Admin Panel</a>
            </div>
        </body>
        </html>
    `);
});

// Serve static files - AFTER specific routes
app.use('/admin', express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Admin frontend routes
app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/admin/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/admin/users', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/admin/medications', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/admin/blog', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/admin/analytics', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/admin/export', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/admin/settings', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'Sugar Insights Admin API is running',
        timestamp: new Date().toISOString()
    });
});

// Test database tables
app.get('/api/test-tables', async (req, res) => {
    try {
        const { supabase } = require('./config/database');
        
        // Test different tables
        const tables = ['user_profiles', 'medications', 'articles', 'videos', 'blog_categories'];
        const results = {};
        
        for (const table of tables) {
            try {
                const { data, error } = await supabase
                    .from(table)
                    .select('*')
                    .limit(1);
                
                results[table] = {
                    exists: !error,
                    count: data?.length || 0,
                    error: error?.message
                };
            } catch (err) {
                results[table] = {
                    exists: false,
                    error: err.message
                };
            }
        }
        
        res.json({
            message: 'Database table test results',
            results
        });
    } catch (error) {
        res.status(500).json({
            error: 'Database test failed',
            message: error.message
        });
    }
});

// Error handling middleware
app.use(errorHandler);

// 404 handler
app.use('*', (req, res) => {
    console.log(`404 - Route not found: ${req.originalUrl}`);
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.originalUrl} not found`
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Global error handler:', err);
    res.status(500).json({
        error: 'Internal Server Error',
        message: err.message || 'Something went wrong'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Sugar Insights Admin API running on port ${PORT}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/health`);
    console.log(`🌐 Admin Panel: http://localhost:${PORT}/admin`);
});

module.exports = app; 