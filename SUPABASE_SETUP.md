# Supabase Setup Documentation

## Authentication Setup

### Email Authentication with OTP (Using Resend)
```sql
-- Enable Email Authentication in Supabase Dashboard
-- Configure Resend API in Authentication > Providers > Email
CREATE POLICY "Enable email confirmation" ON auth.users
FOR SELECT
USING (email_confirmed_at IS NOT NULL);
```

### User Roles
```sql
-- Create roles enum
CREATE TYPE public.user_role AS ENUM ('admin', 'patient');

-- Add role column to auth.users
ALTER TABLE auth.users ADD COLUMN role user_role DEFAULT 'patient';

-- Policy to allow admins to manage all users
CREATE POLICY "Admins can manage all users" ON auth.users
FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

## Database Schema

### 1. Profiles Table
```sql
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    updated_at TIMESTAMP WITH TIME ZONE,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    phone_number TEXT,
    date_of_birth DATE,
    gender TEXT,
    height DECIMAL,
    weight DECIMAL,
    diabetes_type TEXT,
    diagnosis_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- RLS Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR SELECT USING (auth.jwt() ->> 'role' = 'admin');

-- Admins can update all profiles
CREATE POLICY "Admins can update all profiles" ON public.profiles
    FOR UPDATE USING (auth.jwt() ->> 'role' = 'admin');
```

### 2. Medications Table
```sql
CREATE TABLE public.medications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    medicine_type TEXT NOT NULL,
    frequency TEXT NOT NULL,
    time_of_day TIME[] NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- RLS Policies
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;

-- Users can CRUD their own medications
CREATE POLICY "Users can manage own medications" ON public.medications
    FOR ALL USING (auth.uid() = user_id);

-- Admins can manage all medications
CREATE POLICY "Admins can manage all medications" ON public.medications
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

### 3. Medication History Table
```sql
CREATE TABLE public.medication_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    medication_id UUID REFERENCES public.medications(id),
    user_id UUID REFERENCES auth.users(id),
    status TEXT NOT NULL, -- 'taken', 'skipped', 'missed'
    taken_at TIMESTAMP WITH TIME ZONE,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- RLS Policies
ALTER TABLE public.medication_history ENABLE ROW LEVEL SECURITY;

-- Users can view and create their history
CREATE POLICY "Users can view own medication history" ON public.medication_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create medication history" ON public.medication_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admins can manage all history
CREATE POLICY "Admins can manage all medication history" ON public.medication_history
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

### 4. Glucose Readings Table
```sql
CREATE TABLE public.glucose_readings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    reading_value DECIMAL NOT NULL,
    reading_type TEXT NOT NULL, -- 'fasting', 'post_meal'
    reading_date DATE NOT NULL,
    reading_time TIME NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- RLS Policies
ALTER TABLE public.glucose_readings ENABLE ROW LEVEL SECURITY;

-- Users can manage their readings
CREATE POLICY "Users can manage own glucose readings" ON public.glucose_readings
    FOR ALL USING (auth.uid() = user_id);

-- Admins can manage all readings
CREATE POLICY "Admins can manage all glucose readings" ON public.glucose_readings
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

### 5. Blood Pressure Readings Table
```sql
CREATE TABLE public.blood_pressure_readings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    systolic INTEGER NOT NULL,
    diastolic INTEGER NOT NULL,
    pulse_rate INTEGER,
    reading_date DATE NOT NULL,
    reading_time TIME NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- RLS Policies
ALTER TABLE public.blood_pressure_readings ENABLE ROW LEVEL SECURITY;

-- Users can manage their readings
CREATE POLICY "Users can manage own bp readings" ON public.blood_pressure_readings
    FOR ALL USING (auth.uid() = user_id);

-- Admins can manage all readings
CREATE POLICY "Admins can manage all bp readings" ON public.blood_pressure_readings
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

### 6. Other Vital Readings Table
```sql
CREATE TABLE public.other_vital_readings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    vital_type TEXT NOT NULL, -- 'hba1c', 'uacr', 'hb', etc.
    reading_value DECIMAL NOT NULL,
    unit TEXT NOT NULL,
    reading_date DATE NOT NULL,
    reading_time TIME NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- RLS Policies
ALTER TABLE public.other_vital_readings ENABLE ROW LEVEL SECURITY;

-- Users can manage their readings
CREATE POLICY "Users can manage own vital readings" ON public.other_vital_readings
    FOR ALL USING (auth.uid() = user_id);

