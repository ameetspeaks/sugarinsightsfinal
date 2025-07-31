-- Migration: Add Medication Management Tables
-- Description: Creates comprehensive medication management system with tables for medications, history, reminders, and analytics functions

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. MEDICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.medications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    medicine_type TEXT NOT NULL,
    frequency TEXT NOT NULL,
    time_of_day TIME[] NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. MEDICATION HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.medication_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    medication_id UUID REFERENCES public.medications(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('taken', 'skipped', 'missed')),
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    taken_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Add unique constraint if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'medication_history_medication_id_scheduled_for_key' 
        AND table_name = 'medication_history'
    ) THEN
        ALTER TABLE public.medication_history 
        ADD CONSTRAINT medication_history_medication_id_scheduled_for_key 
        UNIQUE (medication_id, scheduled_for);
    END IF;
END $$;

-- 3. MEDICATION REMINDERS TABLE
CREATE TABLE IF NOT EXISTS public.medication_reminders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    medication_id UUID REFERENCES public.medications(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_id INTEGER NOT NULL,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 4. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_medications_user_id ON public.medications(user_id);
CREATE INDEX IF NOT EXISTS idx_medications_is_active ON public.medications(is_active);
CREATE INDEX IF NOT EXISTS idx_medications_start_date ON public.medications(start_date);
CREATE INDEX IF NOT EXISTS idx_medications_end_date ON public.medications(end_date);

CREATE INDEX IF NOT EXISTS idx_medication_history_medication_id ON public.medication_history(medication_id);
CREATE INDEX IF NOT EXISTS idx_medication_history_user_id ON public.medication_history(user_id);
CREATE INDEX IF NOT EXISTS idx_medication_history_status ON public.medication_history(status);
CREATE INDEX IF NOT EXISTS idx_medication_history_scheduled_for ON public.medication_history(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_medication_history_taken_at ON public.medication_history(taken_at);

CREATE INDEX IF NOT EXISTS idx_medication_reminders_medication_id ON public.medication_reminders(medication_id);
CREATE INDEX IF NOT EXISTS idx_medication_reminders_user_id ON public.medication_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_medication_reminders_scheduled_time ON public.medication_reminders(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_medication_reminders_is_active ON public.medication_reminders(is_active);

-- 5. ENABLE ROW LEVEL SECURITY
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_reminders ENABLE ROW LEVEL SECURITY;

-- 6. CREATE RLS POLICIES

-- Medications Policies
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medications' AND policyname = 'Users can view own medications') THEN
        CREATE POLICY "Users can view own medications" ON public.medications
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medications' AND policyname = 'Users can insert own medications') THEN
        CREATE POLICY "Users can insert own medications" ON public.medications
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medications' AND policyname = 'Users can update own medications') THEN
        CREATE POLICY "Users can update own medications" ON public.medications
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medications' AND policyname = 'Users can delete own medications') THEN
        CREATE POLICY "Users can delete own medications" ON public.medications
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Medication History Policies
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_history' AND policyname = 'Users can view own medication history') THEN
        CREATE POLICY "Users can view own medication history" ON public.medication_history
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_history' AND policyname = 'Users can insert own medication history') THEN
        CREATE POLICY "Users can insert own medication history" ON public.medication_history
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_history' AND policyname = 'Users can update own medication history') THEN
        CREATE POLICY "Users can update own medication history" ON public.medication_history
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_history' AND policyname = 'Users can delete own medication history') THEN
        CREATE POLICY "Users can delete own medication history" ON public.medication_history
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Medication Reminders Policies
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_reminders' AND policyname = 'Users can view own medication reminders') THEN
        CREATE POLICY "Users can view own medication reminders" ON public.medication_reminders
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_reminders' AND policyname = 'Users can insert own medication reminders') THEN
        CREATE POLICY "Users can insert own medication reminders" ON public.medication_reminders
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_reminders' AND policyname = 'Users can update own medication reminders') THEN
        CREATE POLICY "Users can update own medication reminders" ON public.medication_reminders
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_reminders' AND policyname = 'Users can delete own medication reminders') THEN
        CREATE POLICY "Users can delete own medication reminders" ON public.medication_reminders
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 7. CREATE DATABASE FUNCTIONS

-- Function to get user medications
CREATE OR REPLACE FUNCTION get_user_medications(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    dosage TEXT,
    medicine_type TEXT,
    frequency TEXT,
    time_of_day TIME[],
    start_date DATE,
    end_date DATE,
    notes TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.name,
        m.dosage,
        m.medicine_type,
        m.frequency,
        m.time_of_day,
        m.start_date,
        m.end_date,
        m.notes,
        m.is_active,
        m.created_at,
        m.updated_at
    FROM public.medications m
    WHERE m.user_id = p_user_id
    AND m.is_active = true
    ORDER BY m.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get today's medications
CREATE OR REPLACE FUNCTION get_today_medications(p_user_id UUID, p_date DATE)
RETURNS TABLE (
    medication_id UUID,
    medication_name TEXT,
    dosage TEXT,
    medicine_type TEXT,
    frequency TEXT,
    scheduled_time TIME,
    status TEXT,
    taken_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id as medication_id,
        m.name as medication_name,
        m.dosage,
        m.medicine_type,
        m.frequency,
        t.scheduled_time,
        COALESCE(mh.status, 'pending') as status,
        mh.taken_at
    FROM public.medications m
    CROSS JOIN LATERAL (
        SELECT unnest(m.time_of_day) as scheduled_time
    ) t
    LEFT JOIN public.medication_history mh ON 
        mh.medication_id = m.id 
        AND mh.scheduled_for::date = p_date
        AND mh.scheduled_for::time = t.scheduled_time
    WHERE m.user_id = p_user_id
    AND m.is_active = true
    AND m.start_date <= p_date
    AND (m.end_date IS NULL OR m.end_date >= p_date)
    ORDER BY t.scheduled_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get medication history
CREATE OR REPLACE FUNCTION get_medication_history(
    p_medication_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    id UUID,
    status TEXT,
    scheduled_for TIMESTAMP WITH TIME ZONE,
    taken_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mh.id,
        mh.status,
        mh.scheduled_for,
        mh.taken_at,
        mh.notes,
        mh.created_at
    FROM public.medication_history mh
    WHERE mh.medication_id = p_medication_id
    AND mh.scheduled_for::date BETWEEN p_start_date AND p_end_date
    ORDER BY mh.scheduled_for DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log medication taken
CREATE OR REPLACE FUNCTION log_medication_taken(
    p_medication_id UUID,
    p_user_id UUID,
    p_scheduled_for TIMESTAMP WITH TIME ZONE,
    p_taken_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_history_id UUID;
BEGIN
    -- First, try to update existing record
    UPDATE public.medication_history 
    SET 
        status = 'taken',
        taken_at = p_taken_at,
        notes = COALESCE(p_notes, notes)
    WHERE medication_id = p_medication_id 
    AND scheduled_for = p_scheduled_for
    RETURNING id INTO v_history_id;
    
    -- If no record was updated, insert a new one
    IF v_history_id IS NULL THEN
        INSERT INTO public.medication_history (
            medication_id,
            user_id,
            status,
            scheduled_for,
            taken_at,
            notes
        ) VALUES (
            p_medication_id,
            p_user_id,
            'taken',
            p_scheduled_for,
            p_taken_at,
            p_notes
        ) RETURNING id INTO v_history_id;
    END IF;
    
    RETURN v_history_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log medication skipped
CREATE OR REPLACE FUNCTION log_medication_skipped(
    p_medication_id UUID,
    p_user_id UUID,
    p_scheduled_for TIMESTAMP WITH TIME ZONE,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_history_id UUID;
BEGIN
    -- First, try to update existing record
    UPDATE public.medication_history 
    SET 
        status = 'skipped',
        notes = COALESCE(p_notes, notes)
    WHERE medication_id = p_medication_id 
    AND scheduled_for = p_scheduled_for
    RETURNING id INTO v_history_id;
    
    -- If no record was updated, insert a new one
    IF v_history_id IS NULL THEN
        INSERT INTO public.medication_history (
            medication_id,
            user_id,
            status,
            scheduled_for,
            notes
        ) VALUES (
            p_medication_id,
            p_user_id,
            'skipped',
            p_scheduled_for,
            p_notes
        ) RETURNING id INTO v_history_id;
    END IF;
    
    RETURN v_history_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get medication compliance rate
CREATE OR REPLACE FUNCTION get_medication_compliance_rate(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    medication_id UUID,
    medication_name TEXT,
    total_scheduled INTEGER,
    total_taken INTEGER,
    total_skipped INTEGER,
    total_missed INTEGER,
    compliance_rate DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id as medication_id,
        m.name as medication_name,
        COUNT(*) as total_scheduled,
        COUNT(CASE WHEN mh.status = 'taken' THEN 1 END) as total_taken,
        COUNT(CASE WHEN mh.status = 'skipped' THEN 1 END) as total_skipped,
        COUNT(CASE WHEN mh.status = 'missed' THEN 1 END) as total_missed,
        ROUND(
            (COUNT(CASE WHEN mh.status = 'taken' THEN 1 END)::DECIMAL / COUNT(*)) * 100, 
            2
        ) as compliance_rate
    FROM public.medications m
    CROSS JOIN LATERAL (
        SELECT generate_series(
            GREATEST(m.start_date, p_start_date)::date,
            LEAST(COALESCE(m.end_date, p_end_date), p_end_date)::date,
            '1 day'::interval
        )::date as scheduled_date
    ) dates
    CROSS JOIN LATERAL (
        SELECT unnest(m.time_of_day) as scheduled_time
    ) times
    LEFT JOIN public.medication_history mh ON 
        mh.medication_id = m.id 
        AND mh.scheduled_for::date = dates.scheduled_date
        AND mh.scheduled_for::time = times.scheduled_time
    WHERE m.user_id = p_user_id
    AND m.is_active = true
    GROUP BY m.id, m.name
    ORDER BY compliance_rate DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get missed medications count
CREATE OR REPLACE FUNCTION get_missed_medications_count(
    p_user_id UUID,
    p_date DATE
)
RETURNS INTEGER AS $$
DECLARE
    v_missed_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_missed_count
    FROM public.medications m
    CROSS JOIN LATERAL (
        SELECT unnest(m.time_of_day) as scheduled_time
    ) t
    WHERE m.user_id = p_user_id
    AND m.is_active = true
    AND m.start_date <= p_date
    AND (m.end_date IS NULL OR m.end_date >= p_date)
    AND NOT EXISTS (
        SELECT 1 FROM public.medication_history mh
        WHERE mh.medication_id = m.id
        AND mh.scheduled_for::date = p_date
        AND mh.scheduled_for::time = t.scheduled_time
        AND mh.status IN ('taken', 'skipped')
    );
    
    RETURN v_missed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. CREATE TRIGGERS

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_medications_updated_at'
    ) THEN
        CREATE TRIGGER update_medications_updated_at
            BEFORE UPDATE ON public.medications
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- 9. INSERT SAMPLE DATA (Optional - for testing)

-- Insert sample medication types
DO $$
BEGIN
    -- This will be handled by the Flutter app, but we can add some reference data if needed
    NULL;
END $$;

-- 10. GRANT PERMISSIONS
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.medications TO authenticated;
GRANT ALL ON public.medication_history TO authenticated;
GRANT ALL ON public.medication_reminders TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated; 