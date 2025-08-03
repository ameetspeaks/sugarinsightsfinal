-- Migration: Create admin users table
-- This migration creates the admin_users table for admin panel authentication

-- Create admin_users table
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT,
    role TEXT NOT NULL DEFAULT 'admin',
    permissions TEXT[] DEFAULT ARRAY['users:read', 'users:write', 'medications:read', 'medications:write', 'blog:read', 'blog:write', 'analytics:read', 'export:read'],
    status TEXT NOT NULL DEFAULT 'active',
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);

-- Create index on status for filtering
CREATE INDEX IF NOT EXISTS idx_admin_users_status ON admin_users(status);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_admin_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER IF NOT EXISTS trigger_update_admin_users_updated_at
    BEFORE UPDATE ON admin_users
    FOR EACH ROW
    EXECUTE FUNCTION update_admin_users_updated_at();

-- Insert default admin user (password: admin_password_123)
-- You should change this password in production
INSERT INTO admin_users (email, password_hash, name, role, permissions) 
VALUES (
    'admin@sugarinsights.com',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- bcrypt hash of 'admin_password_123'
    'System Administrator',
    'super_admin',
    ARRAY['users:read', 'users:write', 'users:delete', 'medications:read', 'medications:write', 'medications:delete', 'blog:read', 'blog:write', 'blog:delete', 'analytics:read', 'export:read']
) ON CONFLICT (email) DO NOTHING;

-- Add RLS policies for admin_users table
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Policy: Only authenticated users can view admin_users (for profile management)
CREATE POLICY IF NOT EXISTS "Admin users can view own profile" ON admin_users
    FOR SELECT USING (auth.uid()::text = id::text);

-- Policy: Only super admins can manage admin users
CREATE POLICY IF NOT EXISTS "Super admins can manage admin users" ON admin_users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users 
            WHERE id::text = auth.uid()::text 
            AND role = 'super_admin'
        )
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_users TO authenticated;
GRANT USAGE ON SEQUENCE admin_users_id_seq TO authenticated;

-- Success message
SELECT 'Admin users table created successfully!' as status; 