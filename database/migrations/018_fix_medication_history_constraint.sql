-- Migration: Fix Medication History Constraint and Functions
-- Description: Adds missing unique constraint and recreates functions with robust error handling

-- Add unique constraint to medication_history table
DO $$ 
BEGIN
    -- Check if the constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'medication_history_medication_id_scheduled_for_key' 
        AND table_name = 'medication_history'
    ) THEN
        -- Add unique constraint
        ALTER TABLE public.medication_history 
        ADD CONSTRAINT medication_history_medication_id_scheduled_for_key 
        UNIQUE (medication_id, scheduled_for);
    END IF;
END $$;

-- Recreate the log_medication_taken function to handle the constraint properly
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
    v_frequency TEXT;
    v_daily_count INTEGER;
    v_scheduled_date DATE;
BEGIN
    -- Get medication frequency
    SELECT frequency INTO v_frequency
    FROM public.medications
    WHERE id = p_medication_id AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Medication not found or access denied';
    END IF;
    
    -- Get the scheduled date
    v_scheduled_date := p_scheduled_for::date;
    
    -- Check daily limit based on frequency
    SELECT COUNT(*) INTO v_daily_count
    FROM public.medication_history
    WHERE medication_id = p_medication_id 
    AND scheduled_for::date = v_scheduled_date
    AND status IN ('taken', 'skipped');
    
    -- Validate frequency limits
    CASE v_frequency
        WHEN 'once daily' THEN
            IF v_daily_count >= 1 THEN
                RAISE EXCEPTION 'Medication already marked as taken or skipped today (once daily limit)';
            END IF;
        WHEN 'twice daily' THEN
            IF v_daily_count >= 2 THEN
                RAISE EXCEPTION 'Medication already marked as taken or skipped twice today (twice daily limit)';
            END IF;
        WHEN 'three times daily' THEN
            IF v_daily_count >= 3 THEN
                RAISE EXCEPTION 'Medication already marked as taken or skipped three times today (three times daily limit)';
            END IF;
        WHEN 'four times daily' THEN
            IF v_daily_count >= 4 THEN
                RAISE EXCEPTION 'Medication already marked as taken or skipped four times today (four times daily limit)';
            END IF;
        ELSE
            -- For other frequencies, allow unlimited entries
            NULL;
    END CASE;
    
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

-- Recreate the log_medication_skipped function to handle the constraint properly
CREATE OR REPLACE FUNCTION log_medication_skipped(
    p_medication_id UUID,
    p_user_id UUID,
    p_scheduled_for TIMESTAMP WITH TIME ZONE,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_history_id UUID;
    v_frequency TEXT;
    v_daily_count INTEGER;
    v_scheduled_date DATE;
BEGIN
    -- Get medication frequency
    SELECT frequency INTO v_frequency
    FROM public.medications
    WHERE id = p_medication_id AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Medication not found or access denied';
    END IF;
    
    -- Get the scheduled date
    v_scheduled_date := p_scheduled_for::date;
    
    -- Check daily limit based on frequency
    SELECT COUNT(*) INTO v_daily_count
    FROM public.medication_history
    WHERE medication_id = p_medication_id 
    AND scheduled_for::date = v_scheduled_date
    AND status IN ('taken', 'skipped');
    
    -- Validate frequency limits
    CASE v_frequency
        WHEN 'once daily' THEN
            IF v_daily_count >= 1 THEN
                RAISE EXCEPTION 'Medication already marked as taken or skipped today (once daily limit)';
            END IF;
        WHEN 'twice daily' THEN
            IF v_daily_count >= 2 THEN
                RAISE EXCEPTION 'Medication already marked as taken or skipped twice today (twice daily limit)';
            END IF;
        WHEN 'three times daily' THEN
            IF v_daily_count >= 3 THEN
                RAISE EXCEPTION 'Medication already marked as taken or skipped three times today (three times daily limit)';
            END IF;
        WHEN 'four times daily' THEN
            IF v_daily_count >= 4 THEN
                RAISE EXCEPTION 'Medication already marked as taken or skipped four times today (four times daily limit)';
            END IF;
        ELSE
            -- For other frequencies, allow unlimited entries
            NULL;
    END CASE;
    
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

-- Ensure all functions have proper permissions
GRANT EXECUTE ON FUNCTION log_medication_taken(UUID, UUID, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION log_medication_skipped(UUID, UUID, TIMESTAMP WITH TIME ZONE, TEXT) TO authenticated;

-- Function to check remaining doses for a medication on a specific date
CREATE OR REPLACE FUNCTION get_remaining_doses(
    p_medication_id UUID,
    p_user_id UUID,
    p_date DATE
)
RETURNS TABLE (
    total_doses INTEGER,
    taken_doses INTEGER,
    skipped_doses INTEGER,
    remaining_doses INTEGER,
    frequency TEXT
) AS $$
DECLARE
    v_frequency TEXT;
    v_total_doses INTEGER;
    v_taken_doses INTEGER;
    v_skipped_doses INTEGER;
BEGIN
    -- Get medication frequency
    SELECT frequency INTO v_frequency
    FROM public.medications
    WHERE id = p_medication_id AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Medication not found or access denied';
    END IF;
    
    -- Calculate total doses based on frequency
    CASE v_frequency
        WHEN 'once daily' THEN v_total_doses := 1;
        WHEN 'twice daily' THEN v_total_doses := 2;
        WHEN 'three times daily' THEN v_total_doses := 3;
        WHEN 'four times daily' THEN v_total_doses := 4;
        ELSE v_total_doses := 999; -- Unlimited for other frequencies
    END CASE;
    
    -- Count taken doses
    SELECT COUNT(*) INTO v_taken_doses
    FROM public.medication_history
    WHERE medication_id = p_medication_id 
    AND scheduled_for::date = p_date
    AND status = 'taken';
    
    -- Count skipped doses
    SELECT COUNT(*) INTO v_skipped_doses
    FROM public.medication_history
    WHERE medication_id = p_medication_id 
    AND scheduled_for::date = p_date
    AND status = 'skipped';
    
    RETURN QUERY SELECT 
        v_total_doses,
        v_taken_doses,
        v_skipped_doses,
        GREATEST(0, v_total_doses - v_taken_doses - v_skipped_doses),
        v_frequency;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for the new function
GRANT EXECUTE ON FUNCTION get_remaining_doses(UUID, UUID, DATE) TO authenticated; 