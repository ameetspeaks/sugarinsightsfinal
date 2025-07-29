# Supabase Email Templates Setup Guide

## Overview
This guide explains how to configure Supabase email templates for the Sugar Insights app authentication system.

## Email Templates Configuration

### 1. Access Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **Authentication** → **Email Templates**

### 2. Configure Email Templates

#### **Confirm Signup Template**
- **Subject**: `Confirm your signup - Sugar Insights`
- **HTML Content**:
```html
<h2>Welcome to Sugar Insights! 🍯</h2>
<p>Thank you for signing up. To complete your registration, please click the button below:</p>

<div style="text-align: center; margin: 30px 0;">
  <a href="{{ .ConfirmationURL }}" 
     style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            padding: 15px 30px; 
            text-decoration: none; 
            border-radius: 8px; 
            font-weight: bold;">
    Confirm Your Email
  </a>
</div>

<p>Or copy and paste this link into your browser:</p>
<p style="word-break: break-all; color: #666;">{{ .ConfirmationURL }}</p>

<p>This link will expire in 24 hours.</p>

<p>If you didn't create this account, you can safely ignore this email.</p>

<p>Best regards,<br>The Sugar Insights Team</p>

<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
<p style="color: #666; font-size: 12px;">© 2024 Sugar Insights. All rights reserved.</p>
```

#### **Magic Link Template**
- **Subject**: `Your login link - Sugar Insights`
- **HTML Content**:
```html
<h2>Login to Sugar Insights 🍯</h2>
<p>Click the button below to sign in to your account:</p>

<div style="text-align: center; margin: 30px 0;">
  <a href="{{ .TokenHash }}" 
     style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            padding: 15px 30px; 
            text-decoration: none; 
            border-radius: 8px; 
            font-weight: bold;">
    Sign In
  </a>
</div>

<p>Or copy and paste this link into your browser:</p>
<p style="word-break: break-all; color: #666;">{{ .TokenHash }}</p>

<p>This link will expire in 1 hour.</p>

<p>If you didn't request this login link, you can safely ignore this email.</p>

<p>Best regards,<br>The Sugar Insights Team</p>

<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
<p style="color: #666; font-size: 12px;">© 2024 Sugar Insights. All rights reserved.</p>
```

#### **Change Email Address Template**
- **Subject**: `Confirm your new email - Sugar Insights`
- **HTML Content**:
```html
<h2>Confirm Your New Email 🍯</h2>
<p>You requested to change your email address. Click the button below to confirm:</p>

<div style="text-align: center; margin: 30px 0;">
  <a href="{{ .ConfirmationURL }}" 
     style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            padding: 15px 30px; 
            text-decoration: none; 
            border-radius: 8px; 
            font-weight: bold;">
    Confirm New Email
  </a>
</div>

<p>Or copy and paste this link into your browser:</p>
<p style="word-break: break-all; color: #666;">{{ .ConfirmationURL }}</p>

<p>This link will expire in 24 hours.</p>

<p>If you didn't request this change, you can safely ignore this email.</p>

<p>Best regards,<br>The Sugar Insights Team</p>

<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
<p style="color: #666; font-size: 12px;">© 2024 Sugar Insights. All rights reserved.</p>
```

#### **Reset Password Template**
- **Subject**: `Reset your password - Sugar Insights`
- **HTML Content**:
```html
<h2>Reset Your Password 🍯</h2>
<p>You requested to reset your password. Click the button below to create a new password:</p>

<div style="text-align: center; margin: 30px 0;">
  <a href="{{ .TokenHash }}" 
     style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            padding: 15px 30px; 
            text-decoration: none; 
            border-radius: 8px; 
            font-weight: bold;">
    Reset Password
  </a>
</div>

<p>Or copy and paste this link into your browser:</p>
<p style="word-break: break-all; color: #666;">{{ .TokenHash }}</p>

<p>This link will expire in 1 hour.</p>

<p>If you didn't request a password reset, you can safely ignore this email.</p>

<p>Best regards,<br>The Sugar Insights Team</p>

<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
<p style="color: #666; font-size: 12px;">© 2024 Sugar Insights. All rights reserved.</p>
```

### 3. Email Provider Configuration

#### **Using Supabase's Built-in Email Provider**
1. Go to **Authentication** → **Providers**
2. Under **Email**, ensure **Enable email confirmations** is checked
3. Set **Secure email change** to enabled
4. Configure **SMTP Settings** if using custom SMTP

#### **Using Custom SMTP Provider**
1. Go to **Authentication** → **Providers**
2. Under **Email**, click **Configure SMTP**
3. Enter your SMTP settings:
   - **Host**: Your SMTP server (e.g., smtp.gmail.com)
   - **Port**: SMTP port (usually 587 or 465)
   - **Username**: Your email address
   - **Password**: Your app password
   - **Sender name**: Sugar Insights
   - **Sender email**: noreply@sugarinsights.com

### 4. Site URL Configuration
1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL** to your app's domain
3. Add redirect URLs for your app:
   - `https://yourdomain.com/auth/callback`
   - `com.sugarinsights.app://auth/callback` (for mobile)

### 5. Testing Email Templates
1. Go to **Authentication** → **Users**
2. Create a test user or use an existing one
3. Click **Send confirmation email** to test the template
4. Check the email to verify the template renders correctly

## App Configuration

### Update Supabase Config
In `lib/core/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Email configuration
  static const String fromEmail = 'noreply@sugarinsights.com';
  static const String fromName = 'Sugar Insights';
}
```

### Authentication Flow
1. **Sign Up**: User creates account → Supabase sends confirmation email
2. **Email Verification**: User clicks link in email → Account confirmed
3. **Sign In**: User signs in → Redirected to app
4. **Password Reset**: User requests reset → Supabase sends reset email

## Troubleshooting

### Common Issues
1. **Emails not sending**: Check SMTP configuration
2. **Templates not rendering**: Verify HTML syntax
3. **Links not working**: Check site URL configuration
4. **Mobile deep linking**: Ensure URL scheme is configured

### Testing Checklist
- [ ] Email templates are configured
- [ ] SMTP settings are correct
- [ ] Site URL is set
- [ ] Redirect URLs are added
- [ ] Test signup flow
- [ ] Test email verification
- [ ] Test password reset
- [ ] Test mobile deep linking

## Security Considerations
1. Use HTTPS for all URLs
2. Set appropriate token expiration times
3. Monitor email delivery rates
4. Implement rate limiting
5. Use secure SMTP connections
6. Regularly update email templates

## Next Steps
1. Configure your Supabase project with the email templates
2. Update the app configuration with your Supabase credentials
3. Test the complete authentication flow
4. Monitor email delivery and user engagement 