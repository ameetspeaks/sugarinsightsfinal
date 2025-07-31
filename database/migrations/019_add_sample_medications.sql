-- Migration: Add Sample Medications
-- Description: Adds sample medications for testing the medication management system

-- Insert sample medications for testing
-- Note: Replace '28a1d171-57ab-4685-88c7-d6598878c58d' with the actual user ID from your database

INSERT INTO public.medications (
    user_id,
    name,
    dosage,
    medicine_type,
    frequency,
    time_of_day,
    start_date,
    end_date,
    notes,
    is_active
) VALUES 
(
    '28a1d171-57ab-4685-88c7-d6598878c58d',
    'Metformin',
    '500mg',
    'tablet',
    'twice daily',
    ARRAY['08:00:00', '20:00:00'],
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '30 days',
    'Take with meals',
    true
),
(
    '28a1d171-57ab-4685-88c7-d6598878c58d',
    'Lisinopril',
    '10mg',
    'tablet',
    'once daily',
    ARRAY['08:00:00'],
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '30 days',
    'Take in the morning',
    true
),
(
    '28a1d171-57ab-4685-88c7-d6598878c58d',
    'Cyanocobalamin',
    '1000mcg',
    'injection',
    'once daily',
    ARRAY['18:00:00'],
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '30 days',
    'Vitamin B12 injection',
    true
)
ON CONFLICT DO NOTHING; 