-- Admins can manage all readings
CREATE POLICY "Admins can manage all vital readings" ON public.other_vital_readings
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

### 7. Steps Data Table
```sql
CREATE TABLE public.steps_data (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    step_count INTEGER NOT NULL,
    distance DECIMAL,
    calories_burned INTEGER,
    active_minutes INTEGER,
    date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- RLS Policies
ALTER TABLE public.steps_data ENABLE ROW LEVEL SECURITY;

-- Users can manage their steps data
CREATE POLICY "Users can manage own steps data" ON public.steps_data
    FOR ALL USING (auth.uid() = user_id);

-- Admins can manage all steps data
CREATE POLICY "Admins can manage all steps data" ON public.steps_data
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

### 8. Food Entries Table
```sql
CREATE TABLE public.food_entries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    food_name TEXT NOT NULL,
    quantity DECIMAL NOT NULL,
    unit TEXT NOT NULL,
    calories INTEGER,
    carbs DECIMAL,
    protein DECIMAL,
    fat DECIMAL,
    meal_type TEXT NOT NULL, -- 'breakfast', 'lunch', 'dinner', 'snack'
    consumed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- RLS Policies
ALTER TABLE public.food_entries ENABLE ROW LEVEL SECURITY;

-- Users can manage their food entries
CREATE POLICY "Users can manage own food entries" ON public.food_entries
    FOR ALL USING (auth.uid() = user_id);

-- Admins can manage all food entries
CREATE POLICY "Admins can manage all food entries" ON public.food_entries
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

## Medication Reminders Implementation

### 1. Reminder Settings Table
```sql
CREATE TABLE public.reminder_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    medication_id UUID REFERENCES public.medications(id),
    reminder_type TEXT NOT NULL, -- 'push', 'email', 'both'
    reminder_time INTERVAL NOT NULL, -- how long before medication time
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- RLS Policies
ALTER TABLE public.reminder_settings ENABLE ROW LEVEL SECURITY;

-- Users can manage their reminder settings
CREATE POLICY "Users can manage own reminder settings" ON public.reminder_settings
    FOR ALL USING (auth.uid() = user_id);

-- Admins can manage all reminder settings
CREATE POLICY "Admins can manage all reminder settings" ON public.reminder_settings
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

### 2. Reminder Logs Table
```sql
CREATE TABLE public.reminder_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    medication_id UUID REFERENCES public.medications(id),
    reminder_type TEXT NOT NULL,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    status TEXT NOT NULL, -- 'pending', 'sent', 'failed'
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- RLS Policies
ALTER TABLE public.reminder_logs ENABLE ROW LEVEL SECURITY;

-- Users can view their reminder logs
CREATE POLICY "Users can view own reminder logs" ON public.reminder_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Admins can manage all reminder logs
CREATE POLICY "Admins can manage all reminder logs" ON public.reminder_logs
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

## Edge Functions for Reminders

1. Create an Edge Function in Supabase that runs on a schedule to:
   - Check for upcoming medications
   - Create reminder logs
   - Send notifications via selected channels

2. Create another Edge Function to handle medication status updates:
   - Mark medications as taken/skipped
   - Update reminder status
   - Create medication history entries
   - Handle missed medications

## Authentication Flow

1. User signs up with email
2. Resend service sends OTP
3. User verifies OTP
4. JWT token is generated with role claim
5. Token is used for all subsequent requests

## Security Considerations

1. All tables have RLS policies
2. Admin role has full access
3. Users can only access their own data
4. Sensitive operations require re-authentication
5. All dates/times are stored in UTC
6. Input validation on both client and server

## Indexes for Performance

```sql
-- Add indexes for frequently queried columns
CREATE INDEX idx_medications_user_id ON public.medications(user_id);
CREATE INDEX idx_medication_history_user_id ON public.medication_history(user_id);
CREATE INDEX idx_glucose_readings_user_id_date ON public.glucose_readings(user_id, reading_date);
CREATE INDEX idx_bp_readings_user_id_date ON public.blood_pressure_readings(user_id, reading_date);
CREATE INDEX idx_other_vital_readings_user_id_date ON public.other_vital_readings(user_id, reading_date);
CREATE INDEX idx_steps_data_user_id_date ON public.steps_data(user_id, date);
CREATE INDEX idx_food_entries_user_id_consumed_at ON public.food_entries(user_id, consumed_at);
CREATE INDEX idx_reminder_logs_scheduled_for ON public.reminder_logs(scheduled_for);
``` 