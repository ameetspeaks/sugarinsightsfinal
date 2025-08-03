#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

console.log('🚀 Sugar Insights Admin Panel Setup');
console.log('=====================================\n');

// Check if .env file exists
const envPath = path.join(__dirname, '.env');
const envExamplePath = path.join(__dirname, 'env.example');

if (!fs.existsSync(envPath)) {
  console.log('📝 Creating .env file from template...');
  
  if (fs.existsSync(envExamplePath)) {
    fs.copyFileSync(envExamplePath, envPath);
    console.log('✅ .env file created successfully!');
    console.log('⚠️  Please update the .env file with your configuration values.');
  } else {
    console.log('❌ env.example file not found!');
    process.exit(1);
  }
} else {
  console.log('✅ .env file already exists');
}

// Create uploads directory
const uploadsPath = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsPath)) {
  console.log('📁 Creating uploads directory...');
  fs.mkdirSync(uploadsPath, { recursive: true });
  console.log('✅ uploads directory created successfully!');
} else {
  console.log('✅ uploads directory already exists');
}

// Generate JWT secret if not provided
const envContent = fs.readFileSync(envPath, 'utf8');
if (envContent.includes('your_jwt_secret_key_here')) {
  console.log('🔐 Generating JWT secret...');
  
  const crypto = require('crypto');
  const jwtSecret = crypto.randomBytes(64).toString('hex');
  
  const updatedContent = envContent.replace(
    'JWT_SECRET=your_jwt_secret_key_here',
    `JWT_SECRET=${jwtSecret}`
  );
  
  fs.writeFileSync(envPath, updatedContent);
  console.log('✅ JWT secret generated and updated in .env file');
}

// Create admin user hash
console.log('🔑 Generating admin password hash...');
const adminPassword = 'admin_password_123';
const saltRounds = 10;
const passwordHash = bcrypt.hashSync(adminPassword, saltRounds);

console.log('📋 Setup Summary:');
console.log('==================');
console.log('✅ Environment file: .env');
console.log('✅ Uploads directory: uploads/');
console.log('✅ JWT secret: Generated');
console.log('✅ Admin password hash: Generated');
console.log('');
console.log('🔧 Next Steps:');
console.log('1. Update .env file with your Supabase credentials');
console.log('2. Run database migration: npm run migrate');
console.log('3. Start the server: npm run dev');
console.log('');
console.log('🔐 Default Admin Credentials:');
console.log('Email: admin@sugarinsights.com');
console.log('Password: admin_password_123');
console.log('');
console.log('⚠️  IMPORTANT: Change the default password in production!');
console.log('');
console.log('🎉 Setup completed successfully!'); 