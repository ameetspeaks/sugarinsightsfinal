# Sugar Insights Database Migration System

This directory contains the SQL migration files for the Sugar Insights application database. Both SQLite and PostgreSQL versions are provided.

## Migration Files

### SQLite Versions (for local development)
- `001_initial_schema.sql` - Core authentication and user management tables
- `002_additional_auth_tables.sql` - Additional authentication features

### PostgreSQL Versions (for production)
- `001_initial_schema_postgres.sql` - Core authentication and user management tables
- `002_additional_auth_tables_postgres.sql` - Additional authentication features

## Core Tables (Both Versions)

**Core Tables:**
- `roles` - User roles and permissions
- `users` - Core user authentication data
- `user_profiles` - Extended user information
- `diabetes_profiles` - Diabetes-specific information
- `sessions` - User session management
- `onboarding_progress` - Onboarding completion tracking
- `onboarding_steps` - Onboarding step configuration

**Security Tables:**
- `password_reset_tokens` - Password reset functionality
- `email_verification_tokens` - Email verification
- `audit_logs` - Complete audit trail

**Additional Tables (Migration 002):**
- `user_preferences` - User settings and preferences
- `user_notification_settings` - Notification preferences
- `user_devices` - Device tracking and management
- `user_relationships` - User-to-user relationships
- `user_security_questions` - Security questions for recovery
- `user_backup_codes` - Two-factor authentication backup codes
- `user_login_history` - Login attempt tracking
- `user_consents` - GDPR compliance and consent tracking
- `user_activity_logs` - Comprehensive activity logging

**Views:**
- `v_users_complete` - Complete user information
- `v_onboarding_progress_summary` - Onboarding statistics
- `v_user_security_summary` - Security status overview
- `v_user_notification_preferences` - Notification settings
- `v_user_activity_summary` - Activity statistics

## How to Apply Migrations

### Using SQLite (Local Development)

1. Navigate to the database directory:
```bash
cd database
```

2. Apply the initial schema:
```bash
sqlite3 sugar_insights.db < migrations/001_initial_schema.sql
```

3. Apply additional tables:
```bash
sqlite3 sugar_insights.db < migrations/002_additional_auth_tables.sql
```

### Using PostgreSQL (Production)

1. Connect to your PostgreSQL database:
```bash
psql -h localhost -U your_username -d your_database
```

2. Apply the initial schema:
```sql
\i migrations/001_initial_schema_postgres.sql
```

3. Apply additional tables:
```sql
\i migrations/002_additional_auth_tables_postgres.sql
```

### Using psql command line:

```bash
psql -h localhost -U your_username -d your_database -f migrations/001_initial_schema_postgres.sql
psql -h localhost -U your_username -d your_database -f migrations/002_additional_auth_tables_postgres.sql
```

### Using Flutter/Dart

The migrations are automatically applied when the `DatabaseService` is initialized in the Flutter app:

```dart
// In lib/services/database_service.dart
Future<Database> _initDatabase() async {
  String path = join(await getDatabasesPath(), 'sugar_insights.db');
  return await openDatabase(
    path,
    version: 2, // Increment this when adding new migrations
    onCreate: _onCreate,
    onUpgrade: _onUpgrade, // Handle future migrations
  );
}
```

## Database Schema Overview

### User Authentication Flow

1. **Registration**: User creates account → `users` table
2. **Profile Setup**: User fills basic info → `user_profiles` table
3. **Diabetes Profile**: User provides diabetes info → `diabetes_profiles` table
4. **Onboarding**: User completes onboarding steps → `onboarding_progress` table
5. **Session Management**: User logs in → `sessions` table

### Role-Based Access Control

- **Admin**: Full system access
- **Doctor**: Patient management and care
- **Nurse**: Patient care and monitoring
- **Patient**: Own data management
- **Family Member**: Limited access to patient data

### Security Features

- **Password Hashing**: All passwords are hashed
- **Session Management**: Token-based authentication
- **Account Locking**: After failed login attempts
- **Audit Logging**: Complete activity tracking
- **Consent Management**: GDPR compliance

### Privacy Features

- **Data Minimization**: Only necessary data is collected
- **Consent Tracking**: User consent is tracked and versioned
- **Right to Deletion**: Users can request data deletion
- **Audit Trails**: All data changes are logged

## Sample Data

Both migration files include sample data for development:

