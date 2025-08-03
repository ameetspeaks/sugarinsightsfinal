const bcrypt = require('bcryptjs');
require('dotenv').config();
const { supabase } = require('../config/database');

async function createAdminTableAndUser() {
    try {
        console.log('🔐 Creating admin_users table and adding admin...');
        
        // Create admin_users table
        const createTableSQL = `
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
        `;

        console.log('📋 Creating admin_users table...');
        const { error: tableError } = await supabase.rpc('exec_sql', {
            sql: createTableSQL
        });

        if (tableError) {
            console.log('⚠️  Table might already exist, continuing...');
        } else {
            console.log('✅ Admin_users table created successfully!');
        }

        // User details to add as admin
        const userDetails = {
            uuid: '94bf1402-cebd-4e0c-b4d6-1c1a78f1f9ce',
            user_id: '627cf777-5ef6-425d-b4c1-066b1c44c558',
            email: 'ameetspeaks@gmail.com'
        };

        // Get user profile
        console.log('📋 Fetching user profile...');
        const { data: userProfile, error: profileError } = await supabase
            .from('user_profiles')
            .select('name, email')
            .eq('user_id', userDetails.user_id)
            .single();

        if (profileError) {
            console.error('❌ Error fetching user profile:', profileError);
            return;
        }

        if (!userProfile) {
            console.error('❌ User profile not found');
            return;
        }

        console.log('✅ User profile found:', userProfile);

        // Generate password hash
        const password = 'admin_password_123';
        const passwordHash = await bcrypt.hash(password, 10);

        // Check if admin already exists
        const { data: existingAdmin, error: checkError } = await supabase
            .from('admin_users')
            .select('id, email')
            .eq('email', userDetails.email)
            .single();

        if (existingAdmin) {
            console.log('⚠️  Admin already exists, updating...');
            
            const { error: updateError } = await supabase
                .from('admin_users')
                .update({
                    name: userProfile.name || 'Admin User',
                    password_hash: passwordHash,
                    role: 'super_admin',
                    permissions: ['users:read', 'users:write', 'users:delete', 'medications:read', 'medications:write', 'medications:delete', 'blog:read', 'blog:write', 'blog:delete', 'analytics:read', 'export:read'],
                    status: 'active',
                    updated_at: new Date().toISOString()
                })
                .eq('email', userDetails.email);

            if (updateError) {
                console.error('❌ Error updating admin:', updateError);
                return;
            }

            console.log('✅ Admin updated successfully!');
        } else {
            console.log('➕ Creating new admin...');
            
            const { error: insertError } = await supabase
                .from('admin_users')
                .insert({
                    email: userDetails.email,
                    password_hash: passwordHash,
                    name: userProfile.name || 'Admin User',
                    role: 'super_admin',
                    permissions: ['users:read', 'users:write', 'users:delete', 'medications:read', 'medications:write', 'medications:delete', 'blog:read', 'blog:write', 'blog:delete', 'analytics:read', 'export:read'],
                    status: 'active'
                });

            if (insertError) {
                console.error('❌ Error creating admin:', insertError);
                console.log('🔍 Error details:', JSON.stringify(insertError, null, 2));
                return;
            }

            console.log('✅ Admin created successfully!');
        }

        console.log('\n🎉 Admin setup complete!');
        console.log('📧 Email:', userDetails.email);
        console.log('🔑 Password:', password);
        console.log('👤 Name:', userProfile.name || 'Admin User');
        console.log('🔐 Role: super_admin');
        console.log('\n🌐 You can now login at: http://localhost:3001/admin');

    } catch (error) {
        console.error('❌ Error:', error);
    }
}

createAdminTableAndUser(); 