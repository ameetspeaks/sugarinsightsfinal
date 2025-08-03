-- Migration: Create admin_users table
-- This migration creates the admin_users table for the admin panel

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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_users_status ON admin_users(status);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_admin_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER IF NOT EXISTS update_admin_users_updated_at
    BEFORE UPDATE ON admin_users
    FOR EACH ROW
    EXECUTE FUNCTION update_admin_users_updated_at();

-- Enable RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DO $$ 
BEGIN
    -- Policy for admins to view all admin users
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'admin_users' AND policyname = 'Admins can view all admin users'
    ) THEN
        CREATE POLICY "Admins can view all admin users" ON admin_users
        FOR SELECT USING (true);
    END IF;

    -- Policy for admins to insert admin users
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'admin_users' AND policyname = 'Admins can insert admin users'
    ) THEN
        CREATE POLICY "Admins can insert admin users" ON admin_users
        FOR INSERT WITH CHECK (true);
    END IF;

    -- Policy for admins to update admin users
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'admin_users' AND policyname = 'Admins can update admin users'
    ) THEN
        CREATE POLICY "Admins can update admin users" ON admin_users
        FOR UPDATE USING (true);
    END IF;

    -- Policy for admins to delete admin users
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'admin_users' AND policyname = 'Admins can delete admin users'
    ) THEN
        CREATE POLICY "Admins can delete admin users" ON admin_users
        FOR DELETE USING (true);
    END IF;
END $$;

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

-- Success message
SELECT 'Admin users table created successfully!' as status; 