class SupabaseConfig {
  // Replace these with your actual Supabase credentials
  static const String url = 'https://dddydfgedegbrphnhtcc.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkZHlkZmdlZGVnYnJwaG5odGNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM0MzAzMjMsImV4cCI6MjA2OTAwNjMyM30.HOWe0n8Xuqz3_MjIal9xUyTcZXnLfrdRa_kLWrNM81I';
  
  // Email configuration
  static const String fromEmail = 'hi@sugarinsights.com';
  static const String fromName = 'Sugar Insights';
  
  // Email templates (configured in Supabase dashboard)
  static const String emailVerificationSubject = 'Verify your Sugar Insights account';
  static const String passwordResetSubject = 'Reset your Sugar Insights password';
  
  // OTP configuration
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;
  
  // Session configuration
  static const int sessionExpiryDays = 30;
  
  // Rate limiting
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
} 