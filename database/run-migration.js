const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Read the migration file
const migrationPath = path.join(__dirname, 'migrations', '001_create_admin_users.sql');
const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

// Import Supabase client
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function runMigration() {
    try {
        console.log('🚀 Running admin_users migration...');
        
        // Split the SQL into individual statements
        const statements = migrationSQL
            .split(';')
            .map(stmt => stmt.trim())
            .filter(stmt => stmt.length > 0);

        for (let i = 0; i < statements.length; i++) {
            const statement = statements[i];
            if (statement.trim()) {
                console.log(`📝 Executing statement ${i + 1}/${statements.length}...`);
                
                const { error } = await supabase.rpc('exec_sql', {
                    sql: statement
                });

                if (error) {
                    console.error(`❌ Error in statement ${i + 1}:`, error);
                    // Continue with other statements
                } else {
                    console.log(`✅ Statement ${i + 1} executed successfully`);
                }
            }
        }

        console.log('🎉 Migration completed!');
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
    }
}

runMigration(); 