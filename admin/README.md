# Sugar Insights Admin Panel

A comprehensive Node.js admin panel for managing the Sugar Insights mobile application. This admin panel provides full CRUD operations for users, medications, blog content, and analytics with data export capabilities.

## Features

### 🔐 Authentication & Authorization
- JWT-based authentication
- Role-based access control
- Permission-based authorization
- Rate limiting for security

### 👥 User Management
- View all users with pagination and filters
- User profile management
- User analytics and activity logs
- User status management (active, inactive, deleted)

### 💊 Medication Management
- View all medications across users
- Medication analytics and adherence tracking
- Medication history and logs
- CRUD operations for medications

### 📝 Blog Content Management
- **Articles**: Full CRUD operations with rich text content
- **Videos**: YouTube video integration with category management
- **Categories**: Blog category management with image uploads
- Content status management (draft, published)

### 📊 Analytics & Reporting
- Dashboard analytics
- User growth tracking
- Health data analytics
- Engagement metrics
- Content performance analytics

### 📤 Data Export
- Export users data (JSON/CSV)
- Export medications data (JSON/CSV)
- Export health data (JSON/CSV)
- Export blog content (JSON/CSV)
- Comprehensive reports
- Analytics reports

## Tech Stack

- **Backend**: Node.js, Express.js
- **Database**: Supabase (PostgreSQL)
- **Authentication**: JWT, bcryptjs
- **File Upload**: Multer
- **Validation**: express-validator
- **Security**: Helmet, CORS, Rate Limiting
- **Logging**: Morgan

## Installation

1. **Clone the repository**
   ```bash
   cd admin
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**
   ```bash
   cp env.example .env
   ```
   
   Update the `.env` file with your configuration:
   ```env
   # Server Configuration
   PORT=3001
   NODE_ENV=development

   # Database Configuration (Supabase)
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

   # JWT Configuration
   JWT_SECRET=your_jwt_secret_key_here
   JWT_EXPIRES_IN=24h

   # Email Configuration
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your_email@gmail.com
   SMTP_PASS=your_email_password

   # File Upload Configuration
   UPLOAD_PATH=./uploads
   MAX_FILE_SIZE=5242880

   # Rate Limiting
   RATE_LIMIT_WINDOW_MS=900000
   RATE_LIMIT_MAX_REQUESTS=100

   # Admin Configuration
   ADMIN_EMAIL=admin@sugarinsights.com
   ADMIN_PASSWORD=admin_password_123
   ```

4. **Create uploads directory**
   ```bash
   mkdir uploads
   ```

5. **Start the server**
   ```bash
   # Development
   npm run dev

   # Production
   npm start
   ```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Admin login
- `GET /api/auth/profile` - Get admin profile
- `POST /api/auth/logout` - Logout
- `POST /api/auth/refresh` - Refresh token

### User Management
- `GET /api/users` - Get all users (with pagination and filters)
- `GET /api/users/:userId` - Get specific user
- `PUT /api/users/:userId` - Update user profile
- `DELETE /api/users/:userId` - Delete user (soft delete)
- `GET /api/users/:userId/analytics` - Get user analytics
- `GET /api/users/:userId/activity` - Get user activity log

### Medication Management
- `GET /api/medications` - Get all medications
- `GET /api/medications/:medicationId` - Get specific medication
- `POST /api/medications` - Create medication
- `PUT /api/medications/:medicationId` - Update medication
- `DELETE /api/medications/:medicationId` - Delete medication
- `GET /api/medications/:medicationId/history` - Get medication history
- `GET /api/medications/analytics/overview` - Get medication analytics

### Blog Management
- `GET /api/blog/categories` - Get all blog categories
- `POST /api/blog/categories` - Create blog category
- `PUT /api/blog/categories/:categoryId` - Update blog category
- `DELETE /api/blog/categories/:categoryId` - Delete blog category

- `GET /api/blog/articles` - Get all articles
- `GET /api/blog/articles/:articleId` - Get specific article
- `POST /api/blog/articles` - Create article
- `PUT /api/blog/articles/:articleId` - Update article
- `DELETE /api/blog/articles/:articleId` - Delete article

- `GET /api/blog/videos` - Get all videos
- `POST /api/blog/videos` - Create video
- `PUT /api/blog/videos/:videoId` - Update video
- `DELETE /api/blog/videos/:videoId` - Delete video

### Analytics
- `GET /api/analytics/dashboard` - Get dashboard analytics
- `GET /api/analytics/user-growth` - Get user growth analytics
- `GET /api/analytics/health-data` - Get health data analytics
- `GET /api/analytics/engagement` - Get engagement analytics
- `GET /api/analytics/content` - Get content analytics

### Data Export
- `GET /api/export/users` - Export users data
- `GET /api/export/medications` - Export medications data
- `GET /api/export/health-data` - Export health data
- `GET /api/export/blog` - Export blog content
- `GET /api/export/comprehensive` - Export comprehensive report
- `GET /api/export/analytics-report` - Generate analytics report

## Database Schema

The admin panel connects to the same Supabase database as the mobile app. Key tables:

### Users
- `user_profiles` - User profile information
- `admin_users` - Admin user accounts

### Health Data
- `glucose_readings` - Blood glucose readings
- `blood_pressure_readings` - Blood pressure readings
- `medications` - User medications
- `medication_history` - Medication adherence logs
- `steps_data` - Step count data

### Content
- `blog_categories` - Blog categories
- `articles` - Blog articles
- `videos` - YouTube videos

## Security Features

- **JWT Authentication**: Secure token-based authentication
- **Role-based Access Control**: Different permissions for different admin roles
- **Rate Limiting**: Prevents abuse and DDoS attacks
- **Input Validation**: All inputs are validated using express-validator
- **CORS Protection**: Configured CORS for security
- **Helmet**: Security headers for protection
- **File Upload Security**: Validated file types and size limits

## File Upload

The admin panel supports image uploads for:
- Blog category images
- Article featured images

Files are stored in the `uploads/` directory and served statically.

## Error Handling

Comprehensive error handling with:
- Database error handling
- Validation error handling
- JWT error handling
- File upload error handling
- Rate limiting error handling

## Logging

- Request logging with Morgan
- Error logging
- Database query logging
- Authentication logging

## Development

### Scripts
- `npm run dev` - Start development server with nodemon
- `npm start` - Start production server
- `npm test` - Run tests (to be implemented)

### Environment Variables
All configuration is done through environment variables. See `env.example` for all available options.

## Deployment

1. **Set up environment variables**
2. **Install dependencies**: `npm install`
3. **Create uploads directory**: `mkdir uploads`
4. **Start the server**: `npm start`

### Production Considerations
- Use a process manager like PM2
- Set up reverse proxy (nginx)
- Configure SSL certificates
- Set up monitoring and logging
- Configure database connection pooling
- Set up automated backups

## API Documentation

### Authentication Headers
All protected endpoints require the following header:
```
Authorization: Bearer <jwt_token>
```

### Response Format
All API responses follow this format:
```json
{
  "data": {...},
  "message": "Success message",
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Error Response Format
```json
{
  "error": "Error type",
  "message": "Error description",
  "details": [...],
  "timestamp": "2024-01-01T00:00:00.000Z",
  "path": "/api/endpoint"
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For support and questions, please contact the development team. 