const bcrypt = require('bcryptjs');
require('dotenv').config();

// Create Supabase client with service role key
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function addAdminSimple() {
    try {
        console.log('🔐 Adding admin user...');
        
        // User details
        const email = 'ameetspeaks@gmail.com';
        const password = 'admin_password_123';
        const passwordHash = await bcrypt.hash(password, 10);

        // Get user profile
        console.log('📋 Fetching user profile...');
        const { data: userProfile, error: profileError } = await supabase
            .from('user_profiles')
            .select('name, email')
            .eq('user_id', '627cf777-5ef6-425d-b4c1-066b1c44c558')
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

        // Try to insert admin user
        console.log('➕ Creating admin user...');
        const { data: insertData, error: insertError } = await supabase
            .from('admin_users')
            .insert({
                email: email,
                password_hash: passwordHash,
                name: userProfile.name || 'Admin User',
                role: 'super_admin',
                permissions: ['users:read', 'users:write', 'users:delete', 'medications:read', 'medications:write', 'medications:delete', 'blog:read', 'blog:write', 'blog:delete', 'analytics:read', 'export:read'],
                status: 'active'
            })
            .select();

        if (insertError) {
            console.error('❌ Error creating admin:', insertError);
            
            // Try to update if user already exists
            console.log('🔄 Trying to update existing admin...');
            const { error: updateError } = await supabase
                .from('admin_users')
                .update({
                    password_hash: passwordHash,
                    name: userProfile.name || 'Admin User',
                    role: 'super_admin',
                    permissions: ['users:read', 'users:write', 'users:delete', 'medications:read', 'medications:write', 'medications:delete', 'blog:read', 'blog:write', 'blog:delete', 'analytics:read', 'export:read'],
                    status: 'active',
                    updated_at: new Date().toISOString()
                })
                .eq('email', email);

            if (updateError) {
                console.error('❌ Error updating admin:', updateError);
                return;
            }

            console.log('✅ Admin updated successfully!');
        } else {
            console.log('✅ Admin created successfully!');
            console.log('📊 Inserted data:', insertData);
        }

        console.log('\n🎉 Admin setup complete!');
        console.log('📧 Email:', email);
        console.log('🔑 Password:', password);
        console.log('👤 Name:', userProfile.name || 'Admin User');
        console.log('🔐 Role: super_admin');
        console.log('\n🌐 You can now login at: http://localhost:3001/admin');

    } catch (error) {
        console.error('❌ Error:', error);
    }
}

addAdminSimple(); 