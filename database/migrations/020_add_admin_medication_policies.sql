-- Migration: Add Admin Medication Policies
-- Description: Adds RLS policies for admin users to access all medications

-- Add admin policies for medications table
DO $$ 
BEGIN
    -- Admin can view all medications
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medications' AND policyname = 'Admins can view all medications') THEN
        CREATE POLICY "Admins can view all medications" ON public.medications
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:read' = ANY(admin_users.permissions)
                )
            );
    END IF;
    
    -- Admin can insert medications
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medications' AND policyname = 'Admins can insert medications') THEN
        CREATE POLICY "Admins can insert medications" ON public.medications
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:write' = ANY(admin_users.permissions)
                )
            );
    END IF;
    
    -- Admin can update medications
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medications' AND policyname = 'Admins can update medications') THEN
        CREATE POLICY "Admins can update medications" ON public.medications
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:write' = ANY(admin_users.permissions)
                )
            );
    END IF;
    
    -- Admin can delete medications
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medications' AND policyname = 'Admins can delete medications') THEN
        CREATE POLICY "Admins can delete medications" ON public.medications
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:delete' = ANY(admin_users.permissions)
                )
            );
    END IF;
END $$;

-- Add admin policies for medication_history table
DO $$ 
BEGIN
    -- Admin can view all medication history
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_history' AND policyname = 'Admins can view all medication history') THEN
        CREATE POLICY "Admins can view all medication history" ON public.medication_history
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:read' = ANY(admin_users.permissions)
                )
            );
    END IF;
    
    -- Admin can insert medication history
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_history' AND policyname = 'Admins can insert medication history') THEN
        CREATE POLICY "Admins can insert medication history" ON public.medication_history
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:write' = ANY(admin_users.permissions)
                )
            );
    END IF;
    
    -- Admin can update medication history
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_history' AND policyname = 'Admins can update medication history') THEN
        CREATE POLICY "Admins can update medication history" ON public.medication_history
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:write' = ANY(admin_users.permissions)
                )
            );
    END IF;
    
    -- Admin can delete medication history
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_history' AND policyname = 'Admins can delete medication history') THEN
        CREATE POLICY "Admins can delete medication history" ON public.medication_history
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:delete' = ANY(admin_users.permissions)
                )
            );
    END IF;
END $$;

-- Add admin policies for medication_reminders table
DO $$ 
BEGIN
    -- Admin can view all medication reminders
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_reminders' AND policyname = 'Admins can view all medication reminders') THEN
        CREATE POLICY "Admins can view all medication reminders" ON public.medication_reminders
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:read' = ANY(admin_users.permissions)
                )
            );
    END IF;
    
    -- Admin can insert medication reminders
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_reminders' AND policyname = 'Admins can insert medication reminders') THEN
        CREATE POLICY "Admins can insert medication reminders" ON public.medication_reminders
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:write' = ANY(admin_users.permissions)
                )
            );
    END IF;
    
    -- Admin can update medication reminders
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_reminders' AND policyname = 'Admins can update medication reminders') THEN
        CREATE POLICY "Admins can update medication reminders" ON public.medication_reminders
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:write' = ANY(admin_users.permissions)
                )
            );
    END IF;
    
    -- Admin can delete medication reminders
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_reminders' AND policyname = 'Admins can delete medication reminders') THEN
        CREATE POLICY "Admins can delete medication reminders" ON public.medication_reminders
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE admin_users.user_id = auth.uid() 
                    AND 'medications:delete' = ANY(admin_users.permissions)
                )
            );
    END IF;
END $$; 