- **Admin User**: `admin@sugarinsights.com` (password: admin123)
- **Patient User**: `patient@example.com` (password: patient123)
- **Sample Profiles**: Complete user and diabetes profiles
- **Sample Onboarding**: Completed onboarding progress
- **Sample Security**: Security questions and backup codes

## Database Views

### v_users_complete
Provides complete user information in a single query:
```sql
SELECT * FROM v_users_complete WHERE email = 'patient@example.com';
```

### v_onboarding_progress_summary
Shows onboarding completion statistics:
```sql
SELECT * FROM v_onboarding_progress_summary;
```

### v_user_security_summary
Displays security status overview:
```sql
SELECT * FROM v_user_security_summary WHERE user_id = 'patient_001';
```

## Indexes and Performance

The database includes optimized indexes for:
- Email lookups (`idx_users_email`)
- Role filtering (`idx_users_role`)
- Session management (`idx_sessions_token`)
- Onboarding progress (`idx_onboarding_progress_user_id`)
- Activity logging (`idx_user_activity_logs_created_at`)

## Triggers

Automatic triggers maintain data integrity:
- `updated_at` timestamp updates
- Cascade deletes for related data
- Audit log entries for data changes

## PostgreSQL vs SQLite Differences

### PostgreSQL Features:
- **JSONB**: Native JSON support with indexing
- **INET**: Native IP address storage
- **SERIAL**: Auto-incrementing primary keys
- **CHECK constraints**: Data validation
- **ON CONFLICT**: Upsert operations
- **TIMESTAMP with timezone**: Better time handling
- **INTERVAL**: Date calculations

### SQLite Features:
- **PRAGMA**: SQLite-specific commands
- **TEXT**: Simple text storage
- **INTEGER**: Auto-incrementing IDs
- **REAL**: Floating-point numbers

## Future Migrations

When adding new features, create new migration files:

1. Create `003_new_feature.sql` and `003_new_feature_postgres.sql`
2. Add new tables, indexes, and views
3. Update the database version in `DatabaseService`
4. Test the migration thoroughly

## Backup and Recovery

### SQLite Backup
```bash
sqlite3 sugar_insights.db ".backup backup_$(date +%Y%m%d_%H%M%S).db"
```

### PostgreSQL Backup
```bash
pg_dump -h localhost -U your_username -d your_database > backup_$(date +%Y%m%d_%H%M%S).sql
```

### PostgreSQL Restore
```bash
psql -h localhost -U your_username -d your_database < backup_file.sql
```

## Troubleshooting

### Common Issues

1. **Foreign Key Constraint Errors**: Ensure all referenced data exists
2. **Unique Constraint Violations**: Check for duplicate emails or unique IDs
3. **Index Conflicts**: Drop and recreate indexes if needed
4. **PostgreSQL-specific**: Check for proper user permissions and database access

### Debug Queries

Check user authentication:
```sql
SELECT u.email, u.is_verified, up.first_name, dp.diabetes_type 
FROM users u 
LEFT JOIN user_profiles up ON u.id = up.user_id 
LEFT JOIN diabetes_profiles dp ON u.id = dp.user_id;
```

Check onboarding progress:
```sql
SELECT * FROM v_onboarding_progress_summary WHERE user_id = 'patient_001';
```

Check active sessions:
```sql
SELECT u.email, s.created_at, s.expires_at 
FROM sessions s 
JOIN users u ON s.user_id = u.id 
WHERE s.is_active = TRUE AND s.expires_at > CURRENT_TIMESTAMP;
```

## Security Considerations

1. **Password Security**: Use strong hashing algorithms in production
2. **Token Security**: Implement proper token generation and validation
3. **Session Security**: Implement session timeout and cleanup
4. **Data Encryption**: Consider encrypting sensitive data
5. **Access Control**: Implement proper role-based permissions
6. **Audit Logging**: Monitor and review audit logs regularly

## Compliance

The database schema supports:
- **GDPR Compliance**: Consent tracking and data portability
- **HIPAA Compliance**: Audit trails and access controls
- **Data Privacy**: User control over personal data
- **Security Standards**: Industry-standard security practices

## Production Deployment

### PostgreSQL Setup:
1. Install PostgreSQL server
2. Create database and user
3. Apply migrations
4. Configure connection pooling
5. Set up automated backups
6. Monitor performance

### Environment Variables:
```bash
DATABASE_URL=postgresql://username:password@localhost:5432/sugar_insights
DATABASE_SSL_MODE=require
DATABASE_MAX_CONNECTIONS=20
``